package com.zoripay.api.model.request;

import com.fasterxml.jackson.annotation.JsonProperty;

public record GoogleAuthInitRequest(@JsonProperty("redirect_uri") String redirectUri) {}
