package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public record EstimateResponse(
        @JsonProperty("estimated_gas") String estimatedGas,
        @JsonProperty("gas_price") String gasPrice,
        @JsonProperty("estimated_fee") String estimatedFee,
        @JsonProperty("estimated_fee_formatted") String estimatedFeeFormatted,
        @JsonProperty("max_amount") String maxAmount,
        @JsonProperty("max_amount_formatted") String maxAmountFormatted
) {}
