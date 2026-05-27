enum InvoiceStatus { draft, partial, paid, late }

class InvoiceModel {
  final String id;
  final String userId;
  final String clientId;
  final String clientName; // dénormalisé pour l'affichage rapide
  final String title;
  final double totalAmount;
  final double paidAmount; // mis à jour à chaque paiement
  final DateTime dueDate;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceModel({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.dueDate,
    this.status = InvoiceStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => totalAmount - paidAmount;

  bool get isFullyPaid => paidAmount >= totalAmount;

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.fromMillisecondsSinceEpoch(
        map['dueDate'] as int? ?? 0,
      ),
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientId': clientId,
      'clientName': clientName,
      'title': title,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  InvoiceModel copyWith({
    String? title,
    double? totalAmount,
    double? paidAmount,
    DateTime? dueDate,
    InvoiceStatus? status,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id,
      userId: userId,
      clientId: clientId,
      clientName: clientName,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
