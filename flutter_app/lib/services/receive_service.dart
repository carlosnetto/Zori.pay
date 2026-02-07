import 'package:flutter_app/services/api_client.dart';

class ReceiveResponse {
  final String blockchain;
  final String address;

  ReceiveResponse({required this.blockchain, required this.address});

  factory ReceiveResponse.fromJson(Map<String, dynamic> json) {
    return ReceiveResponse(
      blockchain: json['blockchain'] as String,
      address: json['address'] as String,
    );
  }
}

class ReceiveService {
  static final ReceiveService _instance = ReceiveService._();
  factory ReceiveService() => _instance;
  ReceiveService._();

  final _api = ApiClient();

  Future<ReceiveResponse> getReceiveAddress() async {
    final data = await _api.get('/receive');
    return ReceiveResponse.fromJson(data);
  }
}
