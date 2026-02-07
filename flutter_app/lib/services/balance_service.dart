import 'package:flutter_app/services/api_client.dart';

class BalanceResponse {
  final String address;
  final String blockchain;
  final List<CurrencyBalance> balances;

  BalanceResponse({
    required this.address,
    required this.blockchain,
    required this.balances,
  });

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['balances'] as List)
        .map((b) => CurrencyBalance.fromJson(b as Map<String, dynamic>))
        .toList();
    return BalanceResponse(
      address: json['address'] as String,
      blockchain: json['blockchain'] as String,
      balances: list,
    );
  }
}

class CurrencyBalance {
  final String currencyCode;
  final String balance;
  final String formattedBalance;
  final int decimals;

  CurrencyBalance({
    required this.currencyCode,
    required this.balance,
    required this.formattedBalance,
    required this.decimals,
  });

  factory CurrencyBalance.fromJson(Map<String, dynamic> json) {
    return CurrencyBalance(
      currencyCode: json['currency_code'] as String,
      balance: json['balance'].toString(),
      formattedBalance: json['formatted_balance'] as String,
      decimals: json['decimals'] as int,
    );
  }
}

class BalanceService {
  static final BalanceService _instance = BalanceService._();
  factory BalanceService() => _instance;
  BalanceService._();

  final _api = ApiClient();

  Future<BalanceResponse> getBalances() async {
    final data = await _api.get('/balance');
    return BalanceResponse.fromJson(data);
  }
}
