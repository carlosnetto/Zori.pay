package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record BalanceResponse(
        String address,
        String blockchain,
        List<CurrencyBalance> balances
) {
    public record CurrencyBalance(
            @JsonProperty("currency_code") String currencyCode,
            String balance,
            int decimals,
            @JsonProperty("formatted_balance") String formattedBalance
    ) {}
}
