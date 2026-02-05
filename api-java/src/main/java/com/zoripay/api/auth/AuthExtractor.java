package com.zoripay.api.auth;

import com.zoripay.api.error.ApiException;
import io.javalin.http.Context;

public final class AuthExtractor {

    private AuthExtractor() {}

    public static Claims extractAndValidate(Context ctx, JwtManager jwt, TokenType expectedType) {
        String authHeader = ctx.header("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw ApiException.invalidToken();
        }
        String token = authHeader.substring("Bearer ".length());
        try {
            return jwt.validateToken(token, expectedType);
        } catch (Exception e) {
            throw ApiException.invalidToken();
        }
    }

    public static Claims extractAccessToken(Context ctx, JwtManager jwt) {
        return extractAndValidate(ctx, jwt, TokenType.ACCESS);
    }

    public static Claims extractIntermediateToken(Context ctx, JwtManager jwt) {
        return extractAndValidate(ctx, jwt, TokenType.INTERMEDIATE);
    }
}
