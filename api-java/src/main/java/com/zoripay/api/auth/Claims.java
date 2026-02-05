package com.zoripay.api.auth;

import java.util.UUID;

public record Claims(
        UUID sub,
        String email,
        TokenType tokenType,
        long iat,
        long exp,
        UUID jti
) {}
