package com.zoripay.api.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.webauthn4j.WebAuthnManager;
import com.webauthn4j.authenticator.AuthenticatorImpl;
import com.webauthn4j.converter.AttestedCredentialDataConverter;
import com.webauthn4j.converter.util.ObjectConverter;
import com.webauthn4j.data.*;
import com.webauthn4j.data.attestation.authenticator.AttestedCredentialData;
import com.webauthn4j.data.client.Origin;
import com.webauthn4j.data.client.challenge.Challenge;
import com.webauthn4j.data.client.challenge.DefaultChallenge;
import com.webauthn4j.server.ServerProperty;
import com.zoripay.api.model.PasskeyCredential;
import com.zoripay.api.model.request.PasskeyVerifyRequest;
import com.zoripay.api.model.response.PasskeyChallengeResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.security.SecureRandom;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class PasskeyAuth {

    private static final Logger log = LoggerFactory.getLogger(PasskeyAuth.class);

    private final String rpId;
    private final String rpOrigin;
    private final WebAuthnManager webAuthnManager;
    private final ObjectConverter objectConverter;

    // In-memory storage for authentication challenges (mirrors Rust RwLock<HashMap>)
    private final ConcurrentHashMap<UUID, ChallengeState> authChallenges = new ConcurrentHashMap<>();

    private record ChallengeState(Challenge challenge, List<PasskeyCredential> credentials) {}

    public PasskeyAuth(String rpId, String rpOrigin) {
        this.rpId = rpId;
        this.rpOrigin = rpOrigin;
        this.objectConverter = new ObjectConverter();
        this.webAuthnManager = WebAuthnManager.createNonStrictWebAuthnManager(objectConverter);
    }

    public PasskeyChallengeResponse generateChallenge(UUID personId,
                                                       List<PasskeyCredential> credentials) {
        // Generate random challenge
        byte[] challengeBytes = new byte[32];
        new SecureRandom().nextBytes(challengeBytes);
        var challenge = new DefaultChallenge(challengeBytes);

        // Store challenge state
        authChallenges.put(personId, new ChallengeState(challenge, credentials));

        // Build allowed credentials list
        var allowedCreds = credentials.stream()
                .map(c -> new PasskeyChallengeResponse.AllowedCredential(
                        "public-key",
                        Base64.getUrlEncoder().withoutPadding().encodeToString(c.credentialId()),
                        c.transports()
                ))
                .toList();

        return new PasskeyChallengeResponse(
                Base64.getUrlEncoder().withoutPadding().encodeToString(challengeBytes),
                60000,
                rpId,
                "required",
                allowedCreds
        );
    }

    public record VerifyResult(byte[] credentialId, int counter) {}

    public VerifyResult verifyResponse(UUID personId, PasskeyVerifyRequest request) {
        // Retrieve and remove challenge state
        var state = authChallenges.remove(personId);
        if (state == null) {
            throw new RuntimeException("No pending authentication challenge");
        }

        byte[] credentialId = Base64.getUrlDecoder().decode(request.credentialId());
        byte[] authenticatorData = Base64.getUrlDecoder().decode(request.authenticatorData());
        byte[] clientDataJson = Base64.getUrlDecoder().decode(request.clientDataJson());
        byte[] signature = Base64.getUrlDecoder().decode(request.signature());

        // Find matching credential
        var matchedCred = state.credentials().stream()
                .filter(c -> Arrays.equals(c.credentialId(), credentialId))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Credential not found"));

        // Deserialize the stored passkey data using WebAuthn4J
        var attestedCredDataConverter = new AttestedCredentialDataConverter(objectConverter);
        AttestedCredentialData attestedCredentialData =
                attestedCredDataConverter.convert(matchedCred.publicKey());

        var authenticator = new AuthenticatorImpl(attestedCredentialData, null,
                matchedCred.counter());

        // Build server property
        var serverProperty = new ServerProperty(
                new Origin(rpOrigin),
                rpId,
                state.challenge(),
                null
        );

        // Verify authentication
        var authenticationRequest = new AuthenticationRequest(
                credentialId,
                authenticatorData,
                clientDataJson,
                signature
        );

        var authenticationParameters = new AuthenticationParameters(
                serverProperty,
                authenticator,
                List.of(credentialId),
                false // userVerificationRequired
        );

        var result = webAuthnManager.validate(authenticationRequest, authenticationParameters);

        return new VerifyResult(credentialId, (int) result.getAuthenticatorData().getSignCount());
    }
}
