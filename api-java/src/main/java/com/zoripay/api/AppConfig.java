package com.zoripay.api;

import io.github.cdimascio.dotenv.Dotenv;

public record AppConfig(
        String host,
        int port,
        String databaseUrl,
        String googleClientId,
        String googleClientSecret,
        String rpId,
        String rpOrigin,
        String jwtSecret,
        long jwtAccessTokenExpirySecs,
        long jwtRefreshTokenExpirySecs,
        long intermediateTokenExpirySecs,
        byte[] masterEncryptionKey,
        String encryptionKeyId,
        String googleDriveRootFolderId,
        String googleDriveClientId,
        String googleDriveClientSecret,
        long maxFileSizeBytes,
        long maxTotalUploadBytes,
        String polygonRpcUrl
) {
    public static AppConfig fromEnv() {
        var dotenv = Dotenv.configure()
                .ignoreIfMissing()
                .load();

        String keyHex = require(dotenv, "MASTER_ENCRYPTION_KEY");
        byte[] masterKey = hexToBytes(keyHex);
        if (masterKey.length != 32) {
            throw new IllegalStateException("MASTER_ENCRYPTION_KEY must be 32 bytes (64 hex chars)");
        }

        long maxFileMb = parseLong(dotenv, "MAX_FILE_SIZE_MB", 10);
        long maxTotalMb = parseLong(dotenv, "MAX_TOTAL_UPLOAD_SIZE_MB", 50);

        return new AppConfig(
                getOr(dotenv, "HOST", "127.0.0.1"),
                (int) parseLong(dotenv, "PORT", 3001),
                require(dotenv, "DATABASE_URL"),
                require(dotenv, "GOOGLE_CLIENT_ID"),
                require(dotenv, "GOOGLE_CLIENT_SECRET"),
                getOr(dotenv, "RP_ID", "zori.pay"),
                getOr(dotenv, "RP_ORIGIN", "https://zori.pay"),
                require(dotenv, "JWT_SECRET"),
                parseLong(dotenv, "JWT_ACCESS_EXPIRY", 3600),
                parseLong(dotenv, "JWT_REFRESH_EXPIRY", 604800),
                parseLong(dotenv, "INTERMEDIATE_TOKEN_EXPIRY", 300),
                masterKey,
                getOr(dotenv, "ENCRYPTION_KEY_ID", "env-v1"),
                require(dotenv, "GOOGLE_DRIVE_ROOT_FOLDER_ID"),
                getOr(dotenv, "GOOGLE_DRIVE_CLIENT_ID",
                        getOr(dotenv, "GOOGLE_CLIENT_ID", "")),
                getOr(dotenv, "GOOGLE_DRIVE_CLIENT_SECRET",
                        getOr(dotenv, "GOOGLE_CLIENT_SECRET", "")),
                maxFileMb * 1024 * 1024,
                maxTotalMb * 1024 * 1024,
                getOr(dotenv, "POLYGON_RPC_URL", "https://polygon-rpc.com")
        );
    }

    private static String require(Dotenv dotenv, String key) {
        String val = dotenv.get(key);
        if (val == null || val.isBlank()) {
            throw new IllegalStateException(key + " must be set");
        }
        return val;
    }

    private static String getOr(Dotenv dotenv, String key, String defaultVal) {
        String val = dotenv.get(key);
        return (val != null && !val.isBlank()) ? val : defaultVal;
    }

    private static long parseLong(Dotenv dotenv, String key, long defaultVal) {
        String val = dotenv.get(key);
        if (val == null || val.isBlank()) return defaultVal;
        try {
            return Long.parseLong(val);
        } catch (NumberFormatException e) {
            return defaultVal;
        }
    }

    private static byte[] hexToBytes(String hex) {
        if (hex.length() % 2 != 0) {
            throw new IllegalArgumentException("Invalid hex string length");
        }
        byte[] bytes = new byte[hex.length() / 2];
        for (int i = 0; i < bytes.length; i++) {
            bytes[i] = (byte) Integer.parseInt(hex.substring(i * 2, i * 2 + 2), 16);
        }
        return bytes;
    }
}
