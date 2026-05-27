class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String activityName;
  final String activityType;
  final bool isPro;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.activityName,
    required this.activityType,
    this.isPro = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      activityName: map['activityName'] as String? ?? '',
      activityType: map['activityType'] as String? ?? '',
      isPro: map['isPro'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'activityName': activityName,
      'activityType': activityType,
      'isPro': isPro,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? activityName,
    String? activityType,
    bool? isPro,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      activityName: activityName ?? this.activityName,
      activityType: activityType ?? this.activityType,
      isPro: isPro ?? this.isPro,
      createdAt: createdAt,
    );
  }
}
