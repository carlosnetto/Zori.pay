import 'package:flutter_app/services/api_client.dart';

class PersonalInfo {
  final String fullName;
  final String? dateOfBirth;
  final String? birthCity;
  final String? birthCountry;

  PersonalInfo({required this.fullName, this.dateOfBirth, this.birthCity, this.birthCountry});

  factory PersonalInfo.fromJson(Map<String, dynamic> json) => PersonalInfo(
    fullName: json['full_name'] ?? '',
    dateOfBirth: json['date_of_birth'],
    birthCity: json['birth_city'],
    birthCountry: json['birth_country'],
  );
}

class PhoneInfo {
  final String phoneNumber;
  final String? phoneType;
  final bool isPrimaryForLogin;

  PhoneInfo({required this.phoneNumber, this.phoneType, required this.isPrimaryForLogin});

  factory PhoneInfo.fromJson(Map<String, dynamic> json) => PhoneInfo(
    phoneNumber: json['phone_number'] ?? '',
    phoneType: json['phone_type'],
    isPrimaryForLogin: json['is_primary_for_login'] ?? false,
  );
}

class EmailInfo {
  final String emailAddress;
  final String? emailType;
  final bool isPrimaryForLogin;

  EmailInfo({required this.emailAddress, this.emailType, required this.isPrimaryForLogin});

  factory EmailInfo.fromJson(Map<String, dynamic> json) => EmailInfo(
    emailAddress: json['email_address'] ?? '',
    emailType: json['email_type'],
    isPrimaryForLogin: json['is_primary_for_login'] ?? false,
  );
}

class ContactInfo {
  final List<PhoneInfo> phones;
  final List<EmailInfo> emails;

  ContactInfo({required this.phones, required this.emails});

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
    phones: (json['phones'] as List<dynamic>? ?? []).map((p) => PhoneInfo.fromJson(p)).toList(),
    emails: (json['emails'] as List<dynamic>? ?? []).map((e) => EmailInfo.fromJson(e)).toList(),
  );
}

class AddressInfo {
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  AddressInfo({this.line1, this.line2, this.city, this.state, this.postalCode, this.country});

  factory AddressInfo.fromJson(Map<String, dynamic> json) => AddressInfo(
    line1: json['line1'],
    line2: json['line2'],
    city: json['city'],
    state: json['state'],
    postalCode: json['postal_code'],
    country: json['country'],
  );
}

class BlockchainInfo {
  final String? polygonAddress;

  BlockchainInfo({this.polygonAddress});

  factory BlockchainInfo.fromJson(Map<String, dynamic> json) => BlockchainInfo(
    polygonAddress: json['polygon_address'],
  );
}

class BrazilBankAccount {
  final String? bankCode;
  final String? branchNumber;
  final String? accountNumber;

  BrazilBankAccount({this.bankCode, this.branchNumber, this.accountNumber});

  factory BrazilBankAccount.fromJson(Map<String, dynamic> json) => BrazilBankAccount(
    bankCode: json['bank_code'],
    branchNumber: json['branch_number'],
    accountNumber: json['account_number'],
  );
}

class UsaBankAccount {
  final String routingNumber;
  final String accountNumber;

  UsaBankAccount({required this.routingNumber, required this.accountNumber});

  factory UsaBankAccount.fromJson(Map<String, dynamic> json) => UsaBankAccount(
    routingNumber: json['routing_number'] ?? '',
    accountNumber: json['account_number'] ?? '',
  );
}

class AccountsInfo {
  final BrazilBankAccount? brazil;
  final UsaBankAccount? usa;

  AccountsInfo({this.brazil, this.usa});

  factory AccountsInfo.fromJson(Map<String, dynamic> json) => AccountsInfo(
    brazil: json['brazil'] != null ? BrazilBankAccount.fromJson(json['brazil']) : null,
    usa: json['usa'] != null ? UsaBankAccount.fromJson(json['usa']) : null,
  );
}

class BrazilDocuments {
  final String cpf;
  final String? rgNumber;
  final String? rgIssuer;
  final String? rgIssuedAt;

  BrazilDocuments({required this.cpf, this.rgNumber, this.rgIssuer, this.rgIssuedAt});

  factory BrazilDocuments.fromJson(Map<String, dynamic> json) => BrazilDocuments(
    cpf: json['cpf'] ?? '',
    rgNumber: json['rg_number'],
    rgIssuer: json['rg_issuer'],
    rgIssuedAt: json['rg_issued_at'],
  );
}

class UsaDocuments {
  final String? ssnLast4;
  final String? driversLicenseNumber;
  final String? driversLicenseState;

  UsaDocuments({this.ssnLast4, this.driversLicenseNumber, this.driversLicenseState});

  factory UsaDocuments.fromJson(Map<String, dynamic> json) => UsaDocuments(
    ssnLast4: json['ssn_last4'],
    driversLicenseNumber: json['drivers_license_number'],
    driversLicenseState: json['drivers_license_state'],
  );
}

class DocumentsInfo {
  final BrazilDocuments? brazil;
  final UsaDocuments? usa;

  DocumentsInfo({this.brazil, this.usa});

  factory DocumentsInfo.fromJson(Map<String, dynamic> json) => DocumentsInfo(
    brazil: json['brazil'] != null ? BrazilDocuments.fromJson(json['brazil']) : null,
    usa: json['usa'] != null ? UsaDocuments.fromJson(json['usa']) : null,
  );
}

class ProfileResponse {
  final PersonalInfo? personal;
  final ContactInfo? contact;
  final AddressInfo? address;
  final BlockchainInfo? blockchain;
  final AccountsInfo? accounts;
  final DocumentsInfo? documents;

  ProfileResponse({this.personal, this.contact, this.address, this.blockchain, this.accounts, this.documents});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => ProfileResponse(
    personal: json['personal'] != null ? PersonalInfo.fromJson(json['personal']) : null,
    contact: json['contact'] != null ? ContactInfo.fromJson(json['contact']) : null,
    address: json['address'] != null ? AddressInfo.fromJson(json['address']) : null,
    blockchain: json['blockchain'] != null ? BlockchainInfo.fromJson(json['blockchain']) : null,
    accounts: json['accounts'] != null ? AccountsInfo.fromJson(json['accounts']) : null,
    documents: json['documents'] != null ? DocumentsInfo.fromJson(json['documents']) : null,
  );
}

class ProfileService {
  final _client = ApiClient();

  Future<ProfileResponse> getProfile() async {
    final data = await _client.get('/profile');
    return ProfileResponse.fromJson(data);
  }
}
