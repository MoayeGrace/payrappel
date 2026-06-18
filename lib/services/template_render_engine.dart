import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/utils/currency_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/invoice_template_model.dart';
import '../data/models/payment_method_model.dart';
import '../data/models/payment_model.dart';

/// Moteur de rendu unifié pour Flutter et PDF
/// Une seule source de vérité pour le design
class TemplateRenderEngine {
  // ── Constantes de design partagées ────────────────────────────────────────
  
  static const double paddingMain = 20;
  static const double paddingSection = 12;
  static const double gapSection = 14;
  static const double borderRadius = 6;
  
  // Colors
  static const Color colorTextDark = Color(0xFF202124);
  static const Color colorTextGrey = Color(0xFF5F6368);
  static const Color colorLabelGrey = Color(0xFF80868B);
  static const Color colorDivider = Color(0xFFE8EAED);
  static const Color colorBoxBg = Color(0xFFF8F9FA);

  static const PdfColor pdfTextDark = PdfColor.fromInt(0xFF202124);
  static const PdfColor pdfTextGrey = PdfColor.fromInt(0xFF5F6368);
  static const PdfColor pdfLabelGrey = PdfColor.fromInt(0xFF80868B);
  static const PdfColor pdfDivider = PdfColor.fromInt(0xFFE8EAED);

  // ── Données context ────────────────────────────────────────────────────────

  final InvoiceTemplateModel template;
  final InvoiceModel invoice;
  final List<PaymentModel> payments;
  final BusinessProfileModel profile;
  final List<PaymentMethodModel> paymentMethods;
  final String clientPhone;
  final String clientEmail;
  final String clientAddress;

  const TemplateRenderEngine({
    required this.template,
    required this.invoice,
    required this.payments,
    required this.profile,
    required this.paymentMethods,
    required this.clientPhone,
    required this.clientEmail,
    required this.clientAddress,
  });

  // ── Flutter Widgets ────────────────────────────────────────────────────────

  Widget buildFlutterDocument(Color accent, Color headerBg) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(paddingMain),
      child: switch (template.layout) {
        TemplateLayout.classic => _buildClassicFlutter(accent, headerBg),
        TemplateLayout.modern => _buildModernFlutter(accent, headerBg),
        TemplateLayout.minimal => _buildMinimalFlutter(accent, headerBg),
        TemplateLayout.bold => _buildBoldFlutter(accent, headerBg),
      },
    );
  }

  Widget _buildClassicFlutter(Color accent, Color headerBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!template.topCenter.isEmpty) ...[
          _renderSectionFlutter(template.topCenter, accent),
          const SizedBox(height: gapSection),
        ],
        // Header
        Container(
          padding: const EdgeInsets.all(paddingSection),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (template.showLogo) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(Icons.business_outlined,
                            color: accent, size: 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: template.topLeft.isEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.companyName.isEmpty
                                      ? 'Mon Entreprise'
                                      : profile.companyName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorTextDark,
                                  ),
                                ),
                                if (profile.address.isNotEmpty)
                                  Text(
                                    profile.address,
                                    style: const TextStyle(
                                        fontSize: 9, color: colorTextGrey),
                                  ),
                                if (profile.phone.isNotEmpty)
                                  Text(
                                    profile.phone,
                                    style: const TextStyle(
                                        fontSize: 9, color: colorTextGrey),
                                  ),
                              ],
                            )
                          : _renderSectionFlutter(template.topLeft, accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      template.titleLabel,
                      style: TextStyle(
                        color: _contrastColor(accent),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N° ${invoice.id}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (template.topRight.isEmpty) ...[
                    _metaRowFlutter('Émise le', _fmtDate(invoice.createdAt)),
                    _metaRowFlutter('Échéance', _fmtDate(invoice.dueDate)),
                  ] else
                    _renderSectionFlutter(template.topRight, accent),
                  ..._statusBadgeFlutter(accent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: paddingSection),
        // Client & Custom fields
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: template.bottomLeft.isEmpty
                    ? _partyBoxFlutter(
                        title: 'CLIENT',
                        name: invoice.clientName,
                        lines: [clientAddress, clientPhone, clientEmail],
                        bg: colorBoxBg,
                        accent: accent,
                      )
                    : _renderSectionFlutter(template.bottomLeft, accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: template.bottomRight.isEmpty
                    ? _customFieldsBoxFlutter(accent)
                    : _renderSectionFlutter(template.bottomRight, accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: gapSection),
        // Line items table
        if (invoice.lineItems.isNotEmpty) ...[
          _lineItemsTableFlutter(accent),
          const SizedBox(height: gapSection),
        ],
        // Amounts
        _amountsBoxFlutter(accent),
        // Payment methods
        if (template.showPaymentMethods && paymentMethods.isNotEmpty) ...[
          const SizedBox(height: gapSection),
          _paymentMethodsFlutter(accent),
        ],
        // Footer
        if (!template.bottomCenter.isEmpty) ...[
          const SizedBox(height: gapSection),
          _renderSectionFlutter(template.bottomCenter, accent),
        ],
      ],
    );
  }

  Widget _buildModernFlutter(Color accent, Color headerBg) {
    final textOnHeader = _contrastColor(headerBg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: headerBg,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (template.showLogo)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.business,
                      color: Colors.white.withOpacity(0.85), size: 22),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: template.topLeft.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.companyName.isEmpty
                                ? 'Mon Entreprise'
                                : profile.companyName,
                            style: TextStyle(
                              color: textOnHeader,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (profile.address.isNotEmpty)
                            Text(
                              profile.address,
                              style: TextStyle(
                                  color: textOnHeader.withOpacity(0.7),
                                  fontSize: 9),
                            ),
                        ],
                      )
                    : _renderSectionFlutter(template.topLeft, accent),
              ),
              if (template.topRight.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      template.titleLabel,
                      style: TextStyle(
                        color: textOnHeader,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'N° ${invoice.id}',
                      style: TextStyle(
                        color: textOnHeader,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                _renderSectionFlutter(template.topRight, accent),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!template.topCenter.isEmpty) ...[
                _renderSectionFlutter(template.topCenter, accent),
                const SizedBox(height: gapSection),
              ],
              Row(
                children: [
                  Expanded(
                    child: template.bottomLeft.isEmpty
                        ? _partyBoxFlutter(
                            title: 'CLIENT',
                            name: invoice.clientName,
                            lines: [
                              clientAddress,
                              clientPhone,
                              clientEmail
                            ],
                            bg: colorBoxBg,
                            accent: accent,
                          )
                        : _renderSectionFlutter(template.bottomLeft, accent),
                  ),
                ],
              ),
              const SizedBox(height: gapSection),
              if (invoice.lineItems.isNotEmpty) ...[
                _lineItemsTableFlutter(accent),
                const SizedBox(height: gapSection),
              ],
              _amountsBoxFlutter(accent),
              if (template.showPaymentMethods && paymentMethods.isNotEmpty) ...[
                const SizedBox(height: gapSection),
                _paymentMethodsFlutter(accent),
              ],
              if (!template.bottomCenter.isEmpty) ...[
                const SizedBox(height: gapSection),
                _renderSectionFlutter(template.bottomCenter, accent),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalFlutter(Color accent, Color headerBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: template.topLeft.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.companyName.isEmpty
                              ? 'Mon Entreprise'
                              : profile.companyName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorTextDark,
                          ),
                        ),
                        if (profile.phone.isNotEmpty)
                          Text(
                            profile.phone,
                            style: const TextStyle(
                              fontSize: 9,
                              color: colorTextGrey,
                            ),
                          ),
                      ],
                    )
                  : _renderSectionFlutter(template.topLeft, accent),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  template.titleLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'N° ${invoice.id}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: accent, thickness: 1.5),
        const SizedBox(height: paddingSection),
        Row(
          children: [
            Expanded(
              child: template.bottomLeft.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CLIENT',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: colorLabelGrey,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.clientName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorTextDark,
                          ),
                        ),
                        if (clientPhone.isNotEmpty)
                          Text(
                            clientPhone,
                            style: const TextStyle(
                              fontSize: 9,
                              color: colorTextGrey,
                            ),
                          ),
                      ],
                    )
                  : _renderSectionFlutter(template.bottomLeft, accent),
            ),
          ],
        ),
        const SizedBox(height: paddingSection),
        if (invoice.lineItems.isNotEmpty) ...[
          _lineItemsTableFlutter(accent),
          const SizedBox(height: gapSection),
        ],
        _amountsBoxFlutter(accent),
      ],
    );
  }

  Widget _buildBoldFlutter(Color accent, Color headerBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          child: Row(
            children: [
              if (template.showLogo)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.business,
                      color: Colors.white.withOpacity(0.9)),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  template.titleLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    invoice.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N° ${invoice.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 4,
          color: accent.withOpacity(0.6),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: template.bottomLeft.isEmpty
                        ? _partyBoxFlutter(
                            title: 'CLIENT',
                            name: invoice.clientName,
                            lines: [
                              clientAddress,
                              clientPhone,
                              clientEmail
                            ],
                            bg: colorBoxBg,
                            accent: accent,
                          )
                        : _renderSectionFlutter(template.bottomLeft, accent),
                  ),
                ],
              ),
              const SizedBox(height: gapSection),
              if (invoice.lineItems.isNotEmpty) ...[
                _lineItemsTableFlutter(accent),
                const SizedBox(height: gapSection),
              ],
              _amountsBoxFlutter(accent),
              if (template.showPaymentMethods && paymentMethods.isNotEmpty) ...[
                const SizedBox(height: gapSection),
                _paymentMethodsFlutter(accent),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Flutter Helpers ────────────────────────────────────────────────────────

  Widget _renderSectionFlutter(TemplateSectionModel section, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: section.fields.map((f) {
        final text = _resolveField(f);
        if (text.isEmpty) return const SizedBox();
        final color = f.textColor != null ? Color(f.textColor!) : colorTextDark;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            text,
            style: TextStyle(
              fontSize: f.large ? 14 : 9,
              fontWeight: f.bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _partyBoxFlutter({
    required String title,
    required String name,
    required List<String> lines,
    required Color bg,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: colorLabelGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorTextDark,
            ),
          ),
          ...lines
              .where((l) => l.isNotEmpty)
              .map((l) => Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 9,
                        color: colorTextGrey,
                      ),
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _customFieldsBoxFlutter(Color accent) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: colorBoxBg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: colorLabelGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            invoice.notes.isEmpty ? 'Aucune note' : invoice.notes,
            style: const TextStyle(
              fontSize: 9,
              color: colorTextGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineItemsTableFlutter(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Désignation',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qté',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accent),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'PU',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accent),
                  textAlign: TextAlign.end,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accent),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        ...invoice.lineItems.map((item) {
          final qty = (item['qty'] as num? ?? 1).toInt();
          final pu = (item['unitPrice'] as num? ?? 0).toDouble();
          final total = qty * pu;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    item['description'] as String? ?? '',
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '$qty',
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.format(pu),
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    CurrencyFormatter.format(total),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _amountsBoxFlutter(Color accent) {
    final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final balance = invoice.totalAmount - totalPaid;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorDivider,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _amountRowFlutter('Sous-total', invoice.totalAmount, accent),
            const SizedBox(height: 4),
            const Divider(height: 12),
            _amountRowFlutter('Total', invoice.totalAmount, accent, bold: true, large: true),
            const SizedBox(height: 2),
            _amountRowFlutter('Payé', totalPaid, accent),
            const SizedBox(height: 2),
            _amountRowFlutter(
              'Reste',
              balance,
              const Color(0xFFC5221F),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodsFlutter(Color accent) {
    if (paymentMethods.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MODES DE PAIEMENT',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: colorLabelGrey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: paymentMethods.map((m) {
            return Expanded(
              child: Container(
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colorDivider,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    m.label,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _metaRowFlutter(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 7, color: colorLabelGrey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 7, color: colorTextGrey),
          ),
        ],
      ),
    );
  }

  List<Widget> _statusBadgeFlutter(Color accent) {
    final color = _invoiceStatusColor(invoice.status);
    return [
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 0.5),
        ),
        child: Text(
          _statusLabel(invoice.status),
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  Widget _amountRowFlutter(
    String label,
    double amount,
    Color color, {
    bool bold = false,
    bool large = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: large ? 10 : 8,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: colorTextDark,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: large ? 10 : 8,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _resolveField(TemplateFieldConfig f) {
    return switch (f.source) {
      FieldSource.companyName => profile.companyName,
      FieldSource.companyAddress => profile.address,
      FieldSource.companyPhone => profile.phone,
      FieldSource.companyEmail => profile.email,
      FieldSource.companyRccm => profile.rccm,
      FieldSource.invoiceNumber => invoice.id,
      FieldSource.invoiceDate => _fmtDate(invoice.createdAt),
      FieldSource.invoiceDueDate => _fmtDate(invoice.dueDate),
      FieldSource.clientName => invoice.clientName,
      FieldSource.clientPhone => clientPhone,
      FieldSource.clientEmail => clientEmail,
      FieldSource.clientAddress => clientAddress,
      FieldSource.invoiceTitle => invoice.title,
      FieldSource.invoiceStatus => _statusLabel(invoice.status),
      FieldSource.bankInfo => profile.bankName,
      FieldSource.manual => f.manualValue ?? '',
    };
  }

  static String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _statusLabel(InvoiceStatus status) => switch (status) {
        InvoiceStatus.draft => 'Brouillon',
        InvoiceStatus.partial => 'Partiellement payée',
        InvoiceStatus.paid => 'Payée',
        InvoiceStatus.late => 'En retard',
      };

  static Color _invoiceStatusColor(InvoiceStatus status) => switch (status) {
        InvoiceStatus.draft => const Color(0xFF9AA0A6),
        InvoiceStatus.partial => const Color(0xFFF57F17),
        InvoiceStatus.paid => const Color(0xFF0B8043),
        InvoiceStatus.late => const Color(0xFFC5221F),
      };

  static Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.35 ? Colors.black87 : Colors.white;
  }
}
