package com.zoripay.api.route;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zoripay.api.AppState;
import com.zoripay.api.auth.AuthExtractor;
import com.zoripay.api.dao.WalletDao;
import com.zoripay.api.error.ApiException;
import com.zoripay.api.model.response.TransactionsResponse;
import com.zoripay.api.model.response.TransactionsResponse.Transaction;
import com.zoripay.api.service.BlockchainService;
import io.javalin.http.Context;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.*;

public class TransactionRoutes {

    private static final Logger log = LoggerFactory.getLogger(TransactionRoutes.class);
    private final AppState state;
    private final WalletDao walletDao;
    private final HttpClient httpClient;
    private final ObjectMapper mapper;

    public TransactionRoutes(AppState state) {
        this.state = state;
        this.walletDao = new WalletDao(state.jdbi());
        this.httpClient = HttpClient.newHttpClient();
        this.mapper = state.mapper();
    }

    /** GET /v1/transactions */
    public void getTransactions(Context ctx) throws Exception {
        var claims = AuthExtractor.extractAccessToken(ctx, state.jwt());

        String currencyCodeFilter = ctx.queryParam("currency_code");
        int limit = Math.min(ctx.queryParamAsClass("limit", Integer.class).getOrDefault(50), 100);

        var walletAddr = walletDao.getPrimaryPolygonAddress(claims.sub())
                .orElseThrow(() -> ApiException.validation(
                        "No Polygon address found for user"));

        String userAddress = walletAddr.publicAddress().toLowerCase();
        String rpcUrl = state.config().polygonRpcUrl();
        String maxCount = "0x" + Integer.toHexString(limit);

        // Fetch sent and received transfers
        var sentTransfers = fetchAlchemyTransfers(rpcUrl, userAddress, maxCount, true);
        var receivedTransfers = fetchAlchemyTransfers(rpcUrl, userAddress, maxCount, false);

        var allTransfers = new ArrayList<>(sentTransfers);
        allTransfers.addAll(receivedTransfers);

        // Get currency contract map
        var contractMap = walletDao.getPolygonCurrencyMap();

        // Collect unique block numbers
        var blockNumbers = new HashSet<Long>();
        for (var transfer : allTransfers) {
            long blockNum = parseHexLong(transfer.get("blockNum").asText());
            if (blockNum > 0) blockNumbers.add(blockNum);
        }

        // Fetch block timestamps
        var blockTimestamps = fetchBlockTimestamps(rpcUrl, blockNumbers);

        // Process transfers
        var seenHashes = new HashSet<String>();
        var transactions = new ArrayList<Transaction>();

        for (var transfer : allTransfers) {
            String hash = transfer.get("hash").asText();
            if (!seenHashes.add(hash)) continue;

            String category = transfer.get("category").asText();
            var rawContract = transfer.get("rawContract");
            String contractAddr = rawContract.has("address") && !rawContract.get("address").isNull()
                    ? rawContract.get("address").asText().toLowerCase() : "";

            // Determine currency
            String currencyCode;
            int decimals;
            if ("external".equals(category)) {
                currencyCode = "POL";
                decimals = 18;
            } else {
                var currency = contractMap.get(contractAddr);
                if (currency == null) continue;
                currencyCode = currency.code();
                decimals = currency.blockchainDecimals();
            }

            // Apply filter
            if (currencyCodeFilter != null && !currencyCodeFilter.equals(currencyCode)) continue;

            // Parse value
            String valueHex = rawContract.get("value").asText().replaceFirst("^0x", "");
            long value = 0;
            try { value = Long.parseUnsignedLong(valueHex, 16); } catch (Exception ignored) {}

            long blockNumber = parseHexLong(transfer.get("blockNum").asText());
            long timestamp = blockTimestamps.getOrDefault(blockNumber, 0L);

            String formattedValue = BlockchainService.formatBalance(
                    java.math.BigInteger.valueOf(value), decimals);

            transactions.add(new Transaction(
                    hash, blockNumber, timestamp,
                    transfer.get("from").asText(),
                    transfer.get("to").asText(),
                    String.valueOf(value),
                    formattedValue, currencyCode, decimals, "confirmed"
            ));
        }

        // Sort by block number descending
        transactions.sort((a, b) -> Long.compare(b.blockNumber(), a.blockNumber()));
        if (transactions.size() > limit) {
            transactions.subList(limit, transactions.size()).clear();
        }

        ctx.json(new TransactionsResponse(userAddress, "POLYGON",
                currencyCodeFilter, transactions));
    }

    private List<JsonNode> fetchAlchemyTransfers(String rpcUrl, String address,
                                                   String maxCount, boolean fromAddress)
            throws Exception {
        String addressParam = fromAddress ? "fromAddress" : "toAddress";

        String payload = mapper.writeValueAsString(Map.of(
                "jsonrpc", "2.0",
                "id", 1,
                "method", "alchemy_getAssetTransfers",
                "params", List.of(Map.of(
                        "fromBlock", "0x0",
                        "toBlock", "latest",
                        addressParam, address,
                        "category", List.of("erc20", "external"),
                        "maxCount", maxCount,
                        "order", "desc"
                ))
        ));

        var request = HttpRequest.newBuilder()
                .uri(URI.create(rpcUrl))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload))
                .build();

        var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        var json = mapper.readTree(response.body());

        var transfers = new ArrayList<JsonNode>();
        var result = json.get("result");
        if (result != null && result.has("transfers")) {
            for (var transfer : result.get("transfers")) {
                transfers.add(transfer);
            }
        }
        return transfers;
    }

    private Map<Long, Long> fetchBlockTimestamps(String rpcUrl,
                                                   Set<Long> blockNumbers) throws Exception {
        var timestamps = new HashMap<Long, Long>();

        for (long blockNum : blockNumbers) {
            String blockHex = "0x" + Long.toHexString(blockNum);
            String payload = mapper.writeValueAsString(Map.of(
                    "jsonrpc", "2.0",
                    "id", 1,
                    "method", "eth_getBlockByNumber",
                    "params", List.of(blockHex, false)
            ));

            var request = HttpRequest.newBuilder()
                    .uri(URI.create(rpcUrl))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(payload))
                    .build();

            var response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            var json = mapper.readTree(response.body());

            var result = json.get("result");
            if (result != null && result.has("timestamp")) {
                long timestamp = parseHexLong(result.get("timestamp").asText());
                timestamps.put(blockNum, timestamp);
            }
        }

        return timestamps;
    }

    private static long parseHexLong(String hex) {
        try {
            return Long.parseUnsignedLong(hex.replaceFirst("^0x", ""), 16);
        } catch (Exception e) {
            return 0;
        }
    }
}
