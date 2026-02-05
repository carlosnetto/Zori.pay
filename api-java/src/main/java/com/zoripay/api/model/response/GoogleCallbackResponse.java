package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public record GoogleCallbackResponse(
        @JsonProperty("intermediate_token") String intermediateToken,
        @JsonProperty("expires_in") long expiresIn,
        UserBasicInfo user
) {}
