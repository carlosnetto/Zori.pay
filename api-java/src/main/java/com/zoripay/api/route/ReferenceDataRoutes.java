package com.zoripay.api.route;

import com.zoripay.api.AppState;
import com.zoripay.api.dao.ReferenceDataDao;
import com.zoripay.api.error.ApiException;
import io.javalin.http.Context;

import java.security.MessageDigest;

public class ReferenceDataRoutes {

    private final AppState state;
    private final ReferenceDataDao referenceDataDao;

    public ReferenceDataRoutes(AppState state) {
        this.state = state;
        this.referenceDataDao = new ReferenceDataDao(state.jdbi());
    }

    /** GET /v1/reference-data */
    public void getReferenceData(Context ctx) {
        try {
            var data = referenceDataDao.getAll();

            // Generate ETag from response JSON
            String jsonData = state.mapper().writeValueAsString(data);
            var digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(jsonData.getBytes());
            // Use first 8 bytes for shorter ETag (matching Rust)
            var sb = new StringBuilder();
            for (int i = 0; i < 8; i++) {
                sb.append(String.format("%02x", hash[i]));
            }
            String etag = "\"" + sb + "\"";

            // Check If-None-Match
            String ifNoneMatch = ctx.header("If-None-Match");
            if (ifNoneMatch != null) {
                if (ifNoneMatch.equals(etag) || ifNoneMatch.equals("W/" + etag)) {
                    ctx.header("ETag", etag);
                    ctx.status(304);
                    return;
                }
            }

            ctx.header("ETag", etag);
            ctx.header("Cache-Control", "public, max-age=3600");
            ctx.json(data);

        } catch (Exception e) {
            throw ApiException.internal("Failed to fetch reference data", e);
        }
    }
}
