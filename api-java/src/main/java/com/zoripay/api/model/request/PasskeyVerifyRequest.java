package com.zoripay.api.model.request;

import com.fasterxml.jackson.annotation.JsonProperty;

public record PasskeyVerifyRequest(
        @JsonProperty("credential_id") String credentialId,
        @JsonProperty("authenticator_data") String authenticatorData,
        @JsonProperty("client_data_json") String clientDataJson,
        String signature,
        @JsonProperty("user_handle") String userHandle
) {}
