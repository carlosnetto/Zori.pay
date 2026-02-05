package com.zoripay.api.route;

import com.zoripay.api.AppState;
import com.zoripay.api.auth.AuthExtractor;
import com.zoripay.api.dao.WalletDao;
import com.zoripay.api.error.ApiException;
import com.zoripay.api.model.response.ReceiveAddressResponse;
import io.javalin.http.Context;

public class ReceiveRoutes {

    private final AppState state;
    private final WalletDao walletDao;

    public ReceiveRoutes(AppState state) {
        this.state = state;
        this.walletDao = new WalletDao(state.jdbi());
    }

    /** GET /v1/receive */
    public void getReceiveAddress(Context ctx) {
        var claims = AuthExtractor.extractAccessToken(ctx, state.jwt());

        var walletAddr = walletDao.getPrimaryPolygonAddress(claims.sub())
                .orElseThrow(() -> ApiException.validation(
                        "No blockchain address found for user"));

        ctx.json(new ReceiveAddressResponse(walletAddr.blockchainCode(),
                walletAddr.publicAddress()));
    }
}
