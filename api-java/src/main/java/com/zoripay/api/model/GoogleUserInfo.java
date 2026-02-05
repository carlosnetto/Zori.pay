package com.zoripay.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public record GoogleUserInfo(
        String email,
        @JsonProperty("email_verified") boolean emailVerified,
        String name,
        String picture,
        String sub
) {}
