import 'package:flutter_app/services/api_client.dart';

class EstimateResponse {
  final String estimatedGas;
  final String gasPrice;
  final String estimatedFee;
  final String estimatedFeeFormatted;
  final String maxAmount;
  final String maxAmountFormatted;

  EstimateResponse({
    required this.estimatedGas,
    required this.gasPrice,
    required this.estimatedFee,
    required this.estimatedFeeFormatted,
    required this.maxAmount,
    required this.maxAmountFormatted,
  });

  factory EstimateResponse.fromJson(Map<String, dynamic> json) {
    return EstimateResponse(
      estimatedGas: json['estimated_gas'].toString(),
      gasPrice: json['gas_price'].toString(),
      estimatedFee: json['estimated_fee'].toString(),
      estimatedFeeFormatted: json['estimated_fee_formatted'] as String,
      maxAmount: json['max_amount'].toString(),
      maxAmountFormatted: json['max_amount_formatted'] as String,
    );
  }
}

class SendResponse {
  final bool success;
  final String transactionHash;
  final String? message;

  SendResponse({
    required this.success,
    required this.transactionHash,
    this.message,
  });

  factory SendResponse.fromJson(Map<String, dynamic> json) {
    return SendResponse(
      success: json['success'] as bool,
      transactionHash: json['transaction_hash'] as String,
      message: json['message'] as String?,
    );
  }
}

class SendService {
  static final SendService _instance = SendService._();
  factory SendService() => _instance;
  SendService._();

  final _api = ApiClient();

  Future<EstimateResponse> estimateTransaction({
    required String toAddress,
    required String amount,
    required String currencyCode,
  }) async {
    final data = await _api.post('/send/estimate', body: {
      'to_address': toAddress,
      'amount': amount,
      'currency_code': currencyCode,
    });
    return EstimateResponse.fromJson(data);
  }

  Future<SendResponse> sendTransaction({
    required String toAddress,
    required String amount,
    required String currencyCode,
  }) async {
    final data = await _api.post('/send', body: {
      'to_address': toAddress,
      'amount': amount,
      'currency_code': currencyCode,
    });
    return SendResponse.fromJson(data);
  }
}
