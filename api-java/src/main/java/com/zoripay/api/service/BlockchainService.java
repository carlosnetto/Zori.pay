package com.zoripay.api.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.web3j.abi.FunctionEncoder;
import org.web3j.abi.FunctionReturnDecoder;
import org.web3j.abi.TypeReference;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.Function;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.RawTransaction;
import org.web3j.crypto.TransactionEncoder;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.Transaction;
import org.web3j.protocol.http.HttpService;
import org.web3j.utils.Numeric;

import java.math.BigInteger;
import java.util.List;

public class BlockchainService {

    private static final Logger log = LoggerFactory.getLogger(BlockchainService.class);
    private final String rpcUrl;

    public BlockchainService(String rpcUrl) {
        this.rpcUrl = rpcUrl;
    }

    private Web3j web3j() {
        return Web3j.build(new HttpService(rpcUrl));
    }

    public BigInteger getNativeBalance(String address) throws Exception {
        try (var web3 = web3j()) {
            return web3.ethGetBalance(address, DefaultBlockParameterName.LATEST)
                    .send().getBalance();
        }
    }

    public BigInteger getErc20Balance(String contractAddress, String walletAddress)
            throws Exception {
        var function = new Function("balanceOf",
                List.of(new Address(walletAddress)),
                List.of(new TypeReference<Uint256>() {}));

        String encodedFunction = FunctionEncoder.encode(function);

        try (var web3 = web3j()) {
            var response = web3.ethCall(
                    Transaction.createEthCallTransaction(walletAddress, contractAddress,
                            encodedFunction),
                    DefaultBlockParameterName.LATEST
            ).send();

            var results = FunctionReturnDecoder.decode(response.getValue(),
                    function.getOutputParameters());
            if (results.isEmpty()) return BigInteger.ZERO;
            return (BigInteger) results.getFirst().getValue();
        }
    }

    public BigInteger getGasPrice() throws Exception {
        try (var web3 = web3j()) {
            return web3.ethGasPrice().send().getGasPrice();
        }
    }

    public BigInteger getChainId() throws Exception {
        try (var web3 = web3j()) {
            return web3.ethChainId().send().getChainId();
        }
    }

    /**
     * Send native token (POL) transaction.
     */
    public String sendNativeTransaction(byte[] privateKey, String toAddress,
                                         BigInteger amount) throws Exception {
        var credentials = Credentials.create(Numeric.toHexStringNoPrefix(privateKey));

        try (var web3 = web3j()) {
            var nonce = web3.ethGetTransactionCount(
                    credentials.getAddress(), DefaultBlockParameterName.PENDING
            ).send().getTransactionCount();

            var gasPrice = web3.ethGasPrice().send().getGasPrice();
            var gasLimit = BigInteger.valueOf(21000);
            var chainId = web3.ethChainId().send().getChainId().longValue();

            var rawTx = RawTransaction.createEtherTransaction(
                    nonce, gasPrice, gasLimit, toAddress, amount);

            byte[] signedMessage = TransactionEncoder.signMessage(rawTx, chainId, credentials);
            String hexValue = Numeric.toHexString(signedMessage);

            var txHash = web3.ethSendRawTransaction(hexValue).send();
            if (txHash.hasError()) {
                throw new RuntimeException("Transaction failed: " + txHash.getError().getMessage());
            }
            return txHash.getTransactionHash();
        }
    }

    /**
     * Send ERC20 token transfer.
     */
    public String sendErc20Transaction(byte[] privateKey, String contractAddress,
                                        String toAddress, BigInteger amount) throws Exception {
        var credentials = Credentials.create(Numeric.toHexStringNoPrefix(privateKey));

        var transferFunction = new Function("transfer",
                List.of(new Address(toAddress), new Uint256(amount)),
                List.of(new TypeReference<org.web3j.abi.datatypes.Bool>() {}));

        String encodedFunction = FunctionEncoder.encode(transferFunction);

        try (var web3 = web3j()) {
            var nonce = web3.ethGetTransactionCount(
                    credentials.getAddress(), DefaultBlockParameterName.PENDING
            ).send().getTransactionCount();

            var gasPrice = web3.ethGasPrice().send().getGasPrice();
            var gasLimit = BigInteger.valueOf(65000);
            var chainId = web3.ethChainId().send().getChainId().longValue();

            var rawTx = RawTransaction.createTransaction(
                    nonce, gasPrice, gasLimit, contractAddress, BigInteger.ZERO,
                    encodedFunction);

            byte[] signedMessage = TransactionEncoder.signMessage(rawTx, chainId, credentials);
            String hexValue = Numeric.toHexString(signedMessage);

            var txHash = web3.ethSendRawTransaction(hexValue).send();
            if (txHash.hasError()) {
                throw new RuntimeException("Transaction failed: " + txHash.getError().getMessage());
            }
            return txHash.getTransactionHash();
        }
    }

    /**
     * Format a BigInteger balance with proper decimals.
     */
    public static String formatBalance(BigInteger balance, int decimals) {
        if (balance.equals(BigInteger.ZERO)) return "0.00";

        var divisor = BigInteger.TEN.pow(decimals);
        var whole = balance.divide(divisor);
        var remainder = balance.mod(divisor);

        int displayDecimals = 2;
        var decimalDivisor = BigInteger.TEN.pow(Math.max(0, decimals - displayDecimals));
        BigInteger decimalPart;
        if (decimals >= displayDecimals) {
            decimalPart = remainder.divide(decimalDivisor);
        } else {
            decimalPart = remainder.multiply(
                    BigInteger.TEN.pow(displayDecimals - decimals));
        }

        return String.format("%s.%02d", whole, decimalPart.intValue());
    }

    /**
     * Format U256-equivalent value with decimals (capped at 8 for display).
     */
    public static String formatU256(BigInteger value, int decimals) {
        if (value.equals(BigInteger.ZERO)) return "0";

        var divisor = BigInteger.TEN.pow(decimals);
        var whole = value.divide(divisor);
        var remainder = value.mod(divisor);

        if (remainder.equals(BigInteger.ZERO)) return whole.toString();

        String remainderStr = String.format("%0" + decimals + "d", remainder);
        int displayDecimals = Math.min(decimals, 8);
        String truncated = remainderStr.substring(0, displayDecimals);
        String trimmed = truncated.replaceAll("0+$", "");

        if (trimmed.isEmpty()) return whole.toString();
        return whole + "." + trimmed;
    }

    /**
     * Parse a decimal amount string to BigInteger with given decimals.
     */
    public static BigInteger parseAmount(String amount, int decimals) {
        String[] parts = amount.split("\\.");
        long whole;
        try {
            whole = Long.parseLong(parts[0]);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid amount");
        }

        long fraction = 0;
        if (parts.length > 1) {
            String fracStr = parts[1];
            int fracLen = Math.min(fracStr.length(), decimals);
            String fracPadded = String.format("%-" + decimals + "s", fracStr.substring(0, fracLen))
                    .replace(' ', '0');
            try {
                fraction = Long.parseLong(fracPadded);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("Invalid amount");
            }
        }

        long multiplier = (long) Math.pow(10, decimals);
        long total = whole * multiplier + fraction;
        return BigInteger.valueOf(total);
    }
}
