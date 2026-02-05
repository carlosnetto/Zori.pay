package com.zoripay.api.route;

import com.zoripay.api.AppState;
import com.zoripay.api.auth.AuthExtractor;
import com.zoripay.api.auth.TokenType;
import com.zoripay.api.dao.PasskeyDao;
import com.zoripay.api.dao.PersonDao;
import com.zoripay.api.error.ApiError;
import com.zoripay.api.error.ApiException;
import com.zoripay.api.model.request.GoogleAuthInitRequest;
import com.zoripay.api.model.request.GoogleCallbackRequest;
import com.zoripay.api.model.request.PasskeyVerifyRequest;
import com.zoripay.api.model.request.RefreshTokenRequest;
import com.zoripay.api.model.response.AuthTokenResponse;
import com.zoripay.api.model.response.GoogleAuthInitResponse;
import com.zoripay.api.model.response.GoogleCallbackResponse;
import com.zoripay.api.model.response.UserBasicInfo;
import io.javalin.http.Context;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AuthRoutes {

    private static final Logger log = LoggerFactory.getLogger(AuthRoutes.class);
    private final AppState state;
    private final PersonDao personDao;
    private final PasskeyDao passkeyDao;

    public AuthRoutes(AppState state) {
        this.state = state;
        this.personDao = new PersonDao(state.jdbi());
        this.passkeyDao = new PasskeyDao(state.jdbi());
    }

    /** POST /v1/auth/google */
    public void initiateGoogleAuth(Context ctx) {
        var request = ctx.bodyAsClass(GoogleAuthInitRequest.class);
        var result = state.googleOAuth().getAuthorizationUrl(request.redirectUri());
        ctx.json(new GoogleAuthInitResponse(result.authorizationUrl(), result.state()));
    }

    /** POST /v1/auth/google/callback */
    public void handleGoogleCallback(Context ctx) throws Exception {
        var request = ctx.bodyAsClass(GoogleCallbackRequest.class);

        var googleUser = state.googleOAuth().exchangeCode(request.code(), request.redirectUri());
        log.info("Google OAuth success for email: {}", googleUser.email());

        var person = personDao.findPersonByLoginEmail(googleUser.email())
                .orElseThrow(() -> {
                    log.warn("Login attempt with unauthorized email: {}", googleUser.email());
                    return ApiException.userNotFound();
                });

        log.info("Found person {} for email {}", person.id(), googleUser.email());

        var intermediateToken = state.jwt().createIntermediateToken(
                person.id(), person.emailAddress(),
                state.config().intermediateTokenExpirySecs());

        ctx.json(new GoogleCallbackResponse(
                intermediateToken,
                state.config().intermediateTokenExpirySecs(),
                new UserBasicInfo(person.id(), person.emailAddress(),
                        person.fullName(), googleUser.picture())
        ));
    }

    /** POST /v1/auth/passkey/challenge */
    public void requestPasskeyChallenge(Context ctx) {
        var claims = AuthExtractor.extractIntermediateToken(ctx, state.jwt());

        var credentials = passkeyDao.getPasskeyCredentials(claims.sub());
        if (credentials.isEmpty()) {
            throw new ApiException(new ApiError.NoPasskeysRegistered());
        }

        var challenge = state.passkey().generateChallenge(claims.sub(), credentials);
        ctx.json(challenge);
    }

    /** POST /v1/auth/passkey/verify */
    public void verifyPasskey(Context ctx) {
        var claims = AuthExtractor.extractIntermediateToken(ctx, state.jwt());
        var request = ctx.bodyAsClass(PasskeyVerifyRequest.class);

        var result = state.passkey().verifyResponse(claims.sub(), request);

        passkeyDao.updatePasskeyCounter(result.credentialId(), result.counter());
        log.info("Passkey verified for person {}", claims.sub());

        ctx.json(createTokenResponse(claims.sub(), claims.email()));
    }

    /** POST /v1/auth/dev/bypass-passkey */
    public void bypassPasskeyVerification(Context ctx) {
        log.warn("DEVELOPMENT MODE: Bypassing passkey verification");
        var claims = AuthExtractor.extractIntermediateToken(ctx, state.jwt());
        log.info("Dev bypass: Created tokens for person {}", claims.sub());
        ctx.json(createTokenResponse(claims.sub(), claims.email()));
    }

    /** POST /v1/auth/refresh */
    public void refreshToken(Context ctx) {
        var request = ctx.bodyAsClass(RefreshTokenRequest.class);

        try {
            var claims = state.jwt().validateRefreshToken(request.refreshToken());
            ctx.json(createTokenResponse(claims.sub(), claims.email()));
        } catch (Exception e) {
            throw ApiException.invalidToken();
        }
    }

    /** POST /v1/auth/logout */
    public void logout(Context ctx) {
        AuthExtractor.extractAccessToken(ctx, state.jwt());
        log.info("User logged out");
        ctx.status(200);
    }

    private AuthTokenResponse createTokenResponse(java.util.UUID personId, String email) {
        var accessToken = state.jwt().createAccessToken(
                personId, email, state.config().jwtAccessTokenExpirySecs());
        var refreshToken = state.jwt().createRefreshToken(
                personId, email, state.config().jwtRefreshTokenExpirySecs());

        return new AuthTokenResponse(accessToken, refreshToken, "Bearer",
                state.config().jwtAccessTokenExpirySecs());
    }
}
