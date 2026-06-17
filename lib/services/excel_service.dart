import 'package:excel/excel.dart';
import '../data/models/client_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/payment_model.dart';

class ExcelExportOptions {
  final DateTime from;
  final DateTime to;
  final bool includeInvoices;
  final bool includePayments;
  final bool includeClients;
  final bool includeStats;

  const ExcelExportOptions({
    required this.from,
    required this.to,
    this.includeInvoices = true,
    this.includePayments = true,
    this.includeClients = false,
    this.includeStats = false,
  });
}

class ExcelService {
  static List<int>? generate({
    required List<InvoiceModel> invoices,
    required List<PaymentModel> payments,
    required List<ClientModel> clients,
    required ExcelExportOptions options,
  }) {
    final excel = Excel.createExcel();
    final defaultSheets = List<String>.from(excel.sheets.keys);

    final filteredInvoices = invoices.where((i) {
      return !i.createdAt.isBefore(options.from) && !i.createdAt.isAfter(options.to);
    }).toList();

    final filteredPayments = payments.where((p) {
      return !p.paidAt.isBefore(options.from) && !p.paidAt.isAfter(options.to);
    }).toList();

    if (options.includeInvoices) {
      _addInvoicesSheet(excel, filteredInvoices);
    }
    if (options.includePayments) {
      _addPaymentsSheet(excel, filteredPayments, clients);
    }
    if (options.includeClients) {
      _addClientsSheet(excel, clients, invoices, payments);
    }
    if (options.includeStats) {
      _addStatsSheet(excel, filteredInvoices, filteredPayments);
    }

    for (final name in defaultSheets) {
      excel.delete(name);
    }

    return excel.save();
  }

  static void _addInvoicesSheet(Excel excel, List<InvoiceModel> invoices) {
    final sheet = excel['Factures'];

    final headers = [
      'Titre', 'Client', 'Montant total', 'Montant payé',
      'Solde restant', 'Statut', 'Date échéance', 'Date création',
    ];
    _writeHeaderRow(sheet, headers);

    for (var i = 0; i < invoices.length; i++) {
      final inv = invoices[i];
      final row = i + 1;
      _setCell(sheet, row, 0, inv.title);
      _setCell(sheet, row, 1, inv.clientName);
      _setDouble(sheet, row, 2, inv.totalAmount);
      _setDouble(sheet, row, 3, inv.paidAmount);
      _setDouble(sheet, row, 4, inv.remainingAmount);
      _setCell(sheet, row, 5, _statusLabel(inv.status));
      _setCell(sheet, row, 6, _formatDate(inv.dueDate));
      _setCell(sheet, row, 7, _formatDate(inv.createdAt));
    }
  }

  static void _addPaymentsSheet(
      Excel excel, List<PaymentModel> payments, List<ClientModel> clients) {
    final sheet = excel['Paiements'];

    final headers = ['Date', 'Client', 'Facture', 'Montant', 'Note'];
    _writeHeaderRow(sheet, headers);

    final clientMap = {for (final c in clients) c.id: c};

    for (var i = 0; i < payments.length; i++) {
      final p = payments[i];
      final clientName = clientMap[p.clientId]?.name ?? '';
      final row = i + 1;
      _setCell(sheet, row, 0, _formatDate(p.paidAt));
      _setCell(sheet, row, 1, clientName);
      _setCell(sheet, row, 2, p.invoiceTitle);
      _setDouble(sheet, row, 3, p.amount);
      _setCell(sheet, row, 4, p.note);
    }
  }

  static void _addClientsSheet(Excel excel, List<ClientModel> clients,
      List<InvoiceModel> invoices, List<PaymentModel> payments) {
    final sheet = excel['Clients'];

    final headers = [
      'Nom', 'Téléphone', 'Email', 'Nb factures',
      'Total facturé', 'Total payé', 'Solde restant',
    ];
    _writeHeaderRow(sheet, headers);

    for (var i = 0; i < clients.length; i++) {
      final c = clients[i];
      final clientInvoices = invoices.where((inv) => inv.clientId == c.id).toList();
      final clientPayments = payments.where((p) => p.clientId == c.id).toList();
      final totalBilled = clientInvoices.fold(0.0, (s, inv) => s + inv.totalAmount);
      final totalPaid = clientPayments.fold(0.0, (s, p) => s + p.amount);

      final row = i + 1;
      _setCell(sheet, row, 0, c.name);
      _setCell(sheet, row, 1, c.phone);
      _setCell(sheet, row, 2, c.email);
      _setInt(sheet, row, 3, clientInvoices.length);
      _setDouble(sheet, row, 4, totalBilled);
      _setDouble(sheet, row, 5, totalPaid);
      _setDouble(sheet, row, 6, totalBilled - totalPaid);
    }
  }

  static void _addStatsSheet(
      Excel excel, List<InvoiceModel> invoices, List<PaymentModel> payments) {
    final sheet = excel['Statistiques'];

    final totalBilled = invoices.fold(0.0, (s, i) => s + i.totalAmount);
    final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
    final totalRemaining = invoices.fold(0.0, (s, i) => s + i.remainingAmount);
    final lateInvoices = invoices.where((i) => i.status == InvoiceStatus.late).length;
    final paidInvoices = invoices.where((i) => i.status == InvoiceStatus.paid).length;
    final recoveryRate = totalBilled > 0 ? (totalPaid / totalBilled * 100) : 0.0;

    final stats = [
      ['Total facturé', totalBilled],
      ['Total encaissé', totalPaid],
      ['Total restant', totalRemaining],
      ['Nb factures', invoices.length.toDouble()],
      ['Nb payées', paidInvoices.toDouble()],
      ['Nb en retard', lateInvoices.toDouble()],
      ['Taux de recouvrement (%)', recoveryRate],
    ];

    _writeHeaderRow(sheet, ['Indicateur', 'Valeur']);
    for (var i = 0; i < stats.length; i++) {
      _setCell(sheet, i + 1, 0, stats[i][0] as String);
      _setDouble(sheet, i + 1, 1, stats[i][1] as double);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static void _writeHeaderRow(Sheet sheet, List<String> headers) {
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#1A73E8'));
    }
  }

  static void _setCell(Sheet sheet, int row, int col, String value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
        TextCellValue(value);
  }

  static void _setDouble(Sheet sheet, int row, int col, double value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
        DoubleCellValue(value);
  }

  static void _setInt(Sheet sheet, int row, int col, int value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
        IntCellValue(value);
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'Payée';
      case InvoiceStatus.partial:
        return 'Partielle';
      case InvoiceStatus.late:
        return 'En retard';
      case InvoiceStatus.draft:
        return 'En cours';
    }
  }
}
