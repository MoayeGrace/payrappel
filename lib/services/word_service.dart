import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/payment_model.dart';

/// Génère un fichier .doc (HTML encodé) lisible par Microsoft Word / LibreOffice.
class WordService {
  static Future<void> shareWord({
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    required BusinessProfileModel profile,
    String? clientPhone,
    String? clientEmail,
  }) async {
    final html = _buildHtml(
      invoice: invoice,
      payments: payments,
      profile: profile,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
    );

    final dir = await getTemporaryDirectory();
    final filename = 'facture_${invoice.title.replaceAll(RegExp(r'[^\w]'), '_')}.doc';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(html, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/msword')],
      subject: 'Facture : ${invoice.title}',
    );
  }

  static String _buildHtml({
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    required BusinessProfileModel profile,
    String? clientPhone,
    String? clientEmail,
  }) {
    const accentHex = '#1A73E8';
    final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
    final remaining = invoice.totalAmount - totalPaid;

    String paymentRows = '';
    for (final p in payments) {
      paymentRows += '''
        <tr>
          <td>${DateFormatter.format(p.paidAt)}</td>
          <td>${CurrencyFormatter.format(p.amount)}</td>
          <td>${p.note.isNotEmpty ? p.note : '—'}</td>
        </tr>''';
    }

    final paymentSection = payments.isEmpty ? '' : '''
      <h3 style="color:$accentHex;margin-top:24px;">Paiements reçus</h3>
      <table>
        <thead>
          <tr><th>Date</th><th>Montant</th><th>Note</th></tr>
        </thead>
        <tbody>$paymentRows</tbody>
      </table>''';

    String cfRows = '';
    for (final cf in invoice.customFields) {
      final label = cf['label'] ?? '';
      final value = cf['value'] ?? '';
      if (label.isNotEmpty) cfRows += '<tr><td><b>$label</b></td><td>$value</td></tr>';
    }

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="ProgId" content="Word.Document">
  <title>Facture ${invoice.title}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; color: #333; font-size: 11pt; }
    .header { display: table; width: 100%; margin-bottom: 28px; }
    .company { display: table-cell; vertical-align: top; }
    .doc-title { display: table-cell; text-align: right; vertical-align: top; }
    .doc-title h1 { color: $accentHex; font-size: 26pt; margin: 0; letter-spacing: 2px; }
    .doc-title p  { margin: 2px 0; font-size: 10pt; color: #666; }
    h2 { font-size: 14pt; font-weight: bold; margin: 0 0 4px; }
    .company p { margin: 2px 0; font-size: 10pt; color: #555; }
    .divider { border: none; border-top: 2px solid $accentHex; margin: 18px 0; }
    .info-row { display: table; width: 100%; margin-bottom: 18px; }
    .info-cell { display: table-cell; width: 50%; vertical-align: top; }
    .label { font-size: 8pt; text-transform: uppercase; color: #888; margin: 0; }
    .value { font-size: 11pt; font-weight: bold; color: #222; margin: 2px 0 10px; }
    table { width: 100%; border-collapse: collapse; margin-top: 8px; }
    th { background: $accentHex; color: white; padding: 8px 10px; text-align: left; font-size: 10pt; }
    td { padding: 8px 10px; border-bottom: 1px solid #eee; font-size: 10pt; }
    tr:nth-child(even) td { background: #f7f9ff; }
    .totals { margin-top: 20px; text-align: right; }
    .totals table { width: auto; float: right; }
    .totals td { border: none; padding: 4px 10px; }
    .total-row td { font-weight: bold; font-size: 13pt; color: $accentHex; border-top: 2px solid $accentHex; }
    .remaining-row td { font-weight: bold; color: #E53935; }
    h3 { color: $accentHex; font-size: 12pt; }
  </style>
</head>
<body>

  <div class="header">
    <div class="company">
      <h2>${_esc(profile.companyName)}</h2>
      ${profile.phone.isNotEmpty ? '<p>📞 ${_esc(profile.phone)}</p>' : ''}
      ${profile.email.isNotEmpty ? '<p>✉ ${_esc(profile.email)}</p>' : ''}
      ${profile.address.isNotEmpty ? '<p>📍 ${_esc(profile.address)}</p>' : ''}
      ${profile.rccm.isNotEmpty ? '<p>RCCM : ${_esc(profile.rccm)}</p>' : ''}
    </div>
    <div class="doc-title">
      <h1>FACTURE</h1>
      <p>#${_esc(invoice.id.substring(0, 8).toUpperCase())}</p>
      <p>Date : ${DateFormatter.format(invoice.createdAt)}</p>
      <p>Échéance : ${DateFormatter.format(invoice.dueDate)}</p>
    </div>
  </div>

  <hr class="divider">

  <div class="info-row">
    <div class="info-cell">
      <p class="label">Facturé à</p>
      <p class="value">${_esc(invoice.clientName)}</p>
      ${clientPhone != null && clientPhone.isNotEmpty ? '<p>📞 $clientPhone</p>' : ''}
      ${clientEmail != null && clientEmail.isNotEmpty ? '<p>✉ $clientEmail</p>' : ''}
    </div>
    <div class="info-cell">
      <p class="label">Montant total</p>
      <p class="value">${CurrencyFormatter.format(invoice.totalAmount)}</p>
    </div>
  </div>

  ${cfRows.isNotEmpty ? '''
  <h3>Détails de la facture</h3>
  <table>
    <thead><tr><th>Champ</th><th>Valeur</th></tr></thead>
    <tbody>$cfRows</tbody>
  </table>''' : ''}

  $paymentSection

  <div class="totals">
    <table>
      <tr><td>Montant total :</td><td>${CurrencyFormatter.format(invoice.totalAmount)}</td></tr>
      <tr><td>Montant payé :</td><td>${CurrencyFormatter.format(totalPaid)}</td></tr>
      <tr class="remaining-row"><td>Solde restant :</td><td>${CurrencyFormatter.format(remaining < 0 ? 0 : remaining)}</td></tr>
      <tr class="total-row"><td>TOTAL :</td><td>${CurrencyFormatter.format(invoice.totalAmount)}</td></tr>
    </table>
  </div>

  ${profile.footerText.isNotEmpty ? '<p style="margin-top:40px;font-size:9pt;color:#888;text-align:center;">${_esc(profile.footerText)}</p>' : ''}

</body>
</html>''';
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
