package com.zoripay.api.model.request;

import com.fasterxml.jackson.annotation.JsonProperty;

public record GoogleCallbackRequest(
        String code,
        @JsonProperty("redirect_uri") String redirectUri
) {}
