class UserModel {
  final String id;
  final bool isPro;
  final DateTime? proExpiry;
  final String? planType; // 'monthly' | 'annual'

  const UserModel({
    required this.id,
    this.isPro = false,
    this.proExpiry,
    this.planType,
  });

  bool get isProActive {
    if (!isPro) return false;
    if (proExpiry == null) return true;
    return proExpiry!.isAfter(DateTime.now());
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) => UserModel(
        id: id,
        isPro: map['isPro'] as bool? ?? false,
        proExpiry: map['proExpiry'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['proExpiry'] as int)
            : null,
        planType: map['planType'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'isPro': isPro,
        if (proExpiry != null) 'proExpiry': proExpiry!.millisecondsSinceEpoch,
        if (planType != null) 'planType': planType,
      };
}
