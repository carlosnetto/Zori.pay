package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public record GoogleAuthInitResponse(
        @JsonProperty("authorization_url") String authorizationUrl,
        String state
) {}
