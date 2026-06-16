import 'payment_method_model.dart';

class BusinessProfileModel {
  final String companyName;
  final String ownerName;
  final String address;
  final String phone;
  final String email;
  final String rccm;
  // bankName / bankAccount kept for backward-compat with Firestore data.
  // New users manage bank info via PaymentMethodType.bankTransfer.
  final String bankName;
  final String bankAccount;
  final String footerText;
  final String? logoPath;
  final List<PaymentMethodModel> paymentMethods;
  final String currency;

  const BusinessProfileModel({
    this.companyName = '',
    this.ownerName = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.rccm = '',
    this.bankName = '',
    this.bankAccount = '',
    this.footerText = '',
    this.logoPath,
    this.paymentMethods = const [],
    this.currency = 'FCFA',
  });

  bool get isEmpty => companyName.isEmpty && ownerName.isEmpty;
  bool get hasLogo => logoPath != null && logoPath!.isNotEmpty;

  List<PaymentMethodModel> get enabledPaymentMethods =>
      paymentMethods.where((m) => m.isEnabled).toList();

  BusinessProfileModel copyWith({
    String? companyName,
    String? ownerName,
    String? address,
    String? phone,
    String? email,
    String? rccm,
    String? bankName,
    String? bankAccount,
    String? footerText,
    String? logoPath,
    bool clearLogo = false,
    List<PaymentMethodModel>? paymentMethods,
    String? currency,
  }) {
    return BusinessProfileModel(
      companyName: companyName ?? this.companyName,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rccm: rccm ?? this.rccm,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      footerText: footerText ?? this.footerText,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      paymentMethods: paymentMethods ?? this.paymentMethods,
      currency: currency ?? this.currency,
    );
  }

  factory BusinessProfileModel.fromMap(Map<String, dynamic> map) {
    final rawMethods = map['paymentMethods'] as List<dynamic>?;
    return BusinessProfileModel(
      companyName: map['companyName'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      rccm: map['rccm'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      bankAccount: map['bankAccount'] as String? ?? '',
      footerText: map['footerText'] as String? ?? '',
      logoPath: map['logoPath'] as String?,
      paymentMethods: rawMethods
              ?.map((e) =>
                  PaymentMethodModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      currency: map['currency'] as String? ?? 'FCFA',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'ownerName': ownerName,
      'address': address,
      'phone': phone,
      'email': email,
      'rccm': rccm,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'footerText': footerText,
      'logoPath': logoPath,
      'paymentMethods': paymentMethods.map((m) => m.toMap()).toList(),
      'currency': currency,
    };
  }
}
