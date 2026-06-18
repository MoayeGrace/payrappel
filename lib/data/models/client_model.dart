class ClientModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String note;
  final DateTime createdAt;

  const ClientModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.note = '',
    required this.createdAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      note: map['note'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  ClientModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? note,
  }) {
    return ClientModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
