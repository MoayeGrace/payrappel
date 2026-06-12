import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';
import 'invoice_repository.dart';

const _kWriteTimeout = Duration(seconds: 5);

class PaymentRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();
  final _invoiceRepo = InvoiceRepository();

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('payments');

  // Paiements d'une facture, en temps réel
  Stream<List<PaymentModel>> watchPaymentsByInvoice(String invoiceId) {
    return _collection
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Tous les paiements, en temps réel
  Stream<List<PaymentModel>> watchAllPayments() {
    return _collection
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Enregistrer un paiement et mettre à jour la facture automatiquement
  Future<PaymentModel> addPayment({
    required String invoiceId,
    required String invoiceTitle,
    required String clientId,
    required double amount,
    String note = '',
    DateTime? paidAt,
    String paymentMethodId = '',
    String paymentMethodLabel = '',
    String paymentReference = '',
    int quantity = 1,
    double unitPrice = 0,
  }) async {
    final id = _uuid.v4();
    final payment = PaymentModel(
      id: id,
      userId: _uid,
      invoiceId: invoiceId,
      invoiceTitle: invoiceTitle,
      clientId: clientId,
      amount: amount,
      note: note,
      paidAt: paidAt ?? DateTime.now(),
      paymentMethodId: paymentMethodId,
      paymentMethodLabel: paymentMethodLabel,
      paymentReference: paymentReference,
      quantity: quantity,
      unitPrice: unitPrice,
    );

    await _collection.doc(id).set(payment.toMap()).timeout(_kWriteTimeout, onTimeout: () {});
    await _recalculateInvoicePaidAmount(invoiceId);

    return payment;
  }

  // Supprimer un paiement et recalculer la facture
  Future<void> deletePayment(String paymentId, String invoiceId) async {
    await _collection.doc(paymentId).delete().timeout(_kWriteTimeout, onTimeout: () {});
    await _recalculateInvoicePaidAmount(invoiceId);
  }

  Future<void> _recalculateInvoicePaidAmount(String invoiceId) async {
    final snap = await _collection
        .where('invoiceId', isEqualTo: invoiceId)
        .get(const GetOptions(source: Source.cache));

    final total = snap.docs.fold<double>(
      0,
      (acc, doc) => acc + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
    );

    await _invoiceRepo.updatePaidAmount(invoiceId, total);
  }
}
