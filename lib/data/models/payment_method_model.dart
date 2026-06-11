import 'package:flutter/material.dart';

/// Types de moyens de paiement prédéfinis.
enum PaymentMethodType {
  orangeMoney,
  moovMoney,
  wave,
  mtnMomo,
  djamo,
  visa,
  mastercard,
  stripe,
  paypal,
  custom,
}

extension PaymentMethodTypeExt on PaymentMethodType {
  String get key {
    switch (this) {
      case PaymentMethodType.orangeMoney:  return 'orange_money';
      case PaymentMethodType.moovMoney:    return 'moov_money';
      case PaymentMethodType.wave:         return 'wave';
      case PaymentMethodType.mtnMomo:      return 'mtn_momo';
      case PaymentMethodType.djamo:        return 'djamo';
      case PaymentMethodType.visa:         return 'visa';
      case PaymentMethodType.mastercard:   return 'mastercard';
      case PaymentMethodType.stripe:       return 'stripe';
      case PaymentMethodType.paypal:       return 'paypal';
      case PaymentMethodType.custom:       return 'custom';
    }
  }

  String get defaultLabel {
    switch (this) {
      case PaymentMethodType.orangeMoney:  return 'Orange Money';
      case PaymentMethodType.moovMoney:    return 'Moov Money';
      case PaymentMethodType.wave:         return 'Wave';
      case PaymentMethodType.mtnMomo:      return 'MTN MoMo';
      case PaymentMethodType.djamo:        return 'Djamo';
      case PaymentMethodType.visa:         return 'Visa';
      case PaymentMethodType.mastercard:   return 'Mastercard';
      case PaymentMethodType.stripe:       return 'Stripe';
      case PaymentMethodType.paypal:       return 'PayPal';
      case PaymentMethodType.custom:       return 'Autre';
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethodType.orangeMoney:  return const Color(0xFFFF6600);
      case PaymentMethodType.moovMoney:    return const Color(0xFF003399);
      case PaymentMethodType.wave:         return const Color(0xFF1A9EDB);
      case PaymentMethodType.mtnMomo:      return const Color(0xFFFFCC00);
      case PaymentMethodType.djamo:        return const Color(0xFF6C3CE1);
      case PaymentMethodType.visa:         return const Color(0xFF1A1F71);
      case PaymentMethodType.mastercard:   return const Color(0xFFEB001B);
      case PaymentMethodType.stripe:       return const Color(0xFF635BFF);
      case PaymentMethodType.paypal:       return const Color(0xFF003087);
      case PaymentMethodType.custom:       return const Color(0xFF607D8B);
    }
  }

  String? get assetPath {
    switch (this) {
      case PaymentMethodType.orangeMoney:  return 'assets/orange_money.png';
      case PaymentMethodType.moovMoney:    return 'assets/moov-money.png';
      case PaymentMethodType.wave:         return 'assets/wave_money.png';
      case PaymentMethodType.mtnMomo:      return 'assets/mtn_momo.webp';
      case PaymentMethodType.djamo:        return 'assets/Djamo-Logo.png';
      case PaymentMethodType.stripe:       return 'assets/stripe.png';
      case PaymentMethodType.paypal:       return 'assets/paypal.png';
      case PaymentMethodType.visa:        return 'assets/VISA.png';
      case PaymentMethodType.mastercard:  return 'assets/MASTERCARD.webp';
      case PaymentMethodType.custom:      return null;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodType.orangeMoney:
      case PaymentMethodType.moovMoney:
      case PaymentMethodType.wave:
      case PaymentMethodType.mtnMomo:
      case PaymentMethodType.djamo:
        return Icons.phone_android_outlined;
      case PaymentMethodType.visa:
      case PaymentMethodType.mastercard:
        return Icons.credit_card_outlined;
      case PaymentMethodType.stripe:
      case PaymentMethodType.paypal:
        return Icons.language_outlined;
      case PaymentMethodType.custom:
        return Icons.account_balance_wallet_outlined;
    }
  }

  /// Champs à remplir pour ce type, avec leur libellé et hint.
  List<PaymentFieldDef> get fieldDefs {
    switch (this) {
      case PaymentMethodType.orangeMoney:
      case PaymentMethodType.moovMoney:
      case PaymentMethodType.wave:
      case PaymentMethodType.mtnMomo:
      case PaymentMethodType.djamo:
        return const [
          PaymentFieldDef('phone', 'Numéro de téléphone', '+225 07 XX XX XX XX',
              TextInputType.phone),
        ];
      case PaymentMethodType.visa:
      case PaymentMethodType.mastercard:
        return const [
          PaymentFieldDef('cardHolder', 'Nom du titulaire', 'Jean DUPONT',
              TextInputType.name),
          PaymentFieldDef('cardNumber', 'Numéro de carte (4 derniers chiffres)',
              '1234', TextInputType.number),
        ];
      case PaymentMethodType.stripe:
        return const [
          PaymentFieldDef('stripeLink', 'Lien de paiement Stripe',
              'https://buy.stripe.com/...', TextInputType.url),
        ];
      case PaymentMethodType.paypal:
        return const [
          PaymentFieldDef('paypalEmail', 'Email ou lien PayPal',
              'moncompte@paypal.com', TextInputType.emailAddress),
        ];
      case PaymentMethodType.custom:
        return const [];
    }
  }

  static PaymentMethodType fromKey(String key) {
    return PaymentMethodType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => PaymentMethodType.custom,
    );
  }
}

class PaymentFieldDef {
  final String key;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  const PaymentFieldDef(this.key, this.label, this.hint, this.keyboardType);
}

// ─────────────────────────────────────────────────────────────────────────────

class PaymentMethodModel {
  final String id;
  final PaymentMethodType type;
  final String label;
  final Map<String, String> fields;
  final String? logoPath;
  final bool isEnabled;

  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.label,
    this.fields = const {},
    this.logoPath,
    this.isEnabled = true,
  });

  List<PaymentFieldDef> get fieldDefs => type.fieldDefs;

  PaymentMethodModel copyWith({
    String? label,
    Map<String, String>? fields,
    String? logoPath,
    bool? isEnabled,
    bool clearLogo = false,
  }) {
    return PaymentMethodModel(
      id: id,
      type: type,
      label: label ?? this.label,
      fields: fields ?? this.fields,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] as String? ?? '',
      type: PaymentMethodTypeExt.fromKey(map['type'] as String? ?? 'custom'),
      label: map['label'] as String? ?? '',
      fields: (map['fields'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      logoPath: map['logoPath'] as String?,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.key,
      'label': label,
      'fields': fields,
      if (logoPath != null) 'logoPath': logoPath,
      'isEnabled': isEnabled,
    };
  }
}
