import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/invoice_template_model.dart';
import '../data/models/payment_model.dart';

/// Génère un fichier .doc (HTML encodé) lisible par Microsoft Word / LibreOffice.
/// La mise en page correspond au template sélectionné (en-tête colorée, tableau).
class WordService {
  static Future<void> shareWord({
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    required BusinessProfileModel profile,
    required InvoiceTemplateModel template,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
  }) async {
    final html = _buildHtml(
      invoice: invoice,
      payments: payments,
      profile: profile,
      template: template,
      clientPhone: clientPhone ?? '',
      clientEmail: clientEmail ?? '',
      clientAddress: clientAddress ?? '',
    );

    final dir = await getTemporaryDirectory();
    final filename =
        'facture_${invoice.title.replaceAll(RegExp(r'[^\w]'), '_')}.doc';
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
    required InvoiceTemplateModel template,
    required String clientPhone,
    required String clientEmail,
    required String clientAddress,
  }) {
    final accentHex = _hex(template.accentColor);
    final headerHex = template.headerBgColor != null
        ? _hex(template.headerBgColor!)
        : accentHex;
    final onHeader = _isLight(template.headerBgColor ?? template.accentColor)
        ? '#222222'
        : '#FFFFFF';
    final onHeaderMuted =
        _isLight(template.headerBgColor ?? template.accentColor)
            ? '#555555'
            : '#CCCCCC';
    // Classic : fond très légèrement teinté (7 % accent sur blanc)
    final accentLightHex = _blendOnWhiteHex(template.accentColor, 0.07);

    final invoiceNum =
        'N° FAC-${invoice.createdAt.year}-${invoice.id.substring(0, 6).toUpperCase()}';

    // ── Lignes du tableau des prestations ──────────────────────────────────
    final StringBuffer itemRows = StringBuffer();
    if (invoice.lineItems.isNotEmpty) {
      for (var i = 0; i < invoice.lineItems.length; i++) {
        final item = invoice.lineItems[i];
        final qty = (item['qty'] as num? ?? 1).toInt();
        final pu = (item['unitPrice'] as num? ?? 0).toDouble();
        final total = qty * pu;
        final rowBg = i.isOdd ? ' bgcolor="#f7f9ff"' : '';
        itemRows.write('''
      <tr$rowBg>
        <td style="padding:8px 10px;border-bottom:1px solid #eee;">${_esc(item['description'] as String? ?? '')}</td>
        <td style="padding:8px 10px;border-bottom:1px solid #eee;text-align:center;">$qty</td>
        <td style="padding:8px 10px;border-bottom:1px solid #eee;text-align:right;">${CurrencyFormatter.format(pu)}</td>
        <td style="padding:8px 10px;border-bottom:1px solid #eee;text-align:right;">${CurrencyFormatter.format(total)}</td>
      </tr>''');
      }
    }

    // ── Montants ───────────────────────────────────────────────────────────
    final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
    final remaining =
        (invoice.totalAmount - totalPaid).clamp(0.0, double.infinity);

    // ── Lignes de l'historique des paiements ───────────────────────────────
    final hasMethod = payments.any((p) => p.paymentMethodLabel.isNotEmpty);
    final methodHeaders = hasMethod
        ? '<th style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;'
              'font-weight:bold;border-bottom:1px solid #e8eaed;">Moyen</th>'
              '<th style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;'
              'font-weight:bold;border-bottom:1px solid #e8eaed;">Réf.</th>'
        : '';
    final StringBuffer payRows = StringBuffer();
    for (var i = 0; i < payments.length; i++) {
      final p = payments[i];
      final rowBg = i.isOdd ? ' bgcolor="#f7f9ff"' : '';
      final methodCells = hasMethod
          ? '<td style="padding:8px 10px;border-bottom:1px solid #eee;">'
              '${p.paymentMethodLabel.isNotEmpty ? _esc(p.paymentMethodLabel) : "—"}</td>'
              '<td style="padding:8px 10px;border-bottom:1px solid #eee;">'
              '${p.paymentReference.isNotEmpty ? _esc(p.paymentReference) : "—"}</td>'
          : '';
      payRows.write('''
      <tr$rowBg>
        <td style="padding:8px 10px;border-bottom:1px solid #eee;">${DateFormatter.format(p.paidAt)}</td>
        <td style="padding:8px 10px;border-bottom:1px solid #eee;">${CurrencyFormatter.format(p.amount)}</td>
        $methodCells
        <td style="padding:8px 10px;border-bottom:1px solid #eee;">${_esc(p.note.isNotEmpty ? p.note : '—')}</td>
      </tr>''');
    }

    final footerText = _esc(profile.footerText.isNotEmpty
        ? profile.footerText
        : 'Merci pour votre confiance.');

    // ── En-tête selon le layout ────────────────────────────────────────────
    final headerHtml = template.layout == TemplateLayout.modern
        ? '''
<table width="100%" cellpadding="0" cellspacing="0" bgcolor="$headerHex"
       style="background-color:$headerHex;">
  <tr>
    <td style="padding:18px 24px;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td style="vertical-align:top;">
            <div style="font-size:14pt;font-weight:bold;color:$onHeader;">
              ${_esc(profile.companyName)}
            </div>
            ${profile.address.isNotEmpty ? '<div style="font-size:9pt;color:$onHeaderMuted;margin-top:3px;">${_esc(profile.address)}</div>' : ''}
            ${profile.phone.isNotEmpty ? '<div style="font-size:9pt;color:$onHeaderMuted;">${_esc(profile.phone)}</div>' : ''}
            ${profile.email.isNotEmpty ? '<div style="font-size:9pt;color:$onHeaderMuted;">${_esc(profile.email)}</div>' : ''}
            ${profile.rccm.isNotEmpty ? '<div style="font-size:9pt;color:$onHeaderMuted;">${_esc(profile.rccm)}</div>' : ''}
          </td>
          <td style="vertical-align:top;text-align:right;white-space:nowrap;padding-left:20px;">
            <div style="font-size:18pt;font-weight:bold;letter-spacing:2px;color:$onHeader;">
              ${_esc(template.titleLabel)}
            </div>
            <div style="font-size:9pt;font-weight:bold;color:$onHeader;margin-top:3px;">
              $invoiceNum
            </div>
            <div style="font-size:9pt;color:$onHeaderMuted;margin-top:2px;">
              ${_esc(invoice.title)}
            </div>
            <div style="font-size:9pt;color:$onHeaderMuted;">
              Ech : ${DateFormatter.format(invoice.dueDate)}
            </div>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>'''
        : template.layout == TemplateLayout.bold
            ? '''
<table width="100%" cellpadding="0" cellspacing="0" bgcolor="$headerHex"
       style="background-color:$headerHex;">
  <tr>
    <td style="padding:20px 18px;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td width="58" style="vertical-align:middle;padding-right:14px;">
            <div style="width:44px;height:44px;border-radius:50%;
                        background:rgba(255,255,255,0.15);"></div>
          </td>
          <td style="vertical-align:middle;">
            <div style="font-size:20pt;font-weight:bold;letter-spacing:3px;color:$onHeader;">
              ${_esc(template.titleLabel.toUpperCase())}
            </div>
          </td>
          <td style="vertical-align:top;text-align:right;white-space:nowrap;padding-left:20px;">
            <div style="font-size:9pt;font-weight:bold;color:$onHeader;">
              ${_esc(invoice.title)}
            </div>
            <div style="font-size:8pt;font-weight:bold;color:$onHeader;margin-top:3px;">
              $invoiceNum
            </div>
            <div style="font-size:8pt;color:$onHeaderMuted;margin-top:3px;">
              Emis le ${DateFormatter.format(invoice.createdAt)}
            </div>
            <div style="font-size:8pt;color:$onHeaderMuted;">
              Ech. ${DateFormatter.format(invoice.dueDate)}
            </div>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<div style="height:4px;background-color:$accentHex;"></div>'''
            // Classic : boîte arrondie teinte légère
            : template.layout == TemplateLayout.classic
                ? '''
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td style="padding:20px 24px 0;">
      <table width="100%" cellpadding="12" cellspacing="0" bgcolor="$accentLightHex"
             style="background-color:$accentLightHex;border-radius:6px;">
        <tr>
          <td style="vertical-align:top;" width="60%">
            <div style="font-size:13pt;font-weight:bold;color:#202124;">
              ${_esc(profile.companyName)}
            </div>
            ${profile.address.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;margin-top:2px;">${_esc(profile.address)}</div>' : ''}
            ${profile.phone.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;">${_esc(profile.phone)}</div>' : ''}
            ${profile.email.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;">${_esc(profile.email)}</div>' : ''}
            ${profile.rccm.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;">${_esc(profile.rccm)}</div>' : ''}
          </td>
          <td style="vertical-align:top;text-align:right;" width="40%">
            <div style="display:inline-block;background-color:$accentHex;color:#FFFFFF;
                        font-size:10pt;font-weight:bold;letter-spacing:1px;
                        padding:4px 10px;border-radius:4px;">
              ${_esc(template.titleLabel)}
            </div>
            <div style="font-size:9pt;font-weight:bold;color:$accentHex;margin-top:5px;">
              $invoiceNum
            </div>
            <div style="font-size:9pt;color:#9AA0A6;margin-top:3px;">
              Emis le : ${DateFormatter.format(invoice.createdAt)}
            </div>
            <div style="font-size:9pt;color:#9AA0A6;">
              Echeance : ${DateFormatter.format(invoice.dueDate)}
            </div>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>'''
                // Minimal : texte simple + ligne colorée séparatrice
                : '''
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td style="padding:20px 24px 0;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td style="vertical-align:top;">
            <div style="font-size:15pt;font-weight:bold;color:#202124;">
              ${_esc(profile.companyName)}
            </div>
            ${profile.phone.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;margin-top:2px;">${_esc(profile.phone)}</div>' : ''}
            ${profile.email.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;">${_esc(profile.email)}</div>' : ''}
          </td>
          <td style="vertical-align:top;text-align:right;padding-left:20px;white-space:nowrap;">
            <div style="font-size:18pt;font-weight:bold;letter-spacing:2px;color:$accentHex;">
              ${_esc(template.titleLabel)}
            </div>
            <div style="font-size:9pt;font-weight:bold;color:$accentHex;margin-top:3px;">
              $invoiceNum
            </div>
            <div style="font-size:9pt;color:#9AA0A6;margin-top:2px;">
              Emis : ${DateFormatter.format(invoice.createdAt)}
            </div>
            <div style="font-size:9pt;color:#9AA0A6;">
              Ech : ${DateFormatter.format(invoice.dueDate)}
            </div>
          </td>
        </tr>
      </table>
      <div style="border-top:2px solid $accentHex;margin-top:10px;"></div>
    </td>
  </tr>
</table>''';

    return '''<!DOCTYPE html>
<html xmlns:o='urn:schemas-microsoft-com:office:office'
      xmlns:w='urn:schemas-microsoft-com:office:word'
      xmlns='http://www.w3.org/TR/REC-html40'>
<head>
  <meta charset="utf-8">
  <meta name="ProgId" content="Word.Document">
  <meta name="Generator" content="Microsoft Word">
  <meta name="Originator" content="Microsoft Word">
  <!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View><w:Zoom>100</w:Zoom></w:WordDocument></xml><![endif]-->
  <title>Facture ${_esc(invoice.title)}</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,Helvetica,sans-serif;background:#fff;color:#333;font-size:11pt}
    .page{max-width:800px;margin:0 auto;background:#fff}
    table{border-collapse:collapse}
    @media print{body{background:#fff}}
  </style>
</head>
<body>
<div class="page">

$headerHtml

<!-- ── Section client ───────────────────────────────────────────────────── -->
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td style="padding:18px 24px 0;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td width="48%" bgcolor="#f8f9fa"
              style="background-color:#f8f9fa;padding:12px 14px;vertical-align:top;">
            <div style="font-size:7pt;font-weight:bold;color:#9AA0A6;letter-spacing:1px;">
              CLIENT
            </div>
            <div style="font-size:13pt;font-weight:bold;color:#202124;margin-top:5px;">
              ${_esc(invoice.clientName)}
            </div>
            ${clientAddress.isNotEmpty ? '<div style="font-size:10pt;color:#5F6368;margin-top:3px;">${_esc(clientAddress)}</div>' : ''}
            ${clientPhone.isNotEmpty ? '<div style="font-size:10pt;color:#5F6368;margin-top:2px;">${_esc(clientPhone)}</div>' : ''}
            ${clientEmail.isNotEmpty ? '<div style="font-size:10pt;color:#5F6368;margin-top:2px;">${_esc(clientEmail)}</div>' : ''}
          </td>
          <td width="4%"></td>
          <td width="48%"></td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<!-- ── Tableau des prestations ──────────────────────────────────────────── -->
${invoice.lineItems.isNotEmpty ? '''
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td style="padding:18px 24px 0;">
      <table width="100%" cellpadding="0" cellspacing="0"
             style="border-collapse:collapse;border:1px solid #e8eaed;">
        <tr bgcolor="$accentHex" style="background-color:$accentHex;">
          <th style="padding:9px 10px;text-align:left;font-size:10pt;color:#FFFFFF;font-weight:bold;">
            Designation
          </th>
          <th style="padding:9px 10px;text-align:center;font-size:10pt;color:#FFFFFF;font-weight:bold;"
              width="60">Qte</th>
          <th style="padding:9px 10px;text-align:right;font-size:10pt;color:#FFFFFF;font-weight:bold;"
              width="130">PU (${CurrencyFormatter.symbol})</th>
          <th style="padding:9px 10px;text-align:right;font-size:10pt;color:#FFFFFF;font-weight:bold;"
              width="140">Total (${CurrencyFormatter.symbol})</th>
        </tr>
        ${itemRows.toString()}
      </table>
    </td>
  </tr>
</table>''' : ''}

<!-- ── Récapitulatif des montants ───────────────────────────────────────── -->
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td style="padding:16px 24px 0;">
      <table width="100%" cellpadding="0" cellspacing="0"
             style="border-collapse:collapse;border:1px solid #e8eaed;">
        <tr>
          <td width="33%" style="padding:14px 16px;text-align:center;
              border-right:1px solid #e8eaed;vertical-align:top;">
            <div style="font-size:8pt;color:#9AA0A6;">Montant total TTC</div>
            <div style="font-size:14pt;font-weight:bold;color:#202124;margin-top:5px;">
              ${CurrencyFormatter.format(invoice.totalAmount)}
            </div>
          </td>
          <td width="33%" style="padding:14px 16px;text-align:center;
              border-right:1px solid #e8eaed;vertical-align:top;">
            <div style="font-size:8pt;color:#9AA0A6;">Montant paye</div>
            <div style="font-size:14pt;font-weight:bold;color:#34A853;margin-top:5px;">
              ${CurrencyFormatter.format(totalPaid)}
            </div>
          </td>
          <td width="33%" style="padding:14px 16px;text-align:center;vertical-align:top;">
            <div style="font-size:8pt;color:#9AA0A6;">Reste a payer</div>
            <div style="font-size:14pt;font-weight:bold;color:#EA4335;margin-top:5px;">
              ${CurrencyFormatter.format(remaining)}
            </div>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>

<!-- ── Historique des paiements ─────────────────────────────────────────── -->
${payments.isNotEmpty ? '''
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td style="padding:18px 24px 0;">
      <div style="font-size:7pt;font-weight:bold;color:#9AA0A6;letter-spacing:1px;
                  margin-bottom:8px;">HISTORIQUE DES PAIEMENTS</div>
      <table width="100%" cellpadding="0" cellspacing="0"
             style="border-collapse:collapse;border:1px solid #e8eaed;">
        <tr bgcolor="#f1f3f4" style="background-color:#f1f3f4;">
          <th style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;
                     font-weight:bold;border-bottom:1px solid #e8eaed;">Date</th>
          <th style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;
                     font-weight:bold;border-bottom:1px solid #e8eaed;">Montant</th>
          $methodHeaders
          <th style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;
                     font-weight:bold;border-bottom:1px solid #e8eaed;">Note</th>
        </tr>
        ${payRows.toString()}
      </table>
    </td>
  </tr>
</table>''' : ''}

<!-- ── Pied de page ──────────────────────────────────────────────────────── -->
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td style="padding:28px 24px 20px;text-align:center;
               border-top:1px solid #e8eaed;margin-top:24px;">
      <div style="font-size:10pt;color:#9AA0A6;">$footerText</div>
      <div style="font-size:8pt;color:#BDC1C6;margin-top:5px;">
        Document genere par PayRappel
      </div>
    </td>
  </tr>
</table>

</div>
</body>
</html>''';
  }

  static String _blendOnWhiteHex(int argb, double opacity) {
    final r = (((argb >> 16) & 0xFF) * opacity + 255 * (1 - opacity)).round();
    final g = (((argb >> 8) & 0xFF) * opacity + 255 * (1 - opacity)).round();
    final b = ((argb & 0xFF) * opacity + 255 * (1 - opacity)).round();
    return '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  static String _hex(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#'
        '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  static bool _isLight(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.35;
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
