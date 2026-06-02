class BusinessProfileModel {
  final String companyName;
  final String ownerName;
  final String address;
  final String phone;
  final String email;
  final String rccm;
  final String bankName;
  final String bankAccount;
  final String footerText;
  final String? logoPath;

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
  });

  bool get isEmpty => companyName.isEmpty && ownerName.isEmpty;
  bool get hasLogo => logoPath != null && logoPath!.isNotEmpty;

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
    );
  }

  factory BusinessProfileModel.fromMap(Map<String, dynamic> map) {
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
    };
  }
}
