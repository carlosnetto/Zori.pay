package com.zoripay.api.model;

import java.util.List;
import java.util.UUID;

public record PasskeyCredential(
        UUID id,
        byte[] credentialId,
        byte[] publicKey,
        int counter,
        List<String> transports
) {}
