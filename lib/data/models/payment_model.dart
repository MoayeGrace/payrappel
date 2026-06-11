class PaymentModel {
  final String id;
  final String userId;
  final String invoiceId;
  final String invoiceTitle;
  final String clientId;
  final double amount;
  final String note;
  final DateTime paidAt;
  final String paymentMethodId;
  final String paymentMethodLabel;
  final String paymentReference;

  const PaymentModel({
    required this.id,
    required this.userId,
    required this.invoiceId,
    this.invoiceTitle = '',
    required this.clientId,
    required this.amount,
    this.note = '',
    required this.paidAt,
    this.paymentMethodId = '',
    this.paymentMethodLabel = '',
    this.paymentReference = '',
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
      paymentMethodId: map['paymentMethodId'] as String? ?? '',
      paymentMethodLabel: map['paymentMethodLabel'] as String? ?? '',
      paymentReference: map['paymentReference'] as String? ?? '',
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
      'paymentMethodId': paymentMethodId,
      'paymentMethodLabel': paymentMethodLabel,
      'paymentReference': paymentReference,
    };
  }
}
