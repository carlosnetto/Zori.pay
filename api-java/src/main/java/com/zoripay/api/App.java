package com.zoripay.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.zoripay.api.auth.GoogleOAuth;
import com.zoripay.api.auth.JwtManager;
import com.zoripay.api.auth.PasskeyAuth;
import com.zoripay.api.error.ApiException;
import com.zoripay.api.error.ErrorResponse;
import com.zoripay.api.route.*;
import com.zoripay.api.service.BlockchainService;
import com.zoripay.api.service.DriveClient;
import io.javalin.Javalin;
import io.javalin.json.JavalinJackson;
import org.jdbi.v3.core.Jdbi;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class App {

    private static final Logger log = LoggerFactory.getLogger(App.class);

    public static void main(String[] args) {
        log.info("Starting Zori.pay API Server (Java)");

        // Load configuration
        var config = AppConfig.fromEnv();
        log.info("Configuration loaded");

        // Jackson ObjectMapper
        var mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        mapper.setSerializationInclusion(
                com.fasterxml.jackson.annotation.JsonInclude.Include.NON_NULL);

        // Database (JDBI + HikariCP)
        var jdbi = createJdbi(config);
        log.info("Connected to database");

        // Auth components
        var googleOAuth = new GoogleOAuth(config.googleClientId(), config.googleClientSecret());
        var jwt = new JwtManager(config.jwtSecret());
        var passkey = new PasskeyAuth(config.rpId(), config.rpOrigin());

        // Services
        var driveClient = DriveClient.create(config.googleDriveRootFolderId(),
                config.googleDriveClientId(), config.googleDriveClientSecret());
        var blockchainService = new BlockchainService(config.polygonRpcUrl());

        // App state
        var state = new AppState(config, jdbi, googleOAuth, jwt, passkey, driveClient,
                blockchainService, mapper);

        // Route handlers
        var webRoutes = new WebRoutes();
        var authRoutes = new AuthRoutes(state);
        var balanceRoutes = new BalanceRoutes(state);
        var receiveRoutes = new ReceiveRoutes(state);
        var sendRoutes = new SendRoutes(state);
        var transactionRoutes = new TransactionRoutes(state);
        var profileRoutes = new ProfileRoutes(state);
        var referenceDataRoutes = new ReferenceDataRoutes(state);
        var kycRoutes = new KycRoutes(state);

        // Create Javalin app with virtual threads
        var app = Javalin.create(cfg -> {
            cfg.jsonMapper(new JavalinJackson(mapper, true));
            cfg.http.maxRequestSize = 50 * 1024 * 1024L; // 50MB
            cfg.useVirtualThreads = true;

            // CORS
            cfg.bundledPlugins.enableCors(cors -> cors.addRule(rule -> {
                rule.anyHost();
            }));
        });

        // Global exception handler
        app.exception(ApiException.class, (e, ctx) -> {
            var error = e.getApiError();
            ctx.status(error.httpStatus());
            ctx.json(new ErrorResponse(error.code(), error.message()));
        });

        app.exception(Exception.class, (e, ctx) -> {
            log.error("Unhandled exception", e);
            ctx.status(500);
            ctx.json(new ErrorResponse("INTERNAL_ERROR", "An internal error occurred"));
        });

        // Web routes
        app.get("/", webRoutes::index);
        app.get("/auth/callback", webRoutes::oauthCallback);
        app.get("/health", webRoutes::health);

        // Auth routes
        app.post("/v1/auth/google", authRoutes::initiateGoogleAuth);
        app.post("/v1/auth/google/callback", authRoutes::handleGoogleCallback);
        app.post("/v1/auth/passkey/challenge", authRoutes::requestPasskeyChallenge);
        app.post("/v1/auth/passkey/verify", authRoutes::verifyPasskey);
        app.post("/v1/auth/dev/bypass-passkey", authRoutes::bypassPasskeyVerification);
        app.post("/v1/auth/refresh", authRoutes::refreshToken);
        app.post("/v1/auth/logout", authRoutes::logout);

        // Balance/Receive/Send/Transactions
        app.get("/v1/balance", balanceRoutes::getBalances);
        app.get("/v1/receive", receiveRoutes::getReceiveAddress);
        app.post("/v1/send", sendRoutes::sendTransaction);
        app.post("/v1/send/estimate", sendRoutes::estimateTransaction);
        app.get("/v1/transactions", transactionRoutes::getTransactions);

        // Profile & Reference Data
        app.get("/v1/profile", profileRoutes::getProfile);
        app.get("/v1/reference-data", referenceDataRoutes::getReferenceData);

        // KYC
        app.post("/v1/kyc/open-account-br", kycRoutes::openAccountBr);

        // Start server
        app.start(config.host(), config.port());
        log.info("Server listening on {}:{}", config.host(), config.port());
    }

    private static Jdbi createJdbi(AppConfig config) {
        var hikariConfig = new com.zaxxer.hikari.HikariConfig();
        hikariConfig.setJdbcUrl(config.databaseUrl().replace("postgres://", "jdbc:postgresql://"));
        hikariConfig.setMaximumPoolSize(10);
        hikariConfig.setMinimumIdle(2);

        // Parse user/password from DATABASE_URL
        // Format: postgres://user:password@host:port/database
        var url = config.databaseUrl();
        if (url.startsWith("postgres://") || url.startsWith("postgresql://")) {
            var withoutScheme = url.replaceFirst("^postgres(ql)?://", "");
            var atIndex = withoutScheme.indexOf('@');
            if (atIndex > 0) {
                var userInfo = withoutScheme.substring(0, atIndex);
                var hostPart = withoutScheme.substring(atIndex + 1);
                var colonIndex = userInfo.indexOf(':');
                if (colonIndex > 0) {
                    hikariConfig.setUsername(userInfo.substring(0, colonIndex));
                    hikariConfig.setPassword(userInfo.substring(colonIndex + 1));
                }
                hikariConfig.setJdbcUrl("jdbc:postgresql://" + hostPart);
            }
        }

        var dataSource = new com.zaxxer.hikari.HikariDataSource(hikariConfig);
        var jdbi = Jdbi.create(dataSource);
        jdbi.installPlugin(new org.jdbi.v3.postgres.PostgresPlugin());
        return jdbi;
    }
}
