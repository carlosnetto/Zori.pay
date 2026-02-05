package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.UUID;

public record AccountOpeningResponse(
        boolean success,
        @JsonProperty("person_id") UUID personId,
        @JsonProperty("account_holder_id") UUID accountHolderId,
        @JsonProperty("polygon_address") String polygonAddress,
        String message,
        @JsonProperty("documents_status") String documentsStatus
) {}
