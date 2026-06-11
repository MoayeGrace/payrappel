import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../core/utils/currency_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/payment_model.dart';

class PdfService {
  static const _primary = PdfColor.fromInt(0xFF1A73E8);
  static const _primaryLight = PdfColor.fromInt(0xFFE8F0FE);
  static const _textDark = PdfColor.fromInt(0xFF202124);
  static const _textGrey = PdfColor.fromInt(0xFF5F6368);
  static const _divider = PdfColor.fromInt(0xFFE8EAED);
  static const _green = PdfColor.fromInt(0xFF34A853);
  static const _red = PdfColor.fromInt(0xFFEA4335);
  static const _orange = PdfColor.fromInt(0xFFF9AB00);

  // ── Facture PDF ──────────────────────────────────────────────────────────
  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    required BusinessProfileModel profile,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;

    if (profile.hasLogo) {
      final file = File(profile.logoPath!);
      if (await file.exists()) {
        logoImage = pw.MemoryImage(await file.readAsBytes());
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(profile, logoImage, invoice),
            pw.SizedBox(height: 24),
            pw.Divider(color: _divider, thickness: 0.5),
            pw.SizedBox(height: 20),
            _buildParties(profile, invoice, clientPhone, clientEmail, clientAddress),
            if (invoice.customFields.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildCustomFieldsBlock(invoice.customFields),
            ],
            pw.SizedBox(height: 24),
            _buildAmountsBlock(invoice),
            if (payments.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _buildPaymentsTable(payments),
            ],
            pw.Spacer(),
            _buildFooter(profile),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Reçu PDF ─────────────────────────────────────────────────────────────
  static Future<Uint8List> generateReceiptPdf({
    required PaymentModel payment,
    required InvoiceModel invoice,
    required BusinessProfileModel profile,
    String? clientPhone,
  }) async {
    final pdf = pw.Document();
    pw.MemoryImage? logoImage;

    if (profile.hasLogo) {
      final file = File(profile.logoPath!);
      if (await file.exists()) {
        logoImage = pw.MemoryImage(await file.readAsBytes());
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildReceiptHeader(profile, logoImage),
            pw.SizedBox(height: 20),
            pw.Divider(color: _divider, thickness: 0.5),
            pw.SizedBox(height: 20),
            _buildReceiptBody(payment, invoice, clientPhone),
            pw.Spacer(),
            _buildFooter(profile),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Partager / Enregistrer ────────────────────────────────────────────────
  static Future<void> sharePdf(Uint8List bytes, {required String filename}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Document PDF');
  }

  // ── Header facture ───────────────────────────────────────────────────────
  static pw.Widget _buildHeader(
    BusinessProfileModel profile,
    pw.MemoryImage? logo,
    InvoiceModel invoice,
  ) {
    final statusColor = _invoiceStatusColor(invoice.status);
    final statusText = _statusLabel(invoice.status);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo / nom entreprise
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      profile.companyName.isNotEmpty
                          ? profile.companyName
                          : 'Mon Entreprise',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    if (profile.ownerName.isNotEmpty)
                      pw.Text(
                        profile.ownerName,
                        style: const pw.TextStyle(fontSize: 10, color: _textGrey),
                      ),
                    if (profile.address.isNotEmpty)
                      pw.Text(
                        profile.address,
                        style: const pw.TextStyle(fontSize: 9, color: _textGrey),
                      ),
                    if (profile.phone.isNotEmpty)
                      pw.Text(
                        profile.phone,
                        style: const pw.TextStyle(fontSize: 9, color: _textGrey),
                      ),
                    if (profile.rccm.isNotEmpty)
                      pw.Text(
                        'RCCM/NIF : ${profile.rccm}',
                        style: const pw.TextStyle(fontSize: 9, color: _textGrey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Badge FACTURE + statut
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _primary,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'FACTURE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColor(statusColor.red, statusColor.green, statusColor.blue, 0.15),
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: statusColor, width: 0.5),
              ),
              child: pw.Text(
                statusText,
                style: pw.TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Émise le ${_fmtDate(invoice.createdAt)}',
              style: const pw.TextStyle(fontSize: 9, color: _textGrey),
            ),
            pw.Text(
              'Échéance : ${_fmtDate(invoice.dueDate)}',
              style: pw.TextStyle(
                fontSize: 9,
                color: invoice.status == InvoiceStatus.late ? _red : _textGrey,
                fontWeight: invoice.status == InvoiceStatus.late
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Header reçu ──────────────────────────────────────────────────────────
  static pw.Widget _buildReceiptHeader(
    BusinessProfileModel profile,
    pw.MemoryImage? logo,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null) ...[
          pw.Container(
            width: 56,
            height: 56,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                profile.companyName.isNotEmpty ? profile.companyName : 'Mon Entreprise',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              if (profile.phone.isNotEmpty)
                pw.Text(profile.phone,
                    style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _green,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'REÇU DE PAIEMENT',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ── Émetteur / Client ─────────────────────────────────────────────────────
  static pw.Widget _buildParties(
    BusinessProfileModel profile,
    InvoiceModel invoice,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _partyBox(
            title: 'ÉMETTEUR',
            name: profile.companyName.isNotEmpty ? profile.companyName : '—',
            lines: [
              if (profile.address.isNotEmpty) profile.address,
              if (profile.phone.isNotEmpty) profile.phone,
              if (profile.email.isNotEmpty) profile.email,
            ],
            color: _primaryLight,
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _partyBox(
            title: 'CLIENT',
            name: invoice.clientName,
            lines: [
              if (clientAddress != null && clientAddress.isNotEmpty) clientAddress,
              if (clientPhone != null && clientPhone.isNotEmpty) clientPhone,
              if (clientEmail != null && clientEmail.isNotEmpty) clientEmail,
            ],
            color: const PdfColor.fromInt(0xFFF8F9FA),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _infoBox(invoice),
        ),
      ],
    );
  }

  static pw.Widget _partyBox({
    required String title,
    required String name,
    required List<String> lines,
    required PdfColor color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _textGrey,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          ...lines.map((l) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(l,
                    style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
              )),
        ],
      ),
    );
  }

  static pw.Widget _infoBox(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8F9FA),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FACTURE',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _textGrey,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            invoice.title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 4),
          _miniRow('Émise', _fmtDate(invoice.createdAt)),
          _miniRow('Échéance', _fmtDate(invoice.dueDate)),
        ],
      ),
    );
  }

  // ── Montants ──────────────────────────────────────────────────────────────
  static pw.Widget _buildAmountsBlock(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _amountTile(
              label: 'Montant total',
              value: CurrencyFormatter.format(invoice.totalAmount),
              color: _textDark,
              large: false,
            ),
          ),
          _verticalDivider(),
          pw.Expanded(
            child: _amountTile(
              label: 'Montant payé',
              value: CurrencyFormatter.format(invoice.paidAmount),
              color: _green,
              large: false,
            ),
          ),
          _verticalDivider(),
          pw.Expanded(
            child: _amountTile(
              label: invoice.isFullyPaid ? 'Soldé' : 'Reste à payer',
              value: CurrencyFormatter.format(invoice.remainingAmount),
              color: invoice.isFullyPaid ? _green : _red,
              large: true,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountTile({
    required String label,
    required String value,
    required PdfColor color,
    required bool large,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: _textGrey),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: large ? 14 : 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _verticalDivider() {
    return pw.Container(
      width: 0.5,
      height: 40,
      color: _divider,
      margin: const pw.EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ── Historique des paiements ──────────────────────────────────────────────
  static pw.Widget _buildPaymentsTable(List<PaymentModel> payments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'HISTORIQUE DES PAIEMENTS',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _textGrey,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _divider, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(2.5),
            2: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F3F4)),
              children: [
                _tCell('Date', header: true),
                _tCell('Montant', header: true),
                _tCell('Note', header: true),
              ],
            ),
            ...payments.map(
              (p) => pw.TableRow(children: [
                _tCell(_fmtDate(p.paidAt)),
                _tCell(CurrencyFormatter.format(p.amount)),
                _tCell(p.note),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // ── Corps reçu ───────────────────────────────────────────────────────────
  static pw.Widget _buildReceiptBody(
    PaymentModel payment,
    InvoiceModel invoice,
    String? clientPhone,
  ) {
    final solde = invoice.remainingAmount - payment.amount;
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF0FFF4),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _green, width: 0.5),
          ),
          child: pw.Column(
            children: [
              _receiptRow('Client', invoice.clientName, bold: true),
              if (clientPhone != null && clientPhone.isNotEmpty)
                _receiptRow('Téléphone', clientPhone),
              pw.Divider(color: _divider),
              _receiptRow('Facture', invoice.title),
              _receiptRow('Date du paiement', _fmtDate(payment.paidAt)),
              _receiptRow(
                'Montant encaissé',
                CurrencyFormatter.format(payment.amount),
                bold: true,
                valueColor: _green,
              ),
              if (payment.note.isNotEmpty) _receiptRow('Note', payment.note),
              pw.Divider(color: _divider),
              _receiptRow(
                'Solde restant',
                CurrencyFormatter.format(solde < 0 ? 0 : solde),
                bold: true,
                valueColor: solde <= 0 ? _green : _orange,
              ),
              if (solde <= 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: _green,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'FACTURE ENTIÈREMENT RÉGLÉE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(BusinessProfileModel profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (profile.bankName.isNotEmpty || profile.bankAccount.isNotEmpty)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _primaryLight,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Coordonnées bancaires : ',
                  style: const pw.TextStyle(fontSize: 9, color: _textGrey),
                ),
                if (profile.bankName.isNotEmpty)
                  pw.Text(
                    '${profile.bankName}  ',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                if (profile.bankAccount.isNotEmpty)
                  pw.Text(
                    profile.bankAccount,
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
              ],
            ),
          ),
        pw.Divider(color: _divider, thickness: 0.5),
        pw.SizedBox(height: 4),
        if (profile.footerText.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              profile.footerText,
              style: const pw.TextStyle(fontSize: 9, color: _textGrey),
              textAlign: pw.TextAlign.center,
            ),
          ),
        pw.Text(
          'Document généré par PayRappel',
          style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFBDC1C6)),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static pw.Widget _tCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? _textDark : _textGrey,
        ),
      ),
    );
  }

  static pw.Widget _miniRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        children: [
          pw.Text('$label : ',
              style: const pw.TextStyle(fontSize: 9, color: _textGrey)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _receiptRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: _textGrey)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _statusLabel(InvoiceStatus s) => switch (s) {
        InvoiceStatus.paid => 'Payée',
        InvoiceStatus.partial => 'Partielle',
        InvoiceStatus.late => 'En retard',
        InvoiceStatus.draft => 'En cours',
      };

  static PdfColor _invoiceStatusColor(InvoiceStatus s) => switch (s) {
        InvoiceStatus.paid => _green,
        InvoiceStatus.partial => _orange,
        InvoiceStatus.late => _red,
        InvoiceStatus.draft => _primary,
      };

  static pw.Widget _buildCustomFieldsBlock(
      List<Map<String, String>> fields) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Informations complémentaires',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _textGrey,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            color: _primaryLight,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: fields
                .map(
                  (f) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Row(
                      mainAxisAlignment:
                          pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          f['label'] ?? '',
                          style: const pw.TextStyle(
                              fontSize: 9, color: _textGrey),
                        ),
                        pw.Text(
                          f['value'] ?? '',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
