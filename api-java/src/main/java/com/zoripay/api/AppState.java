package com.zoripay.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zoripay.api.auth.GoogleOAuth;
import com.zoripay.api.auth.JwtManager;
import com.zoripay.api.auth.PasskeyAuth;
import com.zoripay.api.service.BlockchainService;
import com.zoripay.api.service.DriveClient;
import org.jdbi.v3.core.Jdbi;

public record AppState(
        AppConfig config,
        Jdbi jdbi,
        GoogleOAuth googleOAuth,
        JwtManager jwt,
        PasskeyAuth passkey,
        DriveClient driveClient,
        BlockchainService blockchainService,
        ObjectMapper mapper
) {}
