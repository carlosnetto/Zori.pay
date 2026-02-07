import 'package:flutter_app/services/api_client.dart';

class Transaction {
  final String hash;
  final int? blockNumber;
  final int timestamp;
  final String from;
  final String to;
  final String value;
  final String formattedValue;
  final String currencyCode;
  final int decimals;
  final String? status;

  Transaction({
    required this.hash,
    this.blockNumber,
    required this.timestamp,
    required this.from,
    required this.to,
    required this.value,
    required this.formattedValue,
    required this.currencyCode,
    required this.decimals,
    this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      hash: json['hash'] as String,
      blockNumber: json['block_number'] as int?,
      timestamp: json['timestamp'] as int,
      from: json['from'] as String,
      to: json['to'] as String,
      value: json['value'].toString(),
      formattedValue: json['formatted_value'] as String,
      currencyCode: json['currency_code'] as String,
      decimals: json['decimals'] as int,
      status: json['status'] as String?,
    );
  }
}

class TransactionsResponse {
  final String address;
  final String blockchain;
  final String currencyCode;
  final List<Transaction> transactions;

  TransactionsResponse({
    required this.address,
    required this.blockchain,
    required this.currencyCode,
    required this.transactions,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['transactions'] as List)
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
    return TransactionsResponse(
      address: json['address'] as String,
      blockchain: json['blockchain'] as String,
      currencyCode: json['currency_code'] as String,
      transactions: list,
    );
  }
}

class TransactionService {
  static final TransactionService _instance = TransactionService._();
  factory TransactionService() => _instance;
  TransactionService._();

  final _api = ApiClient();

  Future<TransactionsResponse> getTransactions(
    String currencyCode, {
    int limit = 10,
  }) async {
    final data = await _api.get(
      '/transactions?currency_code=$currencyCode&limit=$limit',
    );
    return TransactionsResponse.fromJson(data);
  }
}
