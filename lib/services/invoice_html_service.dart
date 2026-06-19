import 'dart:convert';
import 'dart:io';

import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/invoice_template_model.dart';
import '../data/models/payment_model.dart';

/// Source unique de rendu HTML — utilisée par [TemplatePdfService].
class InvoiceHtmlService {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static Future<String> buildAsync({
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    required BusinessProfileModel profile,
    required InvoiceTemplateModel template,
    String clientPhone = '',
    String clientEmail = '',
    String clientAddress = '',
  }) async {
    String? logoDataUrl;
    if (profile.hasLogo) {
      try {
        final bytes = await File(profile.logoPath!).readAsBytes();
        final ext = profile.logoPath!.split('.').last.toLowerCase();
        final mime = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : 'image/png';
        logoDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      } catch (_) {}
    }
    return build(
      invoice: invoice,
      payments: payments,
      profile: profile,
      template: template,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      clientAddress: clientAddress,
      logoDataUrl: logoDataUrl,
    );
  }

  static String build({
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    required BusinessProfileModel profile,
    required InvoiceTemplateModel template,
    String clientPhone = '',
    String clientEmail = '',
    String clientAddress = '',
    String? logoDataUrl,
  }) {
    final accentHex   = _hex(template.accentColor);
    final headerHex   = _hex(template.headerBgColor ?? template.accentColor);
    final accentLight = _blendOnWhite(template.accentColor, 0.08);
    final onHeader    = _isLight(template.headerBgColor ?? template.accentColor) ? '#222222' : '#FFFFFF';
    final onHeaderMut = _isLight(template.headerBgColor ?? template.accentColor) ? '#555555' : '#CCCCCC';

    final invoiceNum = 'N° FAC-${invoice.createdAt.year}-${invoice.id.substring(0, 6).toUpperCase()}';
    final statusLabel = _statusLabel(invoice.status);
    final statusColor = _statusColor(invoice.status);

    final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
    final remaining = (invoice.totalAmount - totalPaid).clamp(0.0, double.infinity);

    // ── Sections custom du template ─────────────────────────────────────────
    String sAlign(TemplateSectionModel s, String def) =>
        s.alignment.isNotEmpty ? s.alignment : def;

    final tl = _sec(template.topLeft,     invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.topLeft,     'left'));
    final tr = _sec(template.topRight,    invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.topRight,    'right'));
    final tc = _sec(template.topCenter,   invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.topCenter,   'center'));
    final bl = _sec(template.bottomLeft,  invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.bottomLeft,  'left'));
    final br = _sec(template.bottomRight, invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.bottomRight, 'right'));
    final bc = _sec(template.bottomCenter,invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.bottomCenter,'center'));

    // Sections rendues dans l'en-tête coloré (Modern / Bold) : couleurs adaptées au fond
    final tlH = _sec(template.topLeft,   invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.topLeft,   'left'),   baseColor: onHeaderMut, boldColor: onHeader);
    final trH = _sec(template.topRight,  invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.topRight,  'right'),  baseColor: onHeaderMut, boldColor: onHeader);
    final tcH = _sec(template.topCenter, invoice, profile, clientPhone, clientEmail, clientAddress, align: sAlign(template.topCenter, 'center'), baseColor: onHeaderMut, boldColor: onHeader);

    final footerText = _e(profile.footerText.isNotEmpty ? profile.footerText : 'Merci pour votre confiance.');

    // ── Logo HTML ───────────────────────────────────────────────────────────
    final logoRound  = _logoHtml(logoDataUrl, 44, accentHex, circle: false);
    final logoCircle = _logoHtml(logoDataUrl, 44, onHeader,  circle: true);
    final logoSmall  = _logoHtml(logoDataUrl, 38, accentHex, circle: false);

    // Barre accent Bold : opacité identique à Flutter (_BoldDoc)
    // Flutter : accent.withOpacity(luminance > 0.5 ? 0.7 : 0.5)
    final accentLum    = _luminance(template.accentColor);
    final boldBarHex   = _blendOnWhite(template.accentColor, accentLum > 0.5 ? 0.7 : 0.5);

    // ── En-tête selon le layout ─────────────────────────────────────────────
    final String headerHtml;
    switch (template.layout) {
      case TemplateLayout.modern:
        headerHtml = _headerModern(
          headerHex: headerHex, onHeader: onHeader, onHeaderMut: onHeaderMut,
          accentHex: accentHex, invoiceNum: invoiceNum,
          titleLabel: template.titleLabel,
          invoice: invoice, profile: profile,
          topLeftHtml: tlH, topRightHtml: trH,
          logoHtml: logoRound,
        );
      case TemplateLayout.classic:
        headerHtml = _headerClassic(
          accentHex: accentHex, accentLight: accentLight,
          invoiceNum: invoiceNum, statusLabel: statusLabel, statusColor: statusColor,
          titleLabel: template.titleLabel,
          invoice: invoice, profile: profile,
          topLeftHtml: tl, topRightHtml: tr,
          logoHtml: logoSmall,
        );
      case TemplateLayout.minimal:
        headerHtml = _headerMinimal(
          accentHex: accentHex,
          invoiceNum: invoiceNum,
          titleLabel: template.titleLabel,
          invoice: invoice, profile: profile,
          topLeftHtml: tl, topRightHtml: tr,
          logoHtml: logoSmall,
        );
      case TemplateLayout.bold:
        headerHtml = _headerBold(
          headerHex: headerHex, onHeader: onHeader, onHeaderMut: onHeaderMut,
          accentHex: accentHex, accentBarHex: boldBarHex,
          invoiceNum: invoiceNum, titleLabel: template.titleLabel,
          invoice: invoice, profile: profile,
          topCenterHtml: tcH, topRightHtml: trH,
          logoHtml: logoCircle,
        );
    }

    // ── Ligne article ───────────────────────────────────────────────────────
    final itemsBuf = StringBuffer();
    for (var i = 0; i < invoice.lineItems.length; i++) {
      final it  = invoice.lineItems[i];
      final qty = (it['qty'] as num? ?? 1).toInt();
      final pu  = (it['unitPrice'] as num? ?? 0).toDouble();
      final tot = qty * pu;
      final bg  = i.isOdd ? ' bgcolor="#F7F9FF" style="background-color:#F7F9FF;"' : '';
      itemsBuf.write('''
        <tr$bg>
          <td style="padding:8px 10px;border-bottom:1px solid #EEEEEE;">${_e(it['description'] as String? ?? '')}</td>
          <td align="center" style="padding:8px 10px;border-bottom:1px solid #EEEEEE;text-align:center;">$qty</td>
          <td align="right" style="padding:8px 10px;border-bottom:1px solid #EEEEEE;text-align:right;">${CurrencyFormatter.format(pu)}</td>
          <td align="right" style="padding:8px 10px;border-bottom:1px solid #EEEEEE;text-align:right;">${CurrencyFormatter.format(tot)}</td>
        </tr>''');
    }

    // ── Lignes paiement ─────────────────────────────────────────────────────
    final hasMethod = payments.any((p) => p.paymentMethodLabel.isNotEmpty);
    final methodTh  = hasMethod ? '''
          <th width="100" style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;font-weight:bold;border-bottom:1px solid #E8EAED;">Moyen</th>
          <th width="120" style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;font-weight:bold;border-bottom:1px solid #E8EAED;">Réf.</th>''' : '';
    final payBuf = StringBuffer();
    for (var i = 0; i < payments.length; i++) {
      final p   = payments[i];
      final bg  = i.isOdd ? ' bgcolor="#F7F9FF" style="background-color:#F7F9FF;"' : '';
      final mCells = hasMethod ? '''
          <td style="padding:8px 10px;border-bottom:1px solid #EEEEEE;">${p.paymentMethodLabel.isNotEmpty ? _e(p.paymentMethodLabel) : '—'}</td>
          <td style="padding:8px 10px;border-bottom:1px solid #EEEEEE;">${p.paymentReference.isNotEmpty ? _e(p.paymentReference) : '—'}</td>''' : '';
      payBuf.write('''
        <tr$bg>
          <td style="padding:8px 10px;border-bottom:1px solid #EEEEEE;">${DateFormatter.format(p.paidAt)}</td>
          <td style="padding:8px 10px;border-bottom:1px solid #EEEEEE;">${CurrencyFormatter.format(p.amount)}</td>
          $mCells
          <td style="padding:8px 10px;border-bottom:1px solid #EEEEEE;">${_e(p.note.isNotEmpty ? p.note : '—')}</td>
        </tr>''');
    }

    // ── topCenter — placement par layout ────────────────────────────────────
    // • Classic : AU-DESSUS du header (dans le wrapper padding)
    // • Modern  : en-dessous du header coloré, avant la section client
    // • Bold    : centre du header coloré, géré dans _headerBold
    // • Minimal : non affiché
    final tcAlign = sAlign(template.topCenter, 'center');
    final classicPreHeader = (template.layout == TemplateLayout.classic && tc.isNotEmpty)
        ? '<div style="text-align:$tcAlign;margin-bottom:10px;">$tc</div>'
        : '';

    // ── Section client ───────────────────────────────────────────────────────
    final clientHtml = bl.isNotEmpty ? bl : '''
      <div style="font-size:7pt;font-weight:bold;color:#9AA0A6;letter-spacing:1px;margin-bottom:4px;">CLIENT</div>
      <div style="font-size:13pt;font-weight:bold;color:#202124;">${_e(invoice.clientName)}</div>
      ${clientAddress.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;margin-top:3px;">${_e(clientAddress)}</div>' : ''}
      ${clientPhone.isNotEmpty  ? '<div style="font-size:9pt;color:#5F6368;margin-top:2px;">${_e(clientPhone)}</div>'   : ''}
      ${clientEmail.isNotEmpty  ? '<div style="font-size:9pt;color:#5F6368;margin-top:2px;">${_e(clientEmail)}</div>'   : ''}''';

    final rightColHtml = br.isNotEmpty ? br : '';
    final showRightCol = br.isNotEmpty;

    // ── Tableau des articles ─────────────────────────────────────────────────
    final itemsBlock = invoice.lineItems.isNotEmpty ? '''
<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-top:18px;">
  <tr bgcolor="$accentHex" style="background-color:$accentHex;">
    <th style="padding:9px 10px;text-align:left;color:#FFFFFF;font-size:10pt;font-weight:bold;">${_e(template.customTable.headers.isNotEmpty ? template.customTable.headers[0] : 'Désignation')}</th>
    <th width="60" align="center" style="padding:9px 10px;text-align:center;color:#FFFFFF;font-size:10pt;font-weight:bold;">Qté</th>
    <th width="130" align="right" style="padding:9px 10px;text-align:right;color:#FFFFFF;font-size:10pt;font-weight:bold;">P.U (${CurrencyFormatter.symbol})</th>
    <th width="140" align="right" style="padding:9px 10px;text-align:right;color:#FFFFFF;font-size:10pt;font-weight:bold;">Total (${CurrencyFormatter.symbol})</th>
  </tr>
  ${itemsBuf.toString()}
</table>''' : '';

    // ── Récapitulatif montants ───────────────────────────────────────────────
    final amountsBlock = '''
<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-top:14px;border:1px solid #E8EAED;">
  <tr>
    <td width="33%" align="center" bgcolor="#FFFFFF" style="padding:14px 10px;text-align:center;border-right:1px solid #E8EAED;vertical-align:top;">
      <div style="font-size:8pt;color:#9AA0A6;">Montant total TTC</div>
      <div style="font-size:13pt;font-weight:bold;color:#202124;margin-top:4px;">${CurrencyFormatter.format(invoice.totalAmount)}</div>
    </td>
    <td width="33%" align="center" bgcolor="#FFFFFF" style="padding:14px 10px;text-align:center;border-right:1px solid #E8EAED;vertical-align:top;">
      <div style="font-size:8pt;color:#9AA0A6;">Montant payé</div>
      <div style="font-size:13pt;font-weight:bold;color:#34A853;margin-top:4px;">${CurrencyFormatter.format(totalPaid)}</div>
    </td>
    <td width="34%" align="center" bgcolor="#FFFFFF" style="padding:14px 10px;text-align:center;vertical-align:top;">
      <div style="font-size:8pt;color:#9AA0A6;">Reste à payer</div>
      <div style="font-size:13pt;font-weight:bold;color:#EA4335;margin-top:4px;">${CurrencyFormatter.format(remaining)}</div>
    </td>
  </tr>
</table>''';

    // ── Historique paiements ─────────────────────────────────────────────────
    final paymentsBlock = payments.isNotEmpty ? '''
<div style="font-size:7pt;font-weight:bold;color:#9AA0A6;letter-spacing:1px;margin-top:18px;margin-bottom:6px;">HISTORIQUE DES PAIEMENTS</div>
<table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border:1px solid #E8EAED;">
  <tr bgcolor="#F1F3F4" style="background-color:#F1F3F4;">
    <th style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;font-weight:bold;border-bottom:1px solid #E8EAED;">Date</th>
    <th width="140" style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;font-weight:bold;border-bottom:1px solid #E8EAED;">Montant</th>
    $methodTh
    <th style="padding:8px 10px;text-align:left;font-size:10pt;color:#5F6368;font-weight:bold;border-bottom:1px solid #E8EAED;">Note</th>
  </tr>
  ${payBuf.toString()}
</table>''' : '';

    // ── Pied de page ─────────────────────────────────────────────────────────
    final footerBlock = '''
<table width="100%" cellpadding="0" cellspacing="0" style="margin-top:24px;">
  <tr>
    <td style="border-top:1px solid #E8EAED;padding-top:16px;text-align:center;">
      ${bc.isNotEmpty ? bc : '<div style="font-size:10pt;color:#9AA0A6;">$footerText</div>'}
      <div style="font-size:8pt;color:#C8C8C8;margin-top:5px;">Document généré par PayRappel</div>
    </td>
  </tr>
</table>''';

    // ── Contenu commun (client, articles, montants, paiements, pied) ─────────
    final clientTable = '''
<table width="100%" cellpadding="0" cellspacing="0" style="margin-top:16px;">
  <tr>
    <td width="${showRightCol ? '50%' : '60%'}" bgcolor="#F8F9FA" style="background-color:#F8F9FA;padding:12px 14px;vertical-align:top;">
      $clientHtml
    </td>
    ${showRightCol ? '<td width="4%"></td><td width="46%" style="vertical-align:top;">$rightColHtml</td>' : '<td width="40%"></td>'}
  </tr>
</table>''';

    final innerContent = '$clientTable\n$itemsBlock\n$amountsBlock\n$paymentsBlock\n$footerBlock';

    // Chip de statut affiché une seule fois, au-dessus du contenu pour Modern/Bold
    final statusChipHtml = invoice.status != InvoiceStatus.draft
        ? '<div style="margin-bottom:10px;">'
          '<span style="display:inline-block;font-size:7pt;font-weight:bold;'
          'color:$statusColor;background-color:${_hexToRgba(statusColor, 0.12)};'
          'border:0.5px solid $statusColor;padding:2px 8px;border-radius:4px;">$statusLabel</span>'
          '</div>'
        : '';

    final modernInner = (tc.isNotEmpty)
        ? '<div style="text-align:$tcAlign;margin-bottom:12px;">$tc</div>\n$innerContent'
        : innerContent;

    // ── Corps par layout ──────────────────────────────────────────────────────
    // Modern/Bold : header pleine largeur HORS du conteneur max-width
    // Classic/Minimal : header à l'intérieur du wrapper avec padding
    final String pageBody;
    switch (template.layout) {
      case TemplateLayout.classic:
        pageBody = '''
<div style="max-width:820px;margin:0 auto;background:#FFFFFF;">
  <div style="padding:20px;">
    $classicPreHeader
    $headerHtml
    $innerContent
  </div>
  <div style="height:20px;"></div>
</div>''';
      case TemplateLayout.modern:
        pageBody = '''
$headerHtml
<div style="max-width:820px;margin:0 auto;background:#FFFFFF;">
  <div style="padding:16px;">
    $statusChipHtml
    $modernInner
  </div>
  <div style="height:20px;"></div>
</div>''';
      case TemplateLayout.minimal:
        pageBody = '''
<div style="max-width:820px;margin:0 auto;background:#FFFFFF;">
  <div style="padding:20px;">
    $headerHtml
    $innerContent
  </div>
  <div style="height:20px;"></div>
</div>''';
      case TemplateLayout.bold:
        pageBody = '''
$headerHtml
<div style="max-width:820px;margin:0 auto;background:#FFFFFF;">
  <div style="padding:16px;">
    $statusChipHtml
    $innerContent
  </div>
  <div style="height:20px;"></div>
</div>''';
    }

    return '''<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="utf-8">
<meta name="ProgId" content="Word.Document">
<meta name="Generator" content="Microsoft Word">
<meta name="Originator" content="Microsoft Word">
<!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View><w:Zoom>100</w:Zoom></w:WordDocument></xml><![endif]-->
<title>Facture ${_e(invoice.title)}</title>
<style>
  * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; }
  body { font-family: Arial, Helvetica, sans-serif; background: #FFFFFF; color: #333333; font-size: 11pt; margin: 0; padding: 0; }
  table { border-collapse: collapse; }
</style>
</head>
<body bgcolor="#FFFFFF">
$pageBody
</body>
</html>''';
  }

  // ---------------------------------------------------------------------------
  // Layout headers
  // ---------------------------------------------------------------------------

  static String _headerModern({
    required String headerHex,
    required String onHeader,
    required String onHeaderMut,
    required String accentHex,
    required String invoiceNum,
    required String titleLabel,
    required InvoiceModel invoice,
    required BusinessProfileModel profile,
    required String topLeftHtml,
    required String topRightHtml,
    required String logoHtml,
  }) {
    final leftContent = topLeftHtml.isNotEmpty ? topLeftHtml : '''
      <div style="font-size:14pt;font-weight:bold;color:$onHeader;">${_e(profile.companyName)}</div>
      ${profile.address.isNotEmpty ? '<div style="font-size:9pt;color:$onHeaderMut;margin-top:3px;">${_e(profile.address)}</div>' : ''}
      ${profile.phone.isNotEmpty  ? '<div style="font-size:9pt;color:$onHeaderMut;margin-top:2px;">${_e(profile.phone)}</div>'   : ''}
      ${profile.email.isNotEmpty  ? '<div style="font-size:9pt;color:$onHeaderMut;margin-top:2px;">${_e(profile.email)}</div>'   : ''}
      ${profile.rccm.isNotEmpty   ? '<div style="font-size:9pt;color:$onHeaderMut;margin-top:2px;">${_e(profile.rccm)}</div>'    : ''}''';

    final rightContent = topRightHtml.isNotEmpty ? topRightHtml : '''
      <div style="font-size:18pt;font-weight:bold;letter-spacing:2px;color:$onHeader;">${_e(titleLabel)}</div>
      <div style="font-size:9pt;font-weight:bold;color:$onHeader;margin-top:4px;">$invoiceNum</div>
      <div style="font-size:9pt;color:$onHeaderMut;margin-top:2px;">${_e(invoice.title)}</div>
      <div style="font-size:9pt;color:$onHeaderMut;">Éch. : ${DateFormatter.format(invoice.dueDate)}</div>''';

    return '''
<table width="100%" cellpadding="0" cellspacing="0" bgcolor="$headerHex" style="background-color:$headerHex;">
  <tr>
    <td style="padding:18px 24px;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td width="60%" style="vertical-align:top;">
            <table cellpadding="0" cellspacing="0">
              <tr>
                ${logoHtml.isNotEmpty ? '<td width="54" style="vertical-align:top;padding-right:10px;">$logoHtml</td>' : ''}
                <td style="vertical-align:top;">$leftContent</td>
              </tr>
            </table>
          </td>
          <td width="40%" style="vertical-align:top;text-align:right;">$rightContent</td>
        </tr>
      </table>
    </td>
  </tr>
</table>''';
  }

  static String _headerClassic({
    required String accentHex,
    required String accentLight,
    required String invoiceNum,
    required String statusLabel,
    required String statusColor,
    required String titleLabel,
    required InvoiceModel invoice,
    required BusinessProfileModel profile,
    required String topLeftHtml,
    required String topRightHtml,
    required String logoHtml,
  }) {
    final leftContent = topLeftHtml.isNotEmpty ? topLeftHtml : '''
      <div style="font-size:13pt;font-weight:bold;color:#202124;">${_e(profile.companyName)}</div>
      ${profile.address.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;margin-top:2px;">${_e(profile.address)}</div>' : ''}
      ${profile.phone.isNotEmpty  ? '<div style="font-size:9pt;color:#5F6368;margin-top:1px;">${_e(profile.phone)}</div>'   : ''}
      ${profile.email.isNotEmpty  ? '<div style="font-size:9pt;color:#5F6368;margin-top:1px;">${_e(profile.email)}</div>'   : ''}
      ${profile.rccm.isNotEmpty   ? '<div style="font-size:9pt;color:#5F6368;margin-top:1px;">${_e(profile.rccm)}</div>'    : ''}''';

    // Badge FACTURE en bloc (pas de float) pour éviter le chevauchement
    final titleBadge = '<div style="margin-bottom:5px;">'
        '<span style="display:inline-block;background-color:$accentHex;color:#FFFFFF;'
        'font-size:10pt;font-weight:bold;letter-spacing:1px;padding:5px 12px;'
        'border-radius:4px;">${_e(titleLabel)}</span>'
        '</div>';

    final rightBody = topRightHtml.isNotEmpty ? topRightHtml : '''
      <div style="font-size:8pt;font-weight:bold;color:$accentHex;margin-top:2px;">$invoiceNum</div>
      <div style="font-size:9pt;color:#9AA0A6;margin-top:3px;">Émis le : ${DateFormatter.format(invoice.createdAt)}</div>
      <div style="font-size:9pt;color:#9AA0A6;">Échéance : ${DateFormatter.format(invoice.dueDate)}</div>''';

    final statusChip = invoice.status != InvoiceStatus.draft
        ? '<div style="margin-top:5px;text-align:right;">'
          '<span style="display:inline-block;font-size:7pt;font-weight:bold;color:$statusColor;'
          'background-color:${_hexToRgba(statusColor, 0.12)};border:0.5px solid $statusColor;'
          'padding:2px 8px;border-radius:4px;">$statusLabel</span>'
          '</div>'
        : '';

    // Wrapper div pour le border-radius (overflow:hidden clip le fond coloré)
    return '''
<div style="border-radius:6px;overflow:hidden;">
<table width="100%" cellpadding="0" cellspacing="0" bgcolor="$accentLight" style="background-color:$accentLight;">
  <tr>
    <td style="padding:12px;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td width="55%" style="vertical-align:top;">
            <table cellpadding="0" cellspacing="0">
              <tr>
                ${logoHtml.isNotEmpty ? '<td width="48" style="vertical-align:top;padding-right:8px;">$logoHtml</td>' : ''}
                <td style="vertical-align:top;">$leftContent</td>
              </tr>
            </table>
          </td>
          <td width="45%" style="vertical-align:top;text-align:right;">
            $titleBadge
            $rightBody
            $statusChip
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
</div>''';
  }

  static String _headerMinimal({
    required String accentHex,
    required String invoiceNum,
    required String titleLabel,
    required InvoiceModel invoice,
    required BusinessProfileModel profile,
    required String topLeftHtml,
    required String topRightHtml,
    required String logoHtml,
  }) {
    final statusLabel = _statusLabel(invoice.status);
    final statusColor = _statusColor(invoice.status);
    final statusChip = invoice.status != InvoiceStatus.draft
        ? '<div style="margin-top:5px;text-align:right;">'
          '<span style="display:inline-block;font-size:7pt;font-weight:bold;color:$statusColor;'
          'background-color:${_hexToRgba(statusColor, 0.12)};border:0.5px solid $statusColor;'
          'padding:2px 8px;border-radius:4px;">$statusLabel</span>'
          '</div>'
        : '';

    final leftContent = topLeftHtml.isNotEmpty ? topLeftHtml : '''
      <div style="font-size:15pt;font-weight:bold;color:#202124;">${_e(profile.companyName)}</div>
      ${profile.phone.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;margin-top:3px;">${_e(profile.phone)}</div>' : ''}
      ${profile.email.isNotEmpty ? '<div style="font-size:9pt;color:#5F6368;margin-top:2px;">${_e(profile.email)}</div>' : ''}''';

    final rightContent = topRightHtml.isNotEmpty ? topRightHtml : '''
      <div style="font-size:16pt;font-weight:bold;letter-spacing:2px;color:$accentHex;">${_e(titleLabel)}</div>
      <div style="font-size:9pt;font-weight:bold;color:$accentHex;margin-top:3px;">$invoiceNum</div>
      <div style="font-size:9pt;color:#9AA0A6;margin-top:2px;">Émis : ${DateFormatter.format(invoice.createdAt)}</div>
      <div style="font-size:9pt;color:#9AA0A6;">Éch. : ${DateFormatter.format(invoice.dueDate)}</div>''';

    // Pas de padding externe — géré par le wrapper <div style="padding:20px">
    return '''
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td width="55%" style="vertical-align:top;">
      <table cellpadding="0" cellspacing="0">
        <tr>
          ${logoHtml.isNotEmpty ? '<td width="48" style="vertical-align:top;padding-right:10px;">$logoHtml</td>' : ''}
          <td style="vertical-align:top;">$leftContent</td>
        </tr>
      </table>
    </td>
    <td width="45%" style="vertical-align:top;text-align:right;">$rightContent$statusChip</td>
  </tr>
</table>
<div style="height:2px;background-color:$accentHex;margin-top:10px;margin-bottom:0;"></div>''';
  }

  static String _headerBold({
    required String headerHex,
    required String onHeader,
    required String onHeaderMut,
    required String accentHex,
    required String accentBarHex,
    required String invoiceNum,
    required String titleLabel,
    required InvoiceModel invoice,
    required BusinessProfileModel profile,
    required String topCenterHtml,
    required String topRightHtml,
    required String logoHtml,
  }) {
    final centerContent = topCenterHtml.isNotEmpty ? topCenterHtml
        : '<div style="font-size:20pt;font-weight:bold;letter-spacing:3px;color:$onHeader;text-align:center;">${_e(titleLabel.toUpperCase())}</div>';

    final rightContent = topRightHtml.isNotEmpty ? topRightHtml : '''
      <div style="font-size:9pt;font-weight:bold;color:$onHeader;">${_e(invoice.title)}</div>
      <div style="font-size:8pt;font-weight:bold;color:$onHeader;margin-top:3px;">$invoiceNum</div>
      <div style="font-size:8pt;color:$onHeaderMut;margin-top:3px;">Émis le ${DateFormatter.format(invoice.createdAt)}</div>
      <div style="font-size:8pt;color:$onHeaderMut;">Éch. ${DateFormatter.format(invoice.dueDate)}</div>''';

    final logoCell = logoHtml.isNotEmpty
        ? '<td width="62" style="padding:20px 0 20px 18px;vertical-align:middle;">$logoHtml</td>'
        : '<td width="62" style="padding:20px 0 20px 18px;vertical-align:middle;"><div style="width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,0.15);"></div></td>';

    return '''
<table width="100%" cellpadding="0" cellspacing="0" bgcolor="$headerHex" style="background-color:$headerHex;">
  <tr>
    $logoCell
    <td style="padding:20px 14px;vertical-align:middle;text-align:center;">$centerContent</td>
    <td style="padding:20px 18px 20px 14px;vertical-align:top;text-align:right;white-space:nowrap;">$rightContent</td>
  </tr>
</table>
<table width="100%" cellpadding="0" cellspacing="0">
  <tr>
    <td bgcolor="$accentBarHex" style="background-color:$accentBarHex;height:4px;font-size:0;line-height:0;">&nbsp;</td>
  </tr>
</table>''';
  }

  // ---------------------------------------------------------------------------
  // Section rendering
  // ---------------------------------------------------------------------------

  static String _sec(
    TemplateSectionModel section,
    InvoiceModel invoice,
    BusinessProfileModel profile,
    String phone,
    String email,
    String address, {
    String align = 'left',
    String baseColor = '#5F6368',
    String boldColor = '#202124',
  }) {
    if (section.isEmpty) return '';
    final buf = StringBuffer();
    for (final f in section.fields) {
      // Le statut est toujours affiché dans l'en-tête — jamais via les sections
      if (f.source == FieldSource.invoiceStatus) continue;
      final raw = _resolve(f, invoice, profile, phone, email, address);
      if (raw.isEmpty) continue;
      final labelColor = baseColor;
      final labelHtml = (f.label != null && f.label!.isNotEmpty)
          ? '<span style="color:$labelColor;font-weight:normal;">${_e(f.label!)}: </span>'
          : '';
      final String color = f.textColor != null
          ? _hex(f.textColor!)
          : (f.bold ? boldColor : baseColor);
      final weight = f.bold ? 'bold' : 'normal';
      final size   = f.large ? '13pt' : '9pt';
      buf.write('<div style="font-size:$size;font-weight:$weight;color:$color;'
          'text-align:$align;margin-bottom:2px;">$labelHtml${_e(raw)}</div>');
    }
    return buf.toString();
  }

  static String _resolve(
    TemplateFieldConfig f,
    InvoiceModel invoice,
    BusinessProfileModel profile,
    String phone,
    String email,
    String address,
  ) {
    final raw = switch (f.source) {
      FieldSource.companyName    => profile.companyName,
      FieldSource.companyAddress => profile.address,
      FieldSource.companyPhone   => profile.phone,
      FieldSource.companyEmail   => profile.email,
      FieldSource.companyRccm    => profile.rccm.isNotEmpty ? 'RCCM: ${profile.rccm}' : '',
      FieldSource.clientName     => invoice.clientName,
      FieldSource.clientAddress  => address,
      FieldSource.clientPhone    => phone,
      FieldSource.clientEmail    => email,
      FieldSource.invoiceTitle   => invoice.title,
      FieldSource.invoiceDate    => DateFormatter.format(invoice.createdAt),
      FieldSource.invoiceDueDate => DateFormatter.format(invoice.dueDate),
      FieldSource.invoiceStatus  => _statusLabel(invoice.status),
      FieldSource.bankInfo       => [
          if (profile.bankName.isNotEmpty) profile.bankName,
          if (profile.bankAccount.isNotEmpty) profile.bankAccount,
        ].join(' — '),
      FieldSource.invoiceNumber  =>
          'N° FAC-${invoice.createdAt.year}-${invoice.id.substring(0, 6).toUpperCase()}',
      FieldSource.today          => DateFormatter.format(DateTime.now()),
      FieldSource.manual         => f.manualValue ?? '',
    };
    return raw;
  }

  // ---------------------------------------------------------------------------
  // Logo helper
  // ---------------------------------------------------------------------------

  static String _logoHtml(String? dataUrl, int size, String accentHex, {bool circle = false}) {
    if (dataUrl == null || dataUrl.isEmpty) return '';
    final radius = circle ? '${size ~/ 2}px' : '6px';
    return '<img src="$dataUrl" width="$size" height="$size" '
        'style="width:${size}px;height:${size}px;border-radius:$radius;object-fit:contain;">';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _statusLabel(InvoiceStatus s) => switch (s) {
    InvoiceStatus.draft   => 'Brouillon',
    InvoiceStatus.paid    => 'Payée',
    InvoiceStatus.partial => 'Partiellement payée',
    InvoiceStatus.late    => 'En retard',
  };

  static String _statusColor(InvoiceStatus s) => switch (s) {
    InvoiceStatus.draft   => '#9AA0A6',
    InvoiceStatus.paid    => '#34A853',
    InvoiceStatus.partial => '#1A73E8',
    InvoiceStatus.late    => '#EA4335',
  };

  static String _blendOnWhite(int argb, double opacity) {
    final r = (((argb >> 16) & 0xFF) * opacity + 255 * (1 - opacity)).round();
    final g = (((argb >> 8)  & 0xFF) * opacity + 255 * (1 - opacity)).round();
    final b = (( argb        & 0xFF) * opacity + 255 * (1 - opacity)).round();
    return '#${r.toRadixString(16).padLeft(2,'0')}${g.toRadixString(16).padLeft(2,'0')}${b.toRadixString(16).padLeft(2,'0')}';
  }

  static String _hex(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8)  & 0xFF;
    final b =  argb        & 0xFF;
    return '#${r.toRadixString(16).padLeft(2,'0')}${g.toRadixString(16).padLeft(2,'0')}${b.toRadixString(16).padLeft(2,'0')}';
  }

  static double _luminance(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8)  & 0xFF) / 255.0;
    final b = ( argb        & 0xFF) / 255.0;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static bool _isLight(int argb) => _luminance(argb) > 0.35;

  static String _hexToRgba(String hex, double alpha) {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    final r = int.parse(h.substring(0, 2), radix: 16);
    final g = int.parse(h.substring(2, 4), radix: 16);
    final b = int.parse(h.substring(4, 6), radix: 16);
    return 'rgba($r,$g,$b,$alpha)';
  }

  static String _e(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
