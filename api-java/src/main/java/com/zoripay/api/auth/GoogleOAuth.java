package com.zoripay.api.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zoripay.api.model.GoogleUserInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

public class GoogleOAuth {

    private static final Logger log = LoggerFactory.getLogger(GoogleOAuth.class);
    private static final String GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
    private static final String GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
    private static final String GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo";

    private final String clientId;
    private final String clientSecret;
    private final HttpClient httpClient;
    private final ObjectMapper mapper;

    public GoogleOAuth(String clientId, String clientSecret) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.httpClient = HttpClient.newHttpClient();
        this.mapper = new ObjectMapper();
    }

    public record AuthUrlResult(String authorizationUrl, String state) {}

    public AuthUrlResult getAuthorizationUrl(String redirectUri) {
        String state = UUID.randomUUID().toString();
        String url = GOOGLE_AUTH_URL
                + "?client_id=" + urlEncode(clientId)
                + "&redirect_uri=" + urlEncode(redirectUri)
                + "&response_type=code"
                + "&scope=" + urlEncode("email profile openid")
                + "&state=" + urlEncode(state)
                + "&access_type=offline"
                + "&prompt=consent";
        return new AuthUrlResult(url, state);
    }

    public GoogleUserInfo exchangeCode(String code, String redirectUri) throws Exception {
        // Exchange code for token
        String body = formEncode(Map.of(
                "code", code,
                "client_id", clientId,
                "client_secret", clientSecret,
                "redirect_uri", redirectUri,
                "grant_type", "authorization_code"
        ));

        var tokenRequest = HttpRequest.newBuilder()
                .uri(URI.create(GOOGLE_TOKEN_URL))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

        var tokenResponse = httpClient.send(tokenRequest, HttpResponse.BodyHandlers.ofString());
        if (tokenResponse.statusCode() != 200) {
            throw new RuntimeException("Failed to exchange code: " + tokenResponse.body());
        }

        var tokenJson = mapper.readTree(tokenResponse.body());
        String accessToken = tokenJson.get("access_token").asText();

        // Fetch user info
        var userInfoRequest = HttpRequest.newBuilder()
                .uri(URI.create(GOOGLE_USERINFO_URL))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        var userInfoResponse = httpClient.send(userInfoRequest, HttpResponse.BodyHandlers.ofString());
        if (userInfoResponse.statusCode() != 200) {
            throw new RuntimeException("Failed to fetch user info: " + userInfoResponse.body());
        }

        var userInfo = mapper.readValue(userInfoResponse.body(), GoogleUserInfo.class);

        if (!userInfo.emailVerified()) {
            throw new RuntimeException("Email not verified by Google");
        }

        return userInfo;
    }

    private static String urlEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private static String formEncode(Map<String, String> params) {
        return params.entrySet().stream()
                .map(e -> urlEncode(e.getKey()) + "=" + urlEncode(e.getValue()))
                .collect(Collectors.joining("&"));
    }
}
