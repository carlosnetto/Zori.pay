package com.zoripay.api.route;

import com.zoripay.api.AppState;
import com.zoripay.api.auth.AuthExtractor;
import com.zoripay.api.dao.ProfileDao;
import io.javalin.http.Context;

public class ProfileRoutes {

    private final AppState state;
    private final ProfileDao profileDao;

    public ProfileRoutes(AppState state) {
        this.state = state;
        this.profileDao = new ProfileDao(state.jdbi());
    }

    /** GET /v1/profile */
    public void getProfile(Context ctx) {
        var claims = AuthExtractor.extractAccessToken(ctx, state.jwt());
        var profile = profileDao.getProfile(claims.sub());
        ctx.json(profile);
    }
}
