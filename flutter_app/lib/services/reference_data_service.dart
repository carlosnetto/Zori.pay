import 'package:flutter_app/services/api_client.dart';

class Country {
  final String isoCode;
  final String name;
  Country({required this.isoCode, required this.name});
  factory Country.fromJson(Map<String, dynamic> json) => Country(
    isoCode: json['iso_code'] ?? '',
    name: json['name'] ?? '',
  );
}

class PhoneType {
  final String code;
  final String description;
  PhoneType({required this.code, required this.description});
  factory PhoneType.fromJson(Map<String, dynamic> json) => PhoneType(
    code: json['code'] ?? '',
    description: json['description'] ?? '',
  );
}

class EmailType {
  final String code;
  final String description;
  EmailType({required this.code, required this.description});
  factory EmailType.fromJson(Map<String, dynamic> json) => EmailType(
    code: json['code'] ?? '',
    description: json['description'] ?? '',
  );
}

class ReferenceData {
  final List<Country> countries;
  final List<PhoneType> phoneTypes;
  final List<EmailType> emailTypes;

  ReferenceData({required this.countries, required this.phoneTypes, required this.emailTypes});

  factory ReferenceData.fromJson(Map<String, dynamic> json) => ReferenceData(
    countries: (json['countries'] as List<dynamic>? ?? []).map((c) => Country.fromJson(c)).toList(),
    phoneTypes: (json['phone_types'] as List<dynamic>? ?? []).map((p) => PhoneType.fromJson(p)).toList(),
    emailTypes: (json['email_types'] as List<dynamic>? ?? []).map((e) => EmailType.fromJson(e)).toList(),
  );
}

class ReferenceDataService {
  final _client = ApiClient();
  static ReferenceData? _cached;

  Future<ReferenceData> getReferenceData() async {
    if (_cached != null) return _cached!;
    final data = await _client.get('/reference-data');
    _cached = ReferenceData.fromJson(data);
    return _cached!;
  }
}
