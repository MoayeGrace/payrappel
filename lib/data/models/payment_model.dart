class PaymentModel {
  final String id;
  final String userId;
  final String invoiceId;
  final String invoiceTitle;
  final String clientId;
  final double amount;
  final String note;
  final DateTime paidAt;

  const PaymentModel({
    required this.id,
    required this.userId,
    required this.invoiceId,
    this.invoiceTitle = '',
    required this.clientId,
    required this.amount,
    this.note = '',
    required this.paidAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      invoiceTitle: map['invoiceTitle'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String? ?? '',
      paidAt: DateTime.fromMillisecondsSinceEpoch(
        map['paidAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'invoiceId': invoiceId,
      'invoiceTitle': invoiceTitle,
      'clientId': clientId,
      'amount': amount,
      'note': note,
      'paidAt': paidAt.millisecondsSinceEpoch,
    };
  }
}
