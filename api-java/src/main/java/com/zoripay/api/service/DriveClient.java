package com.zoripay.api.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.ByteArrayContent;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.drive.Drive;
import com.google.api.services.drive.model.File;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.UserCredentials;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Date;
import java.util.List;

public class DriveClient {

    private static final Logger log = LoggerFactory.getLogger(DriveClient.class);
    private static final String TOKEN_FILE = "secrets/google-drive-token.json";

    private final String rootFolderId;
    private final Drive driveService;

    private DriveClient(String rootFolderId, Drive driveService) {
        this.rootFolderId = rootFolderId;
        this.driveService = driveService;
    }

    public static DriveClient create(String rootFolderId, String clientId,
                                      String clientSecret) {
        try {
            var mapper = new ObjectMapper();
            var json = mapper.readTree(Files.readString(Path.of(TOKEN_FILE)));

            String refreshToken = json.get("refresh_token").asText();
            String accessToken = json.get("access_token").asText();
            long expiresAt = json.get("expires_at").asLong();

            var credentials = UserCredentials.newBuilder()
                    .setClientId(clientId)
                    .setClientSecret(clientSecret)
                    .setRefreshToken(refreshToken)
                    .setAccessToken(new AccessToken(accessToken,
                            new Date(expiresAt * 1000)))
                    .build();

            var transport = GoogleNetHttpTransport.newTrustedTransport();
            var drive = new Drive.Builder(
                    transport,
                    GsonFactory.getDefaultInstance(),
                    new HttpCredentialsAdapter(credentials))
                    .setApplicationName("Zori.pay")
                    .build();

            log.info("Google Drive client initialized from {}", TOKEN_FILE);
            return new DriveClient(rootFolderId, drive);
        } catch (Exception e) {
            log.warn("Failed to initialize Drive client: {}. Drive uploads will fail.",
                    e.getMessage());
            return new DriveClient(rootFolderId, null);
        }
    }

    public String ensureCpfFolder(String cpf) throws IOException {
        String docDbFolderId = ensureFolder("DOC_DB", rootFolderId);
        return ensureFolder(cpf, docDbFolderId);
    }

    private String ensureFolder(String folderName, String parentId) throws IOException {
        if (driveService == null) throw new IOException("Drive client not initialized");

        String query = "name = '" + folderName + "' and '" + parentId
                + "' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false";

        var result = driveService.files().list()
                .setQ(query)
                .setFields("files(id, name)")
                .execute();

        if (result.getFiles() != null && !result.getFiles().isEmpty()) {
            String id = result.getFiles().get(0).getId();
            log.info("Found existing folder: {} ({})", folderName, id);
            return id;
        }

        log.info("Creating folder: {} in parent {}", folderName, parentId);
        var folderMetadata = new File()
                .setName(folderName)
                .setParents(List.of(parentId))
                .setMimeType("application/vnd.google-apps.folder");

        File folder = driveService.files().create(folderMetadata)
                .setFields("id, name")
                .execute();

        log.info("Created folder: {} ({})", folderName, folder.getId());
        return folder.getId();
    }

    public String uploadFile(byte[] data, String filename, String mimeType,
                              String folderId) throws IOException {
        if (driveService == null) throw new IOException("Drive client not initialized");

        log.info("Uploading file: {} ({} bytes) to folder {}", filename, data.length, folderId);

        var fileMetadata = new File()
                .setName(filename)
                .setParents(List.of(folderId));

        var mediaContent = new ByteArrayContent(mimeType, data);

        File uploaded = driveService.files().create(fileMetadata, mediaContent)
                .setFields("id, name")
                .execute();

        log.info("Uploaded file: {} (ID: {})", filename, uploaded.getId());
        return uploaded.getId();
    }
}
