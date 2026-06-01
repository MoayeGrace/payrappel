import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils/currency_formatter.dart';
import '../data/models/invoice_model.dart';
import '../data/models/payment_model.dart';

class PdfService {
  static const _labelColor = PdfColors.grey700;
  static const _primaryColor = PdfColor.fromInt(0xFF1A73E8);

  // ── Facture PDF ──────────────────────────────────────────────────────────────
  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    String? clientPhone,
    String? clientEmail,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('FACTURE'),
            pw.SizedBox(height: 24),
            _clientBlock(invoice.clientName, clientPhone, clientEmail),
            pw.SizedBox(height: 20),
            _infoBlock(invoice),
            pw.SizedBox(height: 20),
            _amountsBlock(invoice),
            if (payments.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _paymentsTable(payments),
            ],
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Reçu PDF ─────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateReceiptPdf({
    required PaymentModel payment,
    required InvoiceModel invoice,
    String? clientPhone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('RECU DE PAIEMENT'),
            pw.SizedBox(height: 24),
            _clientBlock(invoice.clientName, clientPhone, null),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _primaryColor, width: 1),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _row('Facture', invoice.title),
                  _row('Montant du paiement', CurrencyFormatter.format(payment.amount)),
                  _row('Date', _formatDate(payment.paidAt)),
                  if (payment.note.isNotEmpty) _row('Note', payment.note),
                  pw.Divider(color: _labelColor),
                  _row('Solde restant', CurrencyFormatter.format(invoice.remainingAmount - payment.amount < 0 ? 0 : invoice.remainingAmount - payment.amount), bold: true),
                ],
              ),
            ),
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Partager un PDF ─────────────────────────────────────────────────────────
  static Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ── Widgets internes ────────────────────────────────────────────────────────
  static pw.Widget _header(String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PayRappel',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            pw.Text(
              'Gestion des paiements',
              style: pw.TextStyle(fontSize: 10, color: _labelColor),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _primaryColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _clientBlock(String name, String? phone, String? email) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Client', style: pw.TextStyle(fontSize: 10, color: _labelColor)),
          pw.SizedBox(height: 4),
          pw.Text(name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (phone != null && phone.isNotEmpty)
            pw.Text(phone, style: pw.TextStyle(fontSize: 11, color: _labelColor)),
          if (email != null && email.isNotEmpty)
            pw.Text(email, style: pw.TextStyle(fontSize: 11, color: _labelColor)),
        ],
      ),
    );
  }

  static pw.Widget _infoBlock(InvoiceModel invoice) {
    return pw.Row(
      children: [
        pw.Expanded(child: _labelValue('Facture', invoice.title)),
        pw.Expanded(child: _labelValue('Echeance', _formatDate(invoice.dueDate))),
        pw.Expanded(child: _labelValue('Statut', _statusLabel(invoice.status))),
      ],
    );
  }

  static pw.Widget _amountsBlock(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _amountRow('Montant total', invoice.totalAmount, bold: true),
          _amountRow('Montant paye', invoice.paidAmount, color: PdfColors.green700),
          pw.Divider(color: PdfColors.grey300),
          _amountRow(
            'Montant restant',
            invoice.remainingAmount,
            color: invoice.remainingAmount > 0 ? PdfColors.red700 : PdfColors.green700,
            bold: true,
          ),
        ],
      ),
    );
  }

  static pw.Widget _paymentsTable(List<PaymentModel> payments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Historique des paiements',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Date', header: true),
                _tableCell('Montant', header: true),
                _tableCell('Note', header: true),
              ],
            ),
            ...payments.map(
              (p) => pw.TableRow(children: [
                _tableCell(_formatDate(p.paidAt)),
                _tableCell(CurrencyFormatter.format(p.amount)),
                _tableCell(p.note),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      children: [
        pw.Divider(color: _labelColor),
        pw.SizedBox(height: 4),
        pw.Text(
          'Document genere par PayRappel',
          style: pw.TextStyle(fontSize: 9, color: _labelColor),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, color: _labelColor)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _labelColor)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _amountRow(String label, double amount, {PdfColor? color, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, color: _labelColor)),
          pw.Text(
            CurrencyFormatter.format(amount),
            style: pw.TextStyle(
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _statusLabel(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'Payee';
      case InvoiceStatus.partial:
        return 'Partielle';
      case InvoiceStatus.late:
        return 'En retard';
      case InvoiceStatus.draft:
        return 'En cours';
    }
  }
}
