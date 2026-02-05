package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.UUID;

public record UserBasicInfo(
        @JsonProperty("person_id") UUID personId,
        String email,
        @JsonProperty("display_name") String displayName,
        @JsonProperty("avatar_url") String avatarUrl
) {}
