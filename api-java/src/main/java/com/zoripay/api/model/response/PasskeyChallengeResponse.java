package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record PasskeyChallengeResponse(
        String challenge,
        long timeout,
        @JsonProperty("rp_id") String rpId,
        @JsonProperty("user_verification") String userVerification,
        @JsonProperty("allowed_credentials") List<AllowedCredential> allowedCredentials
) {
    public record AllowedCredential(
            String type,
            String id,
            List<String> transports
    ) {}
}
