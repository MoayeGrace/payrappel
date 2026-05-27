import 'package:flutter/foundation.dart';
import '../data/models/payment_model.dart';
import '../data/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final _repo = PaymentRepository();

  Stream<List<PaymentModel>> watchPaymentsByInvoice(String invoiceId) =>
      _repo.watchPaymentsByInvoice(invoiceId);

  Stream<List<PaymentModel>> watchAllPayments() => _repo.watchAllPayments();

  Future<PaymentModel> addPayment({
    required String invoiceId,
    required String invoiceTitle,
    required String clientId,
    required double amount,
    String note = '',
    DateTime? paidAt,
  }) =>
      _repo.addPayment(
        invoiceId: invoiceId,
        invoiceTitle: invoiceTitle,
        clientId: clientId,
        amount: amount,
        note: note,
        paidAt: paidAt,
      );

  Future<void> deletePayment(String paymentId, String invoiceId) =>
      _repo.deletePayment(paymentId, invoiceId);
}
