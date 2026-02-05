package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record TransactionsResponse(
        String address,
        String blockchain,
        @JsonProperty("currency_code") String currencyCode,
        List<Transaction> transactions
) {
    public record Transaction(
            String hash,
            @JsonProperty("block_number") long blockNumber,
            long timestamp,
            String from,
            String to,
            String value,
            @JsonProperty("formatted_value") String formattedValue,
            @JsonProperty("currency_code") String currencyCode,
            int decimals,
            String status
    ) {}
}
