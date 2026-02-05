package com.zoripay.api.model.request;

import com.fasterxml.jackson.annotation.JsonProperty;

public record EstimateRequest(
        @JsonProperty("to_address") String toAddress,
        String amount,
        @JsonProperty("currency_code") String currencyCode
) {}
