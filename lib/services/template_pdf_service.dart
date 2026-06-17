import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/utils/currency_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/invoice_template_model.dart';
import '../data/models/payment_method_model.dart';
import '../data/models/payment_model.dart';

class TemplatePdfService {
  // ── Public entry point ────────────────────────────────────────────────────

  static Future<Uint8List> generate({
    required InvoiceTemplateModel template,
    required InvoiceModel invoice,
    required List<PaymentModel> payments,
    required BusinessProfileModel profile,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
  }) async {
    pw.MemoryImage? logoImage;
    if (template.showLogo && profile.hasLogo) {
      final f = File(profile.logoPath!);
      if (await f.exists()) {
        logoImage = pw.MemoryImage(await f.readAsBytes());
      }
    }

    // Load payment method logos
    final pmLogos = <String, pw.MemoryImage>{};
    for (final m in profile.enabledPaymentMethods) {
      final assetPath = m.type.assetPath;
      if (assetPath != null) {
        try {
          final data = await rootBundle.load(assetPath);
          pmLogos[m.id] = pw.MemoryImage(data.buffer.asUint8List());
        } catch (_) {}
      } else if (m.type == PaymentMethodType.custom && m.logoPath != null) {
        final f = File(m.logoPath!);
        if (await f.exists()) {
          pmLogos[m.id] = pw.MemoryImage(await f.readAsBytes());
        }
      }
    }

    final accent = _c(template.accentColor);
    final headerBg = template.headerBgColor != null
        ? _c(template.headerBgColor!)
        : accent;

    final ctx = _RenderCtx(
      template: template,
      invoice: invoice,
      payments: payments,
      profile: profile,
      logo: logoImage,
      clientPhone: clientPhone ?? '',
      clientEmail: clientEmail ?? '',
      clientAddress: clientAddress ?? '',
      accent: accent,
      headerBg: headerBg,
      pmLogos: pmLogos,
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        footer: (_) => _footer(ctx),
        build: (_) => switch (template.layout) {
          TemplateLayout.classic => _buildClassic(ctx),
          TemplateLayout.modern => _buildModern(ctx),
          TemplateLayout.minimal => _buildMinimal(ctx),
          TemplateLayout.bold => _buildBold(ctx),
        },
      ),
    );
    return pdf.save();
  }

  // ── Layout: Classic ───────────────────────────────────────────────────────

  static List<pw.Widget> _buildClassic(_RenderCtx c) {
    return [
      if (!c.template.topCenter.isEmpty) ...[
        _renderSection(c.template.topCenter, c, fullWidth: true),
        pw.SizedBox(height: 10),
      ],
      // ── En-tête : fond accent léger + badge + numéro de facture ──────────
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColor(c.accent.red, c.accent.green, c.accent.blue, 0.07),
          borderRadius: pw.BorderRadius.circular(6),
        ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Gauche : logo + société
              pw.Expanded(
                flex: 3,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (c.logo != null) ...[
                      pw.Container(
                        width: 52,
                        height: 52,
                        decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(8)),
                        child: pw.Image(c.logo!, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Expanded(
                      child: _renderSectionContent(c.template.topLeft, c,
                          defaultColor: _kTextDark),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              // Droite : badge titre + numéro + méta
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: pw.BoxDecoration(
                      color: c.accent,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      c.template.titleLabel,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    _invoiceNum(c),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: c.accent,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _renderSectionContent(c.template.topRight, c,
                      defaultColor: _kTextGrey),
                  ..._statusBadge(c),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _partyBox(
                title: 'ÉMETTEUR',
                name: _val(FieldSource.companyName, c),
                lines: [
                  _val(FieldSource.companyAddress, c),
                  _val(FieldSource.companyPhone, c),
                  _val(FieldSource.companyEmail, c),
                ],
                bgColor:
                    PdfColor(c.accent.red, c.accent.green, c.accent.blue, 0.08),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _partyBox(
                title: 'CLIENT',
                name: c.invoice.clientName,
                lines: [c.clientAddress, c.clientPhone, c.clientEmail],
                bgColor: const PdfColor.fromInt(0xFFF8F9FA),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(child: _infoBox(c)),
          ],
        ),
        pw.SizedBox(height: 18),
        if (c.invoice.lineItems.isNotEmpty) ...[
          _invoiceLineItemsBlock(c),
          pw.SizedBox(height: 14),
        ] else if (_showCustomTable(c)) ...[
          _customTableBlock(c),
          pw.SizedBox(height: 14),
        ],
        _amountsBlock(c),
        if (c.template.showPaymentMethods) ...[
          pw.SizedBox(height: 14),
          _paymentMethodsBlock(c),
        ],
        if (c.payments.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _paymentsTable(c),
        ],
        if (!c.template.bottomLeft.isEmpty ||
            !c.template.bottomRight.isEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (!c.template.bottomLeft.isEmpty)
                pw.Expanded(
                    child: _renderSectionContent(c.template.bottomLeft, c)),
              if (!c.template.bottomRight.isEmpty)
                pw.Expanded(
                    child: _renderSectionContent(c.template.bottomRight, c)),
            ],
          ),
        ],
    ];
  }

  // ── Layout: Modern ────────────────────────────────────────────────────────

  static List<pw.Widget> _buildModern(_RenderCtx c) {
    return [
        // Full-width colored header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: c.headerBg,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (c.logo != null) ...[
                pw.Container(
                  width: 52,
                  height: 52,
                  child: pw.Image(c.logo!, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 14),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      c.profile.companyName.isNotEmpty
                          ? c.profile.companyName
                          : 'Mon Entreprise',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (c.profile.address.isNotEmpty)
                      pw.Text(c.profile.address,
                          style: const pw.TextStyle(
                              color: PdfColor(1, 1, 1, 0.7), fontSize: 9)),
                    if (c.profile.phone.isNotEmpty)
                      pw.Text(c.profile.phone,
                          style: const pw.TextStyle(
                              color: PdfColor(1, 1, 1, 0.7), fontSize: 9)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    c.template.titleLabel,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _invoiceNum(c),
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    c.invoice.title,
                    style: const pw.TextStyle(
                        color: PdfColor(1, 1, 1, 0.7), fontSize: 11),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Échéance : ${_fmtDate(c.invoice.dueDate)}',
                    style: const pw.TextStyle(
                        color: PdfColor(1, 1, 1, 0.7), fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        // Optional topCenter section
        if (!c.template.topCenter.isEmpty) ...[
          _renderSection(c.template.topCenter, c, fullWidth: true),
          pw.SizedBox(height: 10),
        ],
        // Client + info row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _partyBox(
                title: 'CLIENT',
                name: c.invoice.clientName,
                lines: [c.clientAddress, c.clientPhone, c.clientEmail],
                bgColor: const PdfColor.fromInt(0xFFF8F9FA),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _infoBox(c)),
          ],
        ),
        pw.SizedBox(height: 16),
        if (c.invoice.lineItems.isNotEmpty) ...[
          _invoiceLineItemsBlock(c),
          pw.SizedBox(height: 14),
        ] else if (_showCustomTable(c)) ...[
          _customTableBlock(c),
          pw.SizedBox(height: 14),
        ],
        _amountsBlock(c),
        if (c.template.showPaymentMethods) ...[
          pw.SizedBox(height: 14),
          _paymentMethodsBlock(c),
        ],
        if (c.payments.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _paymentsTable(c),
        ],
    ];
  }

  // ── Layout: Minimal ───────────────────────────────────────────────────────

  static List<pw.Widget> _buildMinimal(_RenderCtx c) {
    return [
        // Header: company left, title right
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (c.logo != null) ...[
              pw.Container(
                width: 44,
                height: 44,
                child: pw.Image(c.logo!, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 10),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    c.profile.companyName.isNotEmpty
                        ? c.profile.companyName
                        : 'Mon Entreprise',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                  if (c.profile.phone.isNotEmpty)
                    pw.Text(c.profile.phone,
                        style:
                            const pw.TextStyle(fontSize: 9, color: _kTextGrey)),
                ],
              ),
            ),
            pw.Text(
              c.template.titleLabel,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: c.accent,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: c.accent, thickness: 1.5),
        pw.SizedBox(height: 12),
        // Details row: invoice info + client
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FACTURE',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _kTextGrey,
                          letterSpacing: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text(c.invoice.title,
                      style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _kTextDark)),
                  pw.SizedBox(height: 2),
                  pw.Text(_invoiceNum(c),
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: c.accent)),
                  pw.SizedBox(height: 4),
                  _miniRow('Émise', _fmtDate(c.invoice.createdAt)),
                  _miniRow('Échéance', _fmtDate(c.invoice.dueDate)),
                  _miniRow('Statut', _statusLabel(c.invoice.status)),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CLIENT',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _kTextGrey,
                          letterSpacing: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text(c.invoice.clientName,
                      style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _kTextDark)),
                  if (c.clientPhone.isNotEmpty)
                    pw.Text(c.clientPhone,
                        style: const pw.TextStyle(
                            fontSize: 9, color: _kTextGrey)),
                  if (c.clientEmail.isNotEmpty)
                    pw.Text(c.clientEmail,
                        style: const pw.TextStyle(
                            fontSize: 9, color: _kTextGrey)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: _kDivider, thickness: 0.5),
        pw.SizedBox(height: 12),
        if (c.invoice.lineItems.isNotEmpty) ...[
          _invoiceLineItemsBlock(c),
          pw.SizedBox(height: 14),
        ] else if (_showCustomTable(c)) ...[
          _customTableBlock(c),
          pw.SizedBox(height: 14),
        ],
        _amountsBlock(c),
        if (c.template.showPaymentMethods) ...[
          pw.SizedBox(height: 14),
          _paymentMethodsBlock(c),
        ],
        if (c.payments.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _paymentsTable(c),
        ],
    ];
  }

  // ── Layout: Bold ──────────────────────────────────────────────────────────

  static List<pw.Widget> _buildBold(_RenderCtx c) {
    return [
        // Bold banner
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: pw.BoxDecoration(
            color: c.headerBg,
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (c.logo != null) ...[
                pw.Container(
                  width: 52,
                  height: 52,
                  child: pw.Image(c.logo!, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 16),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (!c.template.topCenter.isEmpty)
                      ...c.template.topCenter.fields.map((f) {
                        final text = _resolveField(f, c);
                        if (text.isEmpty) return pw.SizedBox();
                        return pw.Text(
                          text,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: f.large ? 18 : 13,
                            fontWeight: f.bold
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                          ),
                        );
                      }),
                    if (c.template.topCenter.isEmpty)
                      pw.Text(
                        c.template.titleLabel,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (c.template.topCenter.isEmpty)
                    pw.Text(
                      c.invoice.title,
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _invoiceNum(c),
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Émis le ${_fmtDate(c.invoice.createdAt)}',
                    style: const pw.TextStyle(
                        color: PdfColor(1, 1, 1, 0.7), fontSize: 9),
                  ),
                  pw.Text(
                    'Éch. ${_fmtDate(c.invoice.dueDate)}',
                    style: const pw.TextStyle(
                        color: PdfColor(1, 1, 1, 0.7), fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          height: 4,
          color: PdfColor(
              c.accent.red, c.accent.green, c.accent.blue, 0.4),
        ),
        pw.SizedBox(height: 14),
        // Company + client row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _partyBox(
                title: 'ÉMETTEUR',
                name: c.profile.companyName.isNotEmpty
                    ? c.profile.companyName
                    : 'Mon Entreprise',
                lines: [
                  c.profile.address,
                  c.profile.phone,
                  c.profile.email,
                ],
                bgColor: PdfColor(
                    c.accent.red, c.accent.green, c.accent.blue, 0.08),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _partyBox(
                title: 'CLIENT',
                name: c.invoice.clientName,
                lines: [c.clientAddress, c.clientPhone, c.clientEmail],
                bgColor: const PdfColor.fromInt(0xFFF8F9FA),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        if (c.invoice.lineItems.isNotEmpty) ...[
          _invoiceLineItemsBlock(c),
          pw.SizedBox(height: 14),
        ] else if (_showCustomTable(c)) ...[
          _customTableBlock(c),
          pw.SizedBox(height: 14),
        ],
        _amountsBlock(c),
        if (c.template.showPaymentMethods) ...[
          pw.SizedBox(height: 14),
          _paymentMethodsBlock(c),
        ],
        if (c.payments.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _paymentsTable(c),
        ],
    ];
  }

  // ── Shared building blocks ─────────────────────────────────────────────────

  static List<pw.Widget> _statusBadge(_RenderCtx c) {
    final statusColor = _invoiceStatusColor(c.invoice.status);
    return [
      pw.SizedBox(height: 6),
      pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: PdfColor(
              statusColor.red, statusColor.green, statusColor.blue, 0.12),
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: statusColor, width: 0.5),
        ),
        child: pw.Text(
          _statusLabel(c.invoice.status),
          style: pw.TextStyle(
              color: statusColor,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold),
        ),
      ),
    ];
  }

  static pw.Widget _renderSection(
    TemplateSectionModel section,
    _RenderCtx c, {
    bool fullWidth = false,
  }) {
    final align = section.alignment == 'center'
        ? pw.CrossAxisAlignment.center
        : section.alignment == 'right'
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start;
    final bgColor =
        section.backgroundColor != null ? _c(section.backgroundColor!) : null;
    final onBg = bgColor != null && _isDark(bgColor) ? PdfColors.white : null;
    final col = pw.Column(
      crossAxisAlignment: align,
      children: section.fields.map((f) {
        final text = _resolveField(f, c);
        if (text.isEmpty) return pw.SizedBox();
        final label = f.label;
        final fgColor =
            f.textColor != null ? _c(f.textColor!) : (onBg ?? _kTextDark);
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1),
          child: label != null
              ? pw.Row(
                  children: [
                    pw.Text('$label : ',
                        style: pw.TextStyle(
                            fontSize: 9, color: onBg ?? _kTextGrey)),
                    pw.Text(text,
                        style: pw.TextStyle(
                          fontSize: f.large ? 13 : 9,
                          fontWeight: f.bold
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                          color: fgColor,
                        )),
                  ],
                )
              : pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: f.large ? 14 : 9,
                    fontWeight:
                        f.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: fgColor,
                  ),
                ),
        );
      }).toList(),
    );
    if (bgColor != null) {
      return pw.Container(
        width: fullWidth ? double.infinity : null,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: col,
      );
    }
    return fullWidth ? pw.SizedBox(width: double.infinity, child: col) : col;
  }

  static pw.Widget _renderSectionContent(
    TemplateSectionModel section,
    _RenderCtx c, {
    PdfColor defaultColor = _kTextGrey,
  }) {
    final align = section.alignment == 'center'
        ? pw.CrossAxisAlignment.center
        : section.alignment == 'right'
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start;
    return pw.Column(
      crossAxisAlignment: align,
      children: section.fields.map((f) {
        final text = _resolveField(f, c);
        if (text.isEmpty) return pw.SizedBox();
        final label = f.label;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: label != null
              ? pw.Row(
                  children: [
                    pw.Text('$label : ',
                        style: const pw.TextStyle(fontSize: 9, color: _kTextGrey)),
                    pw.Text(text,
                        style: pw.TextStyle(
                          fontSize: f.large ? 13 : 9,
                          fontWeight: f.bold
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                          color: f.textColor != null
                              ? _c(f.textColor!)
                              : defaultColor,
                        )),
                  ],
                )
              : pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: f.large ? 14 : 9,
                    fontWeight:
                        f.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: f.textColor != null
                        ? _c(f.textColor!)
                        : defaultColor,
                  ),
                ),
        );
      }).toList(),
    );
  }

  static pw.Widget _partyBox({
    required String title,
    required String name,
    required List<String> lines,
    required PdfColor bgColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _kTextGrey,
                  letterSpacing: 1)),
          pw.SizedBox(height: 4),
          pw.Text(name,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _kTextDark)),
          ...lines
              .where((l) => l.isNotEmpty)
              .map((l) => pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(l,
                        style: const pw.TextStyle(
                            fontSize: 9, color: _kTextGrey)),
                  )),
        ],
      ),
    );
  }

  static pw.Widget _infoBox(_RenderCtx c) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8F9FA),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('FACTURE',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _kTextGrey,
                  letterSpacing: 1)),
          pw.SizedBox(height: 4),
          pw.Text(c.invoice.title,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _kTextDark)),
          pw.SizedBox(height: 3),
          pw.Text(_invoiceNum(c),
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: c.accent)),
          pw.SizedBox(height: 3),
          _miniRow('Émise', _fmtDate(c.invoice.createdAt)),
          _miniRow('Échéance', _fmtDate(c.invoice.dueDate)),
        ],
      ),
    );
  }

  static pw.Widget _invoiceLineItemsBlock(_RenderCtx c) {
    final items = c.invoice.lineItems;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PRESTATIONS',
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _kTextGrey,
                letterSpacing: 1)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _kDivider, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: c.accent),
              children: ['Désignation', 'Qté', 'PU (${CurrencyFormatter.symbol})', 'Total (${CurrencyFormatter.symbol})']
                  .map((h) => _tCell(h, header: true, textColor: PdfColors.white))
                  .toList(),
            ),
            ...items.map((item) {
              final qty = (item['qty'] as num? ?? 1).toInt();
              final pu = (item['unitPrice'] as num? ?? 0).toDouble();
              final total = qty * pu;
              return pw.TableRow(children: [
                _tCell(item['description'] as String? ?? ''),
                _tCell('$qty'),
                _tCell(CurrencyFormatter.format(pu)),
                _tCell(CurrencyFormatter.format(total)),
              ]);
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _customTableBlock(_RenderCtx c) {
    final table = c.template.customTable;
    final colWidths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < table.columnCount; i++) i: const pw.FlexColumnWidth(1),
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PRESTATIONS',
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _kTextGrey,
                letterSpacing: 1)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _kDivider, width: 0.5),
          columnWidths: colWidths,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: c.accent),
              children: table.headers
                  .map((h) => _tCell(h, header: true, textColor: PdfColors.white))
                  .toList(),
            ),
            ...table.rows.map((row) => pw.TableRow(
                  children: row.map((cell) => _tCell(cell)).toList(),
                )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _amountsBlock(_RenderCtx c) {
    final inv = c.invoice;

    if (inv.lineItems.isNotEmpty) {
      return pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 230,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kDivider, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _amountRow('Sous-total',
                  CurrencyFormatter.format(inv.subtotal), _kTextDark),
              if (inv.discountAmount > 0) ...[
                pw.SizedBox(height: 4),
                _amountRow('Réduction',
                    '- ${CurrencyFormatter.format(inv.discountAmount)}',
                    _kRed),
              ],
              pw.SizedBox(height: 6),
              pw.Divider(color: _kDivider, thickness: 0.5),
              pw.SizedBox(height: 4),
              _amountRow('Total TTC',
                  CurrencyFormatter.format(inv.totalAmount), _kTextDark,
                  bold: true, large: true),
              if (inv.paidAmount > 0) ...[
                pw.SizedBox(height: 6),
                pw.Divider(color: _kDivider, thickness: 0.5),
                pw.SizedBox(height: 4),
                _amountRow('Montant payé',
                    CurrencyFormatter.format(inv.paidAmount), _kGreen),
                pw.SizedBox(height: 4),
                _amountRow(
                  inv.isFullyPaid ? 'Soldé' : 'Reste à payer',
                  CurrencyFormatter.format(inv.remainingAmount),
                  inv.isFullyPaid ? _kGreen : _kRed,
                  bold: true,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kDivider, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
              child: _amountTile('Montant total TTC',
                  CurrencyFormatter.format(inv.totalAmount), _kTextDark)),
          _vDivider(),
          pw.Expanded(
              child: _amountTile('Montant payé',
                  CurrencyFormatter.format(inv.paidAmount), _kGreen)),
          _vDivider(),
          pw.Expanded(
              child: _amountTile(
                inv.isFullyPaid ? 'Soldé' : 'Reste à payer',
                CurrencyFormatter.format(inv.remainingAmount),
                inv.isFullyPaid ? _kGreen : _kRed,
                large: true,
              )),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(String label, String value, PdfColor color,
      {bool bold = false, bool large = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: _kTextGrey)),
        pw.Text(value,
            style: pw.TextStyle(
              fontSize: large ? 12 : 9,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            )),
      ],
    );
  }

  static pw.Widget _amountTile(
      String label, String value, PdfColor color,
      {bool large = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: _kTextGrey),
            textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 3),
        pw.Text(value,
            style: pw.TextStyle(
              fontSize: large ? 13 : 11,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center),
      ],
    );
  }

  static pw.Widget _vDivider() => pw.Container(
        width: 0.5,
        height: 36,
        color: _kDivider,
        margin: const pw.EdgeInsets.symmetric(horizontal: 6),
      );

  static pw.Widget _paymentsTable(_RenderCtx c) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('HISTORIQUE DES PAIEMENTS',
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _kTextGrey,
                letterSpacing: 1)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _kDivider, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(2.5),
            2: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F3F4)),
              children: [
                _tCell('Date', header: true),
                _tCell('Montant', header: true),
                _tCell('Note', header: true),
              ],
            ),
            ...c.payments.map((p) => pw.TableRow(children: [
                  _tCell(_fmtDate(p.paidAt)),
                  _tCell(CurrencyFormatter.format(p.amount)),
                  _tCell(p.note),
                ])),
          ],
        ),
      ],
    );
  }

  static pw.Widget _paymentMethodsBlock(_RenderCtx c) {
    final methods = _getPaymentMethods(c.template, c.profile);
    if (methods.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('MOYENS DE PAIEMENT ACCEPTÉS',
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _kTextGrey,
                letterSpacing: 1)),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 8,
          runSpacing: 6,
          children: methods.map((m) {
            final color = _c(m.type.color.value);
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColor(color.red, color.green, color.blue, 0.08),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                    color: PdfColor(color.red, color.green, color.blue, 0.3),
                    width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      if (c.pmLogos.containsKey(m.id)) ...[
                        pw.Container(
                          width: 16,
                          height: 16,
                          child: pw.Image(c.pmLogos[m.id]!,
                              fit: pw.BoxFit.contain),
                        ),
                        pw.SizedBox(width: 4),
                      ],
                      pw.Text(m.label,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: color)),
                    ],
                  ),
                  ...m.fields.entries
                      .where((e) => e.value.isNotEmpty)
                      .map((e) => pw.Text(e.value,
                          style: const pw.TextStyle(
                              fontSize: 8, color: _kTextGrey))),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _footer(_RenderCtx c) {
    final section = c.template.bottomCenter;
    final profile = c.profile;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: _kDivider, thickness: 0.5),
        pw.SizedBox(height: 4),
        if (!section.isEmpty)
          ...section.fields.map((f) {
            final text = _resolveField(f, c);
            if (text.isEmpty) return pw.SizedBox();
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                text,
                style: const pw.TextStyle(fontSize: 9, color: _kTextGrey),
                textAlign: pw.TextAlign.center,
              ),
            );
          })
        else if (profile.footerText.isNotEmpty)
          pw.Text(profile.footerText,
              style: const pw.TextStyle(fontSize: 9, color: _kTextGrey),
              textAlign: pw.TextAlign.center),
        pw.Text(
          'Document généré par PayRappel',
          style: const pw.TextStyle(
              fontSize: 8, color: PdfColor.fromInt(0xFFBDC1C6)),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ── Field resolver ────────────────────────────────────────────────────────

  static String _resolveField(TemplateFieldConfig field, _RenderCtx c) {
    switch (field.source) {
      case FieldSource.companyName:
        return c.profile.companyName;
      case FieldSource.companyAddress:
        return c.profile.address;
      case FieldSource.companyPhone:
        return c.profile.phone;
      case FieldSource.companyEmail:
        return c.profile.email;
      case FieldSource.companyRccm:
        return c.profile.rccm.isNotEmpty ? 'RCCM: ${c.profile.rccm}' : '';
      case FieldSource.clientName:
        return c.invoice.clientName;
      case FieldSource.clientAddress:
        return c.clientAddress;
      case FieldSource.clientPhone:
        return c.clientPhone;
      case FieldSource.clientEmail:
        return c.clientEmail;
      case FieldSource.invoiceTitle:
        return c.invoice.title;
      case FieldSource.invoiceDate:
        return _fmtDate(c.invoice.createdAt);
      case FieldSource.invoiceDueDate:
        return _fmtDate(c.invoice.dueDate);
      case FieldSource.invoiceStatus:
        return _statusLabel(c.invoice.status);
      case FieldSource.bankInfo:
        final parts = [
          if (c.profile.bankName.isNotEmpty) c.profile.bankName,
          if (c.profile.bankAccount.isNotEmpty) c.profile.bankAccount,
        ];
        return parts.join(' — ');
      case FieldSource.invoiceNumber:
        return _invoiceNum(c);
      case FieldSource.manual:
        return field.manualValue ?? '';
    }
  }

  static bool _isDark(PdfColor color) {
    final r = color.red, g = color.green, b = color.blue;
    final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    return luminance < 0.5;
  }

  static bool _showCustomTable(_RenderCtx c) =>
      (c.invoice.globalPrice == null || c.invoice.globalPrice! <= 0) &&
      c.template.customTable.rowCount > 0;

  static String _invoiceNum(_RenderCtx c) =>
      'N° FAC-${c.invoice.createdAt.year}-${c.invoice.id.substring(0, 6).toUpperCase()}';

  static String _val(FieldSource source, _RenderCtx c) =>
      _resolveField(TemplateFieldConfig(source: source), c);

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<PaymentMethodModel> _getPaymentMethods(
      InvoiceTemplateModel template, BusinessProfileModel profile) {
    final enabled = profile.enabledPaymentMethods;
    if (template.selectedPaymentMethodIds.isEmpty) return enabled;
    return enabled
        .where((m) => template.selectedPaymentMethodIds.contains(m.id))
        .toList();
  }

  static pw.Widget _tCell(String text,
          {bool header = false, PdfColor? textColor}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? (header ? _kTextDark : _kTextGrey),
            )),
      );

  static pw.Widget _miniRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Row(children: [
          pw.Text('$label : ',
              style: const pw.TextStyle(fontSize: 9, color: _kTextGrey)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ]),
      );

  static PdfColor _c(int argb) {
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return PdfColor(r, g, b);
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
        InvoiceStatus.paid => _kGreen,
        InvoiceStatus.partial => _kOrange,
        InvoiceStatus.late => _kRed,
        InvoiceStatus.draft => const PdfColor.fromInt(0xFF1A73E8),
      };

  // ── Constants ─────────────────────────────────────────────────────────────
  static const _kTextDark = PdfColor.fromInt(0xFF202124);
  static const _kTextGrey = PdfColor.fromInt(0xFF5F6368);
  static const _kDivider = PdfColor.fromInt(0xFFE8EAED);
  static const _kGreen = PdfColor.fromInt(0xFF34A853);
  static const _kRed = PdfColor.fromInt(0xFFEA4335);
  static const _kOrange = PdfColor.fromInt(0xFFF9AB00);
}

// ── Render context (groups all parameters) ────────────────────────────────────

class _RenderCtx {
  final InvoiceTemplateModel template;
  final InvoiceModel invoice;
  final List<PaymentModel> payments;
  final BusinessProfileModel profile;
  final pw.MemoryImage? logo;
  final String clientPhone;
  final String clientEmail;
  final String clientAddress;
  final PdfColor accent;
  final PdfColor headerBg;
  final Map<String, pw.MemoryImage> pmLogos;

  _RenderCtx({
    required this.template,
    required this.invoice,
    required this.payments,
    required this.profile,
    this.logo,
    required this.clientPhone,
    required this.clientEmail,
    required this.clientAddress,
    required this.accent,
    required this.headerBg,
    this.pmLogos = const {},
  });
}
