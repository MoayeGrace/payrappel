import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/utils/currency_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/payment_model.dart';

class ReportPdfService {
  static const _blue = PdfColor.fromInt(0xFF1A73E8);
  static const _teal = PdfColor.fromInt(0xFF00BFA5);
  static const _green = PdfColor.fromInt(0xFF43A047);
  static const _red = PdfColor.fromInt(0xFFE53935);
  static const _orange = PdfColor.fromInt(0xFFF57C00);
  static const _grey = PdfColor.fromInt(0xFF757575);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const _dark = PdfColor.fromInt(0xFF202124);
  static const _divider = PdfColor.fromInt(0xFFE0E0E0);

  static Future<Uint8List> generate({
    required List<InvoiceModel> invoices,
    required List<PaymentModel> payments,
    required List clients,
    required BusinessProfileModel profile,
    required DateTime from,
    required DateTime to,
    required bool inclInvoices,
    required bool inclPayments,
    required bool inclStats,
  }) async {
    final pdf = pw.Document();

    // Filtrer par période
    final filtInvoices = invoices
        .where((i) =>
            !i.createdAt.isBefore(from) &&
            !i.createdAt.isAfter(to))
        .toList();
    final filtPayments = payments
        .where((p) =>
            !p.paidAt.isBefore(from) && !p.paidAt.isAfter(to))
        .toList();

    final totalInvoiced =
        filtInvoices.fold(0.0, (s, i) => s + i.totalAmount);
    final totalPaid =
        filtPayments.fold(0.0, (s, p) => s + p.amount);
    final totalPending =
        filtInvoices.fold(0.0, (s, i) => s + i.remainingAmount);
    final lateInvoices =
        filtInvoices.where((i) => i.status == InvoiceStatus.late).length;
    final recoveryRate =
        totalInvoiced > 0 ? (totalPaid / totalInvoiced * 100) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        header: (ctx) => _buildPageHeader(profile, from, to),
        footer: (ctx) => _buildPageFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          if (inclStats) ...[
            _sectionTitle('RÉSUMÉ DE LA PÉRIODE'),
            pw.SizedBox(height: 10),
            _buildStatsRow(
              totalInvoiced: totalInvoiced,
              totalPaid: totalPaid,
              totalPending: totalPending,
              lateCount: lateInvoices,
              recoveryRate: recoveryRate,
            ),
            pw.SizedBox(height: 20),
          ],
          if (inclInvoices && filtInvoices.isNotEmpty) ...[
            _sectionTitle('FACTURES (${filtInvoices.length})'),
            pw.SizedBox(height: 10),
            _buildInvoicesTable(filtInvoices),
            pw.SizedBox(height: 20),
          ],
          if (inclPayments && filtPayments.isNotEmpty) ...[
            _sectionTitle('PAIEMENTS REÇUS (${filtPayments.length})'),
            pw.SizedBox(height: 10),
            _buildPaymentsTable(filtPayments),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPageHeader(
      BusinessProfileModel profile, DateTime from, DateTime to) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _divider, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                profile.companyName.isNotEmpty
                    ? profile.companyName
                    : 'PayRappel',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _blue,
                ),
              ),
              if (profile.phone.isNotEmpty)
                pw.Text(profile.phone,
                    style: const pw.TextStyle(fontSize: 8, color: _grey)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _blue,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'RAPPORT D\'ACTIVITÉ',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Période : ${_fmt(from)} — ${_fmt(to)}',
                style: const pw.TextStyle(fontSize: 8, color: _grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: _divider, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Document généré par PayRappel',
              style: const pw.TextStyle(fontSize: 7, color: _grey)),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _grey)),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static pw.Widget _buildStatsRow({
    required double totalInvoiced,
    required double totalPaid,
    required double totalPending,
    required int lateCount,
    required double recoveryRate,
  }) {
    return pw.Row(
      children: [
        _statBox('Total facturé', CurrencyFormatter.format(totalInvoiced),
            _blue),
        pw.SizedBox(width: 8),
        _statBox('Encaissé', CurrencyFormatter.format(totalPaid), _green),
        pw.SizedBox(width: 8),
        _statBox('Reste à encaisser', CurrencyFormatter.format(totalPending),
            _orange),
        pw.SizedBox(width: 8),
        _statBox('Taux recouvrement',
            '${recoveryRate.toStringAsFixed(1)} %', _teal),
      ],
    );
  }

  static pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _divider, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: _grey),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildInvoicesTable(List<InvoiceModel> invoices) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _lightGrey),
          children: [
            _th('Facture'),
            _th('Client'),
            _th('Total'),
            _th('Payé'),
            _th('Statut'),
          ],
        ),
        ...invoices.map((inv) => pw.TableRow(
              children: [
                _td(inv.title),
                _td(inv.clientName),
                _td(CurrencyFormatter.format(inv.totalAmount)),
                _td(CurrencyFormatter.format(inv.paidAmount)),
                _tdColored(_statusLabel(inv.status),
                    _statusColor(inv.status)),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildPaymentsTable(List<PaymentModel> payments) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _lightGrey),
          children: [
            _th('Date'),
            _th('Facture'),
            _th('Montant'),
            _th('Note'),
          ],
        ),
        ...payments.map((p) => pw.TableRow(
              children: [
                _td(_fmt(p.paidAt)),
                _td(p.invoiceTitle),
                _tdColored(CurrencyFormatter.format(p.amount), _green),
                _td(p.note),
              ],
            )),
      ],
    );
  }

  static pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _dark)),
      );

  static pw.Widget _td(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 8, color: _dark)),
      );

  static pw.Widget _tdColored(String text, PdfColor color) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      );

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _statusLabel(InvoiceStatus s) => switch (s) {
        InvoiceStatus.paid => 'Payée',
        InvoiceStatus.partial => 'Partielle',
        InvoiceStatus.late => 'En retard',
        InvoiceStatus.draft => 'En cours',
      };

  static PdfColor _statusColor(InvoiceStatus s) => switch (s) {
        InvoiceStatus.paid => _green,
        InvoiceStatus.partial => _orange,
        InvoiceStatus.late => _red,
        InvoiceStatus.draft => _blue,
      };
}
