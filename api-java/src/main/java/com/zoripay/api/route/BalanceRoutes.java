package com.zoripay.api.route;

import com.zoripay.api.AppState;
import com.zoripay.api.auth.AuthExtractor;
import com.zoripay.api.dao.WalletDao;
import com.zoripay.api.error.ApiException;
import com.zoripay.api.model.response.BalanceResponse;
import com.zoripay.api.model.response.BalanceResponse.CurrencyBalance;
import com.zoripay.api.service.BlockchainService;
import io.javalin.http.Context;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;
import java.util.ArrayList;

public class BalanceRoutes {

    private static final Logger log = LoggerFactory.getLogger(BalanceRoutes.class);
    private final AppState state;
    private final WalletDao walletDao;

    public BalanceRoutes(AppState state) {
        this.state = state;
        this.walletDao = new WalletDao(state.jdbi());
    }

    /** GET /v1/balance */
    public void getBalances(Context ctx) throws Exception {
        var claims = AuthExtractor.extractAccessToken(ctx, state.jwt());

        var walletAddr = walletDao.getPrimaryPolygonAddress(claims.sub())
                .orElseThrow(() -> ApiException.validation(
                        "No Polygon address found for user"));

        var currencies = walletDao.getPolygonCurrencies();
        var blockchain = state.blockchainService();

        var balances = new ArrayList<CurrencyBalance>();

        for (var currency : currencies) {
            int decimals = currency.blockchainDecimals();
            BigInteger balance;

            try {
                if ("POL".equals(currency.code())) {
                    balance = blockchain.getNativeBalance(walletAddr.publicAddress());
                } else if (currency.contractAddress() != null) {
                    balance = blockchain.getErc20Balance(
                            currency.contractAddress(), walletAddr.publicAddress());
                } else {
                    log.warn("No contract address for {}, skipping", currency.code());
                    continue;
                }
            } catch (Exception e) {
                log.error("Failed to get {} balance: {}", currency.code(), e.getMessage());
                continue;
            }

            balances.add(new CurrencyBalance(
                    currency.code(),
                    balance.toString(),
                    decimals,
                    BlockchainService.formatBalance(balance, decimals)
            ));
        }

        ctx.json(new BalanceResponse(walletAddr.publicAddress(), "POLYGON", balances));
    }
}
