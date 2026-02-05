package com.zoripay.api.auth;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;

import java.time.Instant;
import java.util.UUID;

public class JwtManager {

    private final Algorithm algorithm;

    public JwtManager(String secret) {
        this.algorithm = Algorithm.HMAC256(secret);
    }

    public String createIntermediateToken(UUID personId, String email, long expirySecs) {
        return createToken(personId, email, TokenType.INTERMEDIATE, expirySecs);
    }

    public String createAccessToken(UUID personId, String email, long expirySecs) {
        return createToken(personId, email, TokenType.ACCESS, expirySecs);
    }

    public String createRefreshToken(UUID personId, String email, long expirySecs) {
        return createToken(personId, email, TokenType.REFRESH, expirySecs);
    }

    private String createToken(UUID personId, String email, TokenType tokenType, long expirySecs) {
        var now = Instant.now();
        return JWT.create()
                .withSubject(personId.toString())
                .withClaim("email", email)
                .withClaim("token_type", tokenType.value())
                .withIssuedAt(now)
                .withExpiresAt(now.plusSeconds(expirySecs))
                .withJWTId(UUID.randomUUID().toString())
                .sign(algorithm);
    }

    public Claims validateToken(String token, TokenType expectedType) {
        try {
            DecodedJWT decoded = JWT.require(algorithm).build().verify(token);

            String tokenTypeStr = decoded.getClaim("token_type").asString();
            var tokenType = TokenType.fromValue(tokenTypeStr);

            if (tokenType != expectedType) {
                throw new JWTVerificationException(
                        "Invalid token type: expected " + expectedType + ", got " + tokenType);
            }

            return new Claims(
                    UUID.fromString(decoded.getSubject()),
                    decoded.getClaim("email").asString(),
                    tokenType,
                    decoded.getIssuedAtAsInstant().getEpochSecond(),
                    decoded.getExpiresAtAsInstant().getEpochSecond(),
                    UUID.fromString(decoded.getId())
            );
        } catch (JWTVerificationException | IllegalArgumentException e) {
            throw new JWTVerificationException("Token validation failed: " + e.getMessage());
        }
    }

    public Claims validateIntermediateToken(String token) {
        return validateToken(token, TokenType.INTERMEDIATE);
    }

    public Claims validateAccessToken(String token) {
        return validateToken(token, TokenType.ACCESS);
    }

    public Claims validateRefreshToken(String token) {
        return validateToken(token, TokenType.REFRESH);
    }
}
