import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import '../../domain/invoice_calculator.dart';

const _kWriteTimeout = Duration(seconds: 5);

class InvoiceRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('invoices');

  // Toutes les factures, en temps réel
  Stream<List<InvoiceModel>> watchInvoices() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Factures d'un client spécifique
  Stream<List<InvoiceModel>> watchInvoicesByClient(String clientId) {
    return _collection
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Écouter une facture spécifique en temps réel
  Stream<InvoiceModel?> watchInvoice(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InvoiceModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Factures en retard
  Stream<List<InvoiceModel>> watchLateInvoices() {
    return _collection
        .where('status', isEqualTo: InvoiceStatus.late.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Créer une facture
  Future<InvoiceModel> addInvoice({
    required String clientId,
    required String clientName,
    required String title,
    required double totalAmount,
    required DateTime dueDate,
    List<Map<String, String>> customFields = const [],
    List<Map<String, dynamic>> lineItems = const [],
    List<Map<String, dynamic>> extraColumns = const [],
    double discountAmount = 0,
    double? globalPrice,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final invoice = InvoiceModel(
      id: id,
      userId: _uid,
      clientId: clientId,
      clientName: clientName,
      title: title,
      totalAmount: totalAmount,
      paidAmount: 0,
      dueDate: dueDate,
      status: InvoiceCalculator.computeStatus(
        totalAmount: totalAmount,
        paidAmount: 0,
        dueDate: dueDate,
      ),
      createdAt: now,
      updatedAt: now,
      customFields: customFields,
      lineItems: lineItems,
      extraColumns: extraColumns,
      discountAmount: discountAmount,
      globalPrice: globalPrice,
    );
    await _collection.doc(id).set(invoice.toMap()).timeout(_kWriteTimeout, onTimeout: () {});
    return invoice;
  }

  // Mettre à jour le montant payé et recalculer le statut
  Future<void> updatePaidAmount(String invoiceId, double newPaidAmount) async {
    final doc = await _collection.doc(invoiceId).get();
    if (!doc.exists) return;

    final invoice = InvoiceModel.fromMap(doc.data()!, doc.id);
    final newStatus = InvoiceCalculator.computeStatus(
      totalAmount: invoice.totalAmount,
      paidAmount: newPaidAmount,
      dueDate: invoice.dueDate,
    );

    await _collection.doc(invoiceId).update({
      'paidAmount': newPaidAmount,
      'status': newStatus.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }).timeout(_kWriteTimeout, onTimeout: () {});
  }

  // Modifier une facture
  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _collection.doc(invoice.id).update(invoice.toMap()).timeout(_kWriteTimeout, onTimeout: () {});
  }

  // Supprimer une facture
  Future<void> deleteInvoice(String invoiceId) async {
    await _collection.doc(invoiceId).delete().timeout(_kWriteTimeout, onTimeout: () {});
  }

  // Recalcule et met à jour les statuts des factures en retard
  Future<void> refreshLateStatuses() async {
    final now = DateTime.now();
    final snap = await _collection
        .where('status', whereIn: [
          InvoiceStatus.draft.name,
          InvoiceStatus.partial.name,
        ])
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      final invoice = InvoiceModel.fromMap(doc.data(), doc.id);
      if (now.isAfter(invoice.dueDate)) {
        batch.update(doc.reference, {
          'status': InvoiceStatus.late.name,
          'updatedAt': now.millisecondsSinceEpoch,
        });
      }
    }
    await batch.commit().timeout(_kWriteTimeout, onTimeout: () {});
  }
}
