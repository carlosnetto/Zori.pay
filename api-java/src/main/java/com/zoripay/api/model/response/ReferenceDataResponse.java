package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record ReferenceDataResponse(
        List<Country> countries,
        List<StateEntry> states,
        @JsonProperty("phone_types") List<PhoneType> phoneTypes,
        @JsonProperty("email_types") List<EmailType> emailTypes,
        List<Currency> currencies,
        @JsonProperty("blockchain_networks") List<BlockchainNetwork> blockchainNetworks,
        @JsonProperty("address_types") List<AddressType> addressTypes,
        @JsonProperty("asset_types") List<AssetType> assetTypes
) {
    public record Country(@JsonProperty("iso_code") String isoCode, String name) {}
    public record StateEntry(@JsonProperty("country_code") String countryCode,
                             @JsonProperty("state_code") String stateCode, String name) {}
    public record PhoneType(String code, String description) {}
    public record EmailType(String code, String description) {}
    public record Currency(String code, String name,
                           @JsonProperty("asset_type_code") String assetTypeCode, int decimals) {}
    public record BlockchainNetwork(String code, String name) {}
    public record AddressType(String code, String description) {}
    public record AssetType(String code, String description) {}
}
