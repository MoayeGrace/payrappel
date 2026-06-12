import 'package:flutter/foundation.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';

class InvoiceProvider extends ChangeNotifier {
  final _repo = InvoiceRepository();

  Stream<List<InvoiceModel>> watchInvoices() => _repo.watchInvoices();

  Stream<List<InvoiceModel>> watchInvoicesByClient(String clientId) =>
      _repo.watchInvoicesByClient(clientId);

  Stream<InvoiceModel?> watchInvoice(String id) => _repo.watchInvoice(id);

  Future<InvoiceModel> addInvoice({
    required String clientId,
    required String clientName,
    required String title,
    required double totalAmount,
    required DateTime dueDate,
    List<Map<String, String>> customFields = const [],
    List<Map<String, dynamic>> lineItems = const [],
    double discountAmount = 0,
    double? globalPrice,
  }) =>
      _repo.addInvoice(
        clientId: clientId,
        clientName: clientName,
        title: title,
        totalAmount: totalAmount,
        dueDate: dueDate,
        customFields: customFields,
        lineItems: lineItems,
        discountAmount: discountAmount,
        globalPrice: globalPrice,
      );

  Future<void> updateInvoice(InvoiceModel invoice) =>
      _repo.updateInvoice(invoice);

  Future<void> deleteInvoice(String invoiceId) =>
      _repo.deleteInvoice(invoiceId);

  Future<void> refreshLateStatuses() => _repo.refreshLateStatuses();
}
