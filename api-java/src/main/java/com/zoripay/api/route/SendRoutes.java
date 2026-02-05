package com.zoripay.api.route;

import com.zoripay.api.AppState;
import com.zoripay.api.auth.AuthExtractor;
import com.zoripay.api.crypto.EncryptionService;
import com.zoripay.api.crypto.WalletService;
import com.zoripay.api.dao.WalletDao;
import com.zoripay.api.error.ApiException;
import com.zoripay.api.model.request.EstimateRequest;
import com.zoripay.api.model.request.SendRequest;
import com.zoripay.api.model.response.EstimateResponse;
import com.zoripay.api.model.response.SendResponse;
import com.zoripay.api.service.BlockchainService;
import io.javalin.http.Context;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;

public class SendRoutes {

    private static final Logger log = LoggerFactory.getLogger(SendRoutes.class);
    private static final BigInteger MIN_GAS_POL = new BigInteger("10000000000000000"); // 0.01 POL
    private final AppState state;
    private final WalletDao walletDao;

    public SendRoutes(AppState state) {
        this.state = state;
        this.walletDao = new WalletDao(state.jdbi());
    }

    /** POST /v1/send */
    public void sendTransaction(Context ctx) throws Exception {
        var claims = AuthExtractor.extractAccessToken(ctx, state.jwt());
        var request = ctx.bodyAsClass(SendRequest.class);

        // Validate destination address (basic hex check)
        if (!request.toAddress().startsWith("0x") || request.toAddress().length() != 42) {
            throw ApiException.validation("Invalid destination address");
        }

        // Get wallet data
        var walletData = walletDao.getWalletData(claims.sub())
                .orElseThrow(() -> ApiException.validation("No wallet found for user"));

        // Decrypt seed
        var encrypted = new EncryptionService.EncryptedSeed(
                walletData.encryptedMasterSeed(),
                walletData.encryptionIv(),
                walletData.encryptionAuthTag()
        );
        byte[] seed = EncryptionService.decryptSeed(encrypted,
                state.config().masterEncryptionKey());

        // Derive private key
        byte[] privateKey = WalletService.derivePrivateKey(seed, 0);

        var blockchain = state.blockchainService();

        // Check POL balance for gas
        BigInteger polBalance = blockchain.getNativeBalance(walletData.publicAddress());
        if (polBalance.compareTo(MIN_GAS_POL) < 0) {
            throw ApiException.validation(
                    "Insufficient POL for gas fees. You need at least 0.01 POL.");
        }

        String txHash;
        if ("POL".equals(request.currencyCode())) {
            BigInteger amount = BlockchainService.parseAmount(request.amount(), 18);
            if (polBalance.compareTo(amount.add(MIN_GAS_POL)) < 0) {
                throw ApiException.validation(
                        "Insufficient POL balance (need to keep some for gas fees)");
            }
            txHash = blockchain.sendNativeTransaction(privateKey, request.toAddress(), amount);
        } else {
            var contractInfo = walletDao.getContractInfo(request.currencyCode())
                    .orElseThrow(() -> ApiException.validation(
                            "Currency " + request.currencyCode() + " not supported"));

            if (contractInfo.contractAddress() == null) {
                throw ApiException.validation(
                        "No contract address for " + request.currencyCode());
            }

            BigInteger amount = BlockchainService.parseAmount(request.amount(),
                    contractInfo.decimals());
            txHash = blockchain.sendErc20Transaction(privateKey,
                    contractInfo.contractAddress(), request.toAddress(), amount);
        }

        log.info("Transaction sent: {} {} to {} - hash: {}",
                request.amount(), request.currencyCode(), request.toAddress(), txHash);

        ctx.json(new SendResponse(true, txHash,
                String.format("Successfully sent %s %s to %s",
                        request.amount(), request.currencyCode(), request.toAddress())));
    }

    /** POST /v1/send/estimate */
    public void estimateTransaction(Context ctx) throws Exception {
        var claims = AuthExtractor.extractAccessToken(ctx, state.jwt());
        var request = ctx.bodyAsClass(EstimateRequest.class);

        var walletAddr = walletDao.getPrimaryPolygonAddress(claims.sub())
                .orElseThrow(() -> ApiException.validation("No wallet found"));

        var blockchain = state.blockchainService();
        BigInteger gasPrice = blockchain.getGasPrice();
        BigInteger polBalance = blockchain.getNativeBalance(walletAddr.publicAddress());

        BigInteger estimatedGas = "POL".equals(request.currencyCode())
                ? BigInteger.valueOf(21000) : BigInteger.valueOf(65000);

        BigInteger estimatedFee = estimatedGas.multiply(gasPrice);
        // +20% buffer
        BigInteger estimatedFeeWithBuffer = estimatedFee.multiply(BigInteger.valueOf(120))
                .divide(BigInteger.valueOf(100));

        BigInteger maxAmount;
        String maxAmountFormatted;

        if ("POL".equals(request.currencyCode())) {
            maxAmount = polBalance.compareTo(estimatedFeeWithBuffer) > 0
                    ? polBalance.subtract(estimatedFeeWithBuffer) : BigInteger.ZERO;
            maxAmountFormatted = BlockchainService.formatU256(maxAmount, 18);
        } else {
            var contractInfo = walletDao.getContractInfo(request.currencyCode())
                    .orElseThrow(() -> ApiException.validation("Currency not supported"));

            if (contractInfo.contractAddress() == null) {
                throw ApiException.validation("No contract address");
            }

            BigInteger tokenBalance = blockchain.getErc20Balance(
                    contractInfo.contractAddress(), walletAddr.publicAddress());
            maxAmount = tokenBalance;
            maxAmountFormatted = BlockchainService.formatU256(tokenBalance,
                    contractInfo.decimals());
        }

        ctx.json(new EstimateResponse(
                estimatedGas.toString(),
                gasPrice.toString(),
                estimatedFeeWithBuffer.toString(),
                BlockchainService.formatU256(estimatedFeeWithBuffer, 18),
                maxAmount.toString(),
                maxAmountFormatted
        ));
    }
}
