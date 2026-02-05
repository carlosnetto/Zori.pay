package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public record SendResponse(
        boolean success,
        @JsonProperty("transaction_hash") String transactionHash,
        String message
) {}
