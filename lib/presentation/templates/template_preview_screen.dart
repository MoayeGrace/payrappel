import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/models/invoice_template_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../providers/business_profile_provider.dart';

// ── Preview profile data ──────────────────────────────────────────────────────

class PreviewProfile {
  final String companyName;
  final String address;
  final String phone;
  final String email;

  const PreviewProfile({
    required this.companyName,
    required this.address,
    required this.phone,
    required this.email,
  });

  factory PreviewProfile.from(BusinessProfileModel p) => PreviewProfile(
        companyName: p.companyName.isEmpty ? 'Mon Entreprise' : p.companyName,
        address: p.address.isEmpty ? 'Abidjan, Plateau' : p.address,
        phone: p.phone.isEmpty ? '+225 07 00 00 00' : p.phone,
        email: p.email.isEmpty ? 'contact@entreprise.com' : p.email,
      );

  static const demo = PreviewProfile(
    companyName: 'Mon Entreprise',
    address: 'Abidjan, Plateau',
    phone: '+225 07 00 00 00',
    email: 'contact@entreprise.com',
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TemplatePreviewScreen extends StatelessWidget {
  final InvoiceTemplateModel template;
  const TemplatePreviewScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final accent = Color(template.accentColor);
    final headerBg = template.headerBgColor != null
        ? Color(template.headerBgColor!)
        : accent;

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: _contrastColor(accent),
        elevation: 0,
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/templates/edit', extra: template);
            },
            icon: Icon(
              template.isBuiltIn ? Icons.copy_outlined : Icons.tune_outlined,
              color: _contrastColor(accent),
              size: 18,
            ),
            label: Text(
              template.isBuiltIn ? 'Copier' : 'Éditer',
              style: TextStyle(
                  color: _contrastColor(accent),
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: accent.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _LayoutChip(label: _layoutLabel(template.layout), color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aperçu avec données de démonstration',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 4.0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Consumer<BusinessProfileProvider>(
                    

                    builder: (_, prov, __) => InvoiceDocPreview(
                      template: template,
                      accent: accent,
                      headerBg: headerBg,
                      profile: PreviewProfile.from(prov.profile),
                      logoPath: prov.profile.logoPath,
                      paymentMethods: prov.profile.paymentMethods
                          .where((m) => m.isEnabled)
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/templates/edit', extra: template);
                  },
                  icon: const Icon(Icons.tune_outlined, size: 18),
                  label: const Text('Personnaliser ce template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: _contrastColor(accent),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _layoutLabel(TemplateLayout l) => switch (l) {
        TemplateLayout.classic => 'Classique',
        TemplateLayout.modern => 'Moderne',
        TemplateLayout.minimal => 'Minimaliste',
        TemplateLayout.bold => 'Impact',
      };

  static Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.35 ? Colors.black87 : Colors.white;
  }
}

// ── Layout chip ───────────────────────────────────────────────────────────────

class _LayoutChip extends StatelessWidget {
  final String label;
  final Color color;
  const _LayoutChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: TemplatePreviewScreen._contrastColor(color),
            fontSize: 10,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Selectable zone (for interactive editor) ──────────────────────────────────

class _SelectableZone extends StatelessWidget {
  final TemplateSectionId id;
  final TemplateSectionId? selected;
  final ValueChanged<TemplateSectionId?>? onTap;
  final VoidCallback? onAddField;
  final OnSectionSwap? onSectionSwap;
  final Widget child;

  const _SelectableZone({
    required this.id,
    required this.selected,
    this.onTap,
    this.onAddField,
    this.onSectionSwap,
    required this.child,
  });

  bool get _isSelected => id == selected;

  static const _blue = Color(0xFF1A73E8);
  static const _green = Color(0xFF34A853);
  static const _orange = Color(0xFFF57C00);

  String get _label => switch (id) {
        TemplateSectionId.topLeft => 'En-tête G.',
        TemplateSectionId.topCenter => 'En-tête Centre',
        TemplateSectionId.topRight => 'En-tête D.',
        TemplateSectionId.bottomLeft => 'Client',
        TemplateSectionId.bottomRight => 'Champs libres',
        TemplateSectionId.bottomCenter => 'Pied de page',
      };

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;

    // The main tappable zone (select / deselect)
    Widget zoneWidget = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onTap!(_isSelected ? null : id),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: _isSelected
                      ? Border.all(color: _blue, width: 1.5)
                      : Border.all(color: Colors.transparent, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap in outer Stack so the overlay chips are siblings of the zone
    // (not descendants), avoiding gesture conflicts.
    Widget result = Stack(
      clipBehavior: Clip.none,
      children: [
        zoneWidget,
        if (_isSelected)
          Positioned(
            top: -1,
            left: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label chip (non-interactive)
                IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      _label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // "+" button — interactive, separate from zone GestureDetector
                if (onAddField != null) ...[
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: onAddField,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(Icons.add,
                          size: 8, color: Colors.white),
                    ),
                  ),
                ],
                // Drag handle — visible only when section is selected
                if (onSectionSwap != null) ...[
                  const SizedBox(width: 2),
                  IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(Icons.drag_indicator,
                          size: 8, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );

    // If drag-and-drop is enabled, wrap with DragTarget + LongPressDraggable
    if (onSectionSwap != null) {
      // Capture the current widget value before each wrapping to avoid
      // the closure capturing the `result` variable by reference, which
      // causes infinite recursion (Stack Overflow) when Flutter calls builder.
      final innerWidget = result;
      result = DragTarget<TemplateSectionId>(
        onWillAcceptWithDetails: (d) => d.data != id,
        onAcceptWithDetails: (d) => onSectionSwap!(d.data, id),
        builder: (context, candidates, _) {
          final isHovered = candidates.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: isHovered
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _orange, width: 2),
                    color: _orange.withOpacity(0.08),
                  )
                : const BoxDecoration(),
            child: innerWidget,
          );
        },
      );

      final dragTarget = result;
      result = LongPressDraggable<TemplateSectionId>(
        data: id,
        delay: const Duration(milliseconds: 350),
        feedback: Material(
          elevation: 6,
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_indicator,
                    size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: dragTarget),
        child: dragTarget,
      );
    }

    return result;
  }
}

// ── Tappable section (table / payment — navigates to editor tab) ──────────────

class _TappableSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget child;

  const _TappableSection({
    required this.label,
    required this.icon,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCDD1D6), width: 0.8),
            ),
            child: child,
          ),
          Positioned(
            top: -1,
            right: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF9AA0A6),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 6, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Callbacks ─────────────────────────────────────────────────────────────────

typedef OnInlineFieldTap = void Function(
    TemplateSectionId sectionId, int fieldIndex, TemplateFieldConfig field);

typedef OnSectionAddField = void Function(TemplateSectionId sectionId);

typedef OnSectionSwap = void Function(
    TemplateSectionId from, TemplateSectionId to);

// ── Document preview ──────────────────────────────────────────────────────────

class InvoiceDocPreview extends StatelessWidget {
  final InvoiceTemplateModel template;
  final Color accent;
  final Color headerBg;
  final PreviewProfile profile;
  final String? logoPath;
  final double elevation;
  final TemplateSectionId? selectedSection;
  final ValueChanged<TemplateSectionId?>? onSectionTap;
  final List<PaymentMethodModel> paymentMethods;
  final OnInlineFieldTap? onFieldTap;
  final OnSectionAddField? onAddField;
  final OnSectionSwap? onSectionSwap;
  final VoidCallback? onTableTap;
  final VoidCallback? onPaymentTap;

  const InvoiceDocPreview({
    super.key,
    required this.template,
    required this.accent,
    required this.headerBg,
    required this.profile,
    this.logoPath,
    this.elevation = 6,
    this.selectedSection,
    this.onSectionTap,
    this.paymentMethods = const [],
    this.onFieldTap,
    this.onAddField,
    this.onSectionSwap,
    this.onTableTap,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.poppins(),
      child: Material(
        elevation: elevation,
        borderRadius: BorderRadius.circular(4),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: switch (template.layout) {
          TemplateLayout.classic => _ClassicDoc(
              accent: accent,
              template: template,
              profile: profile,
              logoPath: logoPath,
              selectedSection: selectedSection,
              onSectionTap: onSectionTap,
              paymentMethods: paymentMethods,
              onFieldTap: onFieldTap,
              onAddField: onAddField,
              onSectionSwap: onSectionSwap,
              onTableTap: onTableTap,
              onPaymentTap: onPaymentTap,
            ),
          TemplateLayout.modern => _ModernDoc(
              accent: accent,
              headerBg: headerBg,
              template: template,
              profile: profile,
              logoPath: logoPath,
              selectedSection: selectedSection,
              onSectionTap: onSectionTap,
              paymentMethods: paymentMethods,
              onFieldTap: onFieldTap,
              onAddField: onAddField,
              onSectionSwap: onSectionSwap,
              onTableTap: onTableTap,
              onPaymentTap: onPaymentTap,
            ),
          TemplateLayout.minimal => _MinimalDoc(
              accent: accent,
              template: template,
              profile: profile,
              logoPath: logoPath,
              selectedSection: selectedSection,
              onSectionTap: onSectionTap,
              paymentMethods: paymentMethods,
              onFieldTap: onFieldTap,
              onAddField: onAddField,
              onSectionSwap: onSectionSwap,
              onTableTap: onTableTap,
              onPaymentTap: onPaymentTap,
            ),
          TemplateLayout.bold => _BoldDoc(
              accent: accent,
              headerBg: headerBg,
              template: template,
              profile: profile,
              logoPath: logoPath,
              selectedSection: selectedSection,
              onSectionTap: onSectionTap,
              paymentMethods: paymentMethods,
              onFieldTap: onFieldTap,
              onAddField: onAddField,
              onSectionSwap: onSectionSwap,
              onTableTap: onTableTap,
              onPaymentTap: onPaymentTap,
            ),
        },
      ),
    ),
    );
  }
}

// ── Classic document ──────────────────────────────────────────────────────────

class _ClassicDoc extends StatelessWidget {
  final Color accent;
  final InvoiceTemplateModel template;
  final PreviewProfile profile;
  final String? logoPath;
  final TemplateSectionId? selectedSection;
  final ValueChanged<TemplateSectionId?>? onSectionTap;
  final List<PaymentMethodModel> paymentMethods;
  final OnInlineFieldTap? onFieldTap;
  final OnSectionAddField? onAddField;
  final OnSectionSwap? onSectionSwap;
  final VoidCallback? onTableTap;
  final VoidCallback? onPaymentTap;

  const _ClassicDoc({
    required this.accent,
    required this.template,
    required this.profile,
    this.logoPath,
    this.selectedSection,
    this.onSectionTap,
    this.paymentMethods = const [],
    this.onFieldTap,
    this.onAddField,
    this.onSectionSwap,
    this.onTableTap,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!template.topCenter.isEmpty) ...[
            _SelectableZone(
              id: TemplateSectionId.topCenter,
              selected: selectedSection,
              onTap: onSectionTap,
              onSectionSwap: onSectionSwap,
              onAddField: onAddField != null
                  ? () => onAddField!(TemplateSectionId.topCenter)
                  : null,
              child: _renderSection(template.topCenter, profile,
                  boldColor: const Color(0xFF202124),
                  baseFontSize: 9,
                  sectionId: TemplateSectionId.topCenter,
                  onFieldTap: onFieldTap),
            ),
            const SizedBox(height: 10),
          ],
          // ── En-tête ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gauche : logo + société
                Expanded(
                  flex: 3,
                  child: _SelectableZone(
                    id: TemplateSectionId.topLeft,
                    selected: selectedSection,
                    onTap: onSectionTap,
                    onSectionSwap: onSectionSwap,
                    onAddField: onAddField != null
                        ? () => onAddField!(TemplateSectionId.topLeft)
                        : null,
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
                            child: logoPath != null && logoPath!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Image.file(
                                      File(logoPath!),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.business_outlined, color: accent, size: 20),
                                    ),
                                  )
                                : Icon(Icons.business_outlined, color: accent, size: 20),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: template.topLeft.isEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _bold(profile.companyName, size: 12),
                                    if (profile.address.isNotEmpty) _grey(profile.address),
                                    if (profile.phone.isNotEmpty) _grey(profile.phone),
                                  ],
                                )
                              : _renderSection(template.topLeft, profile,
                                  boldColor: const Color(0xFF202124),
                                  baseFontSize: 9,
                                  sectionId: TemplateSectionId.topLeft,
                                  onFieldTap: onFieldTap),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Droite : badge + numéro + méta
                _SelectableZone(
                  id: TemplateSectionId.topRight,
                  selected: selectedSection,
                  onTap: onSectionTap,
                  onSectionSwap: onSectionSwap,
                  onAddField: onAddField != null
                      ? () => onAddField!(TemplateSectionId.topRight)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          template.titleLabel,
                          style: TextStyle(
                              color: TemplatePreviewScreen._contrastColor(accent),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (template.topRight.isEmpty) ...[
                        Text('N° FAC-2026-A3B4C5',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accent)),
                        const SizedBox(height: 3),
                        _metaRow('Émise le', '01/01/2026'),
                        _metaRow('Échéance', '31/01/2026'),
                      ] else
                        _renderSection(template.topRight, profile,
                            baseFontSize: 8,
                            sectionId: TemplateSectionId.topRight,
                            onFieldTap: onFieldTap),
                      const SizedBox(height: 4),
                      _statusChipDemo(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SelectableZone(
                    id: TemplateSectionId.bottomLeft,
                    selected: selectedSection,
                    onTap: onSectionTap,
                    onSectionSwap: onSectionSwap,
                    onAddField: onAddField != null
                        ? () => onAddField!(TemplateSectionId.bottomLeft)
                        : null,
                    child: template.bottomLeft.isEmpty
                        ? _partyBox(
                            title: 'CLIENT',
                            name: 'Jean Dupont',
                            lines: const ['+225 05 00 00 00'],
                            bg: const Color(0xFFF8F9FA),
                          )
                        : _renderSection(template.bottomLeft, profile,
                            boldColor: const Color(0xFF202124),
                            baseFontSize: 9,
                            sectionId: TemplateSectionId.bottomLeft,
                            onFieldTap: onFieldTap),
                  ),
                ),
                if (!template.bottomRight.isEmpty || onSectionTap != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SelectableZone(
                      id: TemplateSectionId.bottomRight,
                      selected: selectedSection,
                      onTap: onSectionTap,
                      onSectionSwap: onSectionSwap,
                      onAddField: onAddField != null
                          ? () => onAddField!(TemplateSectionId.bottomRight)
                          : null,
                      child: template.bottomRight.isEmpty
                          ? _customFieldsBox(accent)
                          : _renderSection(template.bottomRight, profile,
                              boldColor: const Color(0xFF202124),
                              baseFontSize: 9,
                              sectionId: TemplateSectionId.bottomRight,
                              onFieldTap: onFieldTap),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TappableSection(
            label: 'Tableau',
            icon: Icons.table_chart_outlined,
            onTap: onTableTap,
            child: Column(
              children: [
                _tablePreview(template, accent),
                _amountsBox(accent),
              ],
            ),
          ),
          if (template.showPaymentMethods)
            _TappableSection(
              label: 'Paiement',
              icon: Icons.payments_outlined,
              onTap: onPaymentTap,
              child: _paymentMethodsBlock(template, accent, paymentMethods),
            ),
          const SizedBox(height: 14),
          _SelectableZone(
            id: TemplateSectionId.bottomCenter,
            selected: selectedSection,
            onTap: onSectionTap,
            onSectionSwap: onSectionSwap,
            onAddField: onAddField != null
                ? () => onAddField!(TemplateSectionId.bottomCenter)
                : null,
            child: _footerSection(template.bottomCenter, accent, profile, onFieldTap: onFieldTap),
          ),
        ],
      ),
    );
  }
}

// ── Modern document ───────────────────────────────────────────────────────────

class _ModernDoc extends StatelessWidget {
  final Color accent;
  final Color headerBg;
  final InvoiceTemplateModel template;
  final PreviewProfile profile;
  final String? logoPath;
  final TemplateSectionId? selectedSection;
  final ValueChanged<TemplateSectionId?>? onSectionTap;
  final List<PaymentMethodModel> paymentMethods;
  final OnInlineFieldTap? onFieldTap;
  final OnSectionAddField? onAddField;
  final OnSectionSwap? onSectionSwap;
  final VoidCallback? onTableTap;
  final VoidCallback? onPaymentTap;

  const _ModernDoc({
    required this.accent,
    required this.headerBg,
    required this.template,
    required this.profile,
    this.logoPath,
    this.selectedSection,
    this.onSectionTap,
    this.paymentMethods = const [],
    this.onFieldTap,
    this.onAddField,
    this.onSectionSwap,
    this.onTableTap,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    final textOnHeader = TemplatePreviewScreen._contrastColor(headerBg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bandeau coloré
        Container(
          color: headerBg,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (template.showLogo) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: logoPath != null && logoPath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(logoPath!),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(Icons.business,
                                color: Colors.white.withOpacity(0.85), size: 22),
                          ),
                        )
                      : Icon(Icons.business,
                          color: Colors.white.withOpacity(0.85), size: 22),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _SelectableZone(
                  id: TemplateSectionId.topLeft,
                  selected: selectedSection,
                  onTap: onSectionTap,
                  onSectionSwap: onSectionSwap,
                  onAddField: onAddField != null
                      ? () => onAddField!(TemplateSectionId.topLeft)
                      : null,
                  child: template.topLeft.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.companyName,
                                style: TextStyle(
                                    color: textOnHeader,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            if (profile.address.isNotEmpty)
                              Text(profile.address,
                                  style: TextStyle(
                                      color: textOnHeader.withOpacity(0.7),
                                      fontSize: 9)),
                            if (profile.phone.isNotEmpty)
                              Text(profile.phone,
                                  style: TextStyle(
                                      color: textOnHeader.withOpacity(0.7),
                                      fontSize: 9)),
                          ],
                        )
                      : _renderSection(template.topLeft, profile,
                          boldColor: textOnHeader,
                          baseColor: textOnHeader.withOpacity(0.7),
                          baseFontSize: 9,
                          sectionId: TemplateSectionId.topLeft,
                          onFieldTap: onFieldTap),
                ),
              ),
              _SelectableZone(
                id: TemplateSectionId.topRight,
                selected: selectedSection,
                onTap: onSectionTap,
                onSectionSwap: onSectionSwap,
                onAddField: onAddField != null
                    ? () => onAddField!(TemplateSectionId.topRight)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (template.topRight.isEmpty) ...[
                      Text(template.titleLabel,
                          style: TextStyle(
                              color: textOnHeader,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 3),
                      Text('N° FAC-2026-A3B4C5',
                          style: TextStyle(
                              color: textOnHeader,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Facture Janv. 2026',
                          style: TextStyle(
                              color: textOnHeader.withOpacity(0.7),
                              fontSize: 9)),
                      Text('Éch. : 31/01/2026',
                          style: TextStyle(
                              color: textOnHeader.withOpacity(0.7),
                              fontSize: 9)),
                    ] else
                      _renderSection(template.topRight, profile,
                          boldColor: textOnHeader,
                          baseColor: textOnHeader.withOpacity(0.7),
                          baseFontSize: 9,
                          sectionId: TemplateSectionId.topRight,
                          onFieldTap: onFieldTap),
                    const SizedBox(height: 4),
                    _statusChipDemo(),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Corps
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!template.topCenter.isEmpty) ...[
                _SelectableZone(
                  id: TemplateSectionId.topCenter,
                  selected: selectedSection,
                  onTap: onSectionTap,
                  onSectionSwap: onSectionSwap,
                  onAddField: onAddField != null
                      ? () => onAddField!(TemplateSectionId.topCenter)
                      : null,
                  child: _renderSection(template.topCenter, profile,
                      boldColor: const Color(0xFF202124),
                      baseFontSize: 9,
                      sectionId: TemplateSectionId.topCenter,
                      onFieldTap: onFieldTap),
                ),
                const SizedBox(height: 10),
              ],
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SelectableZone(
                        id: TemplateSectionId.bottomLeft,
                        selected: selectedSection,
                        onTap: onSectionTap,
                        onSectionSwap: onSectionSwap,
                        onAddField: onAddField != null
                            ? () => onAddField!(TemplateSectionId.bottomLeft)
                            : null,
                        child: template.bottomLeft.isEmpty
                            ? _partyBox(
                                title: 'CLIENT',
                                name: 'Jean Dupont',
                                lines: const ['+225 05 00 00 00'],
                                bg: const Color(0xFFF8F9FA),
                              )
                            : _renderSection(template.bottomLeft, profile,
                                boldColor: const Color(0xFF202124),
                                baseFontSize: 9,
                                sectionId: TemplateSectionId.bottomLeft,
                                onFieldTap: onFieldTap),
                      ),
                    ),
                    if (!template.bottomRight.isEmpty || onSectionTap != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SelectableZone(
                          id: TemplateSectionId.bottomRight,
                          selected: selectedSection,
                          onTap: onSectionTap,
                          onSectionSwap: onSectionSwap,
                          onAddField: onAddField != null
                              ? () => onAddField!(TemplateSectionId.bottomRight)
                              : null,
                          child: template.bottomRight.isEmpty
                              ? _customFieldsBox(accent)
                              : _renderSection(template.bottomRight, profile,
                                  boldColor: const Color(0xFF202124),
                                  baseFontSize: 9,
                                  sectionId: TemplateSectionId.bottomRight,
                                  onFieldTap: onFieldTap),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _TappableSection(
                label: 'Tableau',
                icon: Icons.table_chart_outlined,
                onTap: onTableTap,
                child: Column(
                  children: [
                    _tablePreview(template, accent),
                    _amountsBox(accent),
                  ],
                ),
              ),
              if (template.showPaymentMethods)
                _TappableSection(
                  label: 'Paiement',
                  icon: Icons.payments_outlined,
                  onTap: onPaymentTap,
                  child: _paymentMethodsBlock(template, accent, paymentMethods),
                ),
              const SizedBox(height: 14),
              _SelectableZone(
                id: TemplateSectionId.bottomCenter,
                selected: selectedSection,
                onTap: onSectionTap,
                onSectionSwap: onSectionSwap,
                onAddField: onAddField != null
                    ? () => onAddField!(TemplateSectionId.bottomCenter)
                    : null,
                child: _footerSection(template.bottomCenter, accent, profile, onFieldTap: onFieldTap),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Minimal document ──────────────────────────────────────────────────────────

class _MinimalDoc extends StatelessWidget {
  final Color accent;
  final InvoiceTemplateModel template;
  final PreviewProfile profile;
  final String? logoPath;
  final TemplateSectionId? selectedSection;
  final ValueChanged<TemplateSectionId?>? onSectionTap;
  final List<PaymentMethodModel> paymentMethods;
  final OnInlineFieldTap? onFieldTap;
  final OnSectionAddField? onAddField;
  final OnSectionSwap? onSectionSwap;
  final VoidCallback? onTableTap;
  final VoidCallback? onPaymentTap;

  const _MinimalDoc({
    required this.accent,
    required this.template,
    required this.profile,
    this.logoPath,
    this.selectedSection,
    this.onSectionTap,
    this.paymentMethods = const [],
    this.onFieldTap,
    this.onAddField,
    this.onSectionSwap,
    this.onTableTap,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SelectableZone(
                  id: TemplateSectionId.topLeft,
                  selected: selectedSection,
                  onTap: onSectionTap,
                  onSectionSwap: onSectionSwap,
                  onAddField: onAddField != null
                      ? () => onAddField!(TemplateSectionId.topLeft)
                      : null,
                  child: template.topLeft.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bold(profile.companyName, size: 14),
                            if (profile.phone.isNotEmpty) _grey(profile.phone),
                            if (profile.email.isNotEmpty) _grey(profile.email),
                          ],
                        )
                      : _renderSection(template.topLeft, profile,
                          boldColor: const Color(0xFF202124),
                          baseFontSize: 9,
                          sectionId: TemplateSectionId.topLeft,
                          onFieldTap: onFieldTap),
                ),
              ),
              _SelectableZone(
                id: TemplateSectionId.topRight,
                selected: selectedSection,
                onTap: onSectionTap,
                onSectionSwap: onSectionSwap,
                onAddField: onAddField != null
                    ? () => onAddField!(TemplateSectionId.topRight)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    template.topRight.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                template.titleLabel,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                    letterSpacing: 2),
                              ),
                              const SizedBox(height: 2),
                              Text('N° FAC-2026-A3B4C5',
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: accent)),
                              _metaRow('Émise', '01/01/2026'),
                              _metaRow('Échéance', '31/01/2026'),
                            ],
                          )
                        : _renderSection(template.topRight, profile,
                            boldColor: const Color(0xFF202124),
                            baseFontSize: 9,
                            sectionId: TemplateSectionId.topRight,
                            onFieldTap: onFieldTap),
                    const SizedBox(height: 4),
                    _statusChipDemo(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1.5, color: accent),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SelectableZone(
                    id: TemplateSectionId.bottomLeft,
                    selected: selectedSection,
                    onTap: onSectionTap,
                    onSectionSwap: onSectionSwap,
                    onAddField: onAddField != null
                        ? () => onAddField!(TemplateSectionId.bottomLeft)
                        : null,
                    child: template.bottomLeft.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('CLIENT'),
                              const SizedBox(height: 3),
                              _bold('Jean Dupont', size: 11),
                              _grey('+225 05 00 00 00'),
                              _grey('jean@email.com'),
                            ],
                          )
                        : _renderSection(template.bottomLeft, profile,
                            boldColor: const Color(0xFF202124),
                            baseFontSize: 9,
                            sectionId: TemplateSectionId.bottomLeft,
                            onFieldTap: onFieldTap),
                  ),
                ),
                if (!template.bottomRight.isEmpty || onSectionTap != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SelectableZone(
                      id: TemplateSectionId.bottomRight,
                      selected: selectedSection,
                      onTap: onSectionTap,
                      onSectionSwap: onSectionSwap,
                      onAddField: onAddField != null
                          ? () => onAddField!(TemplateSectionId.bottomRight)
                          : null,
                      child: template.bottomRight.isEmpty
                          ? _customFieldsBox(accent)
                          : _renderSection(template.bottomRight, profile,
                              boldColor: const Color(0xFF202124),
                              baseFontSize: 9,
                              sectionId: TemplateSectionId.bottomRight,
                              onFieldTap: onFieldTap),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200, thickness: 0.5),
          const SizedBox(height: 10),
          _TappableSection(
            label: 'Tableau',
            icon: Icons.table_chart_outlined,
            onTap: onTableTap,
            child: Column(
              children: [
                _tablePreview(template, accent),
                _amountsBox(accent),
              ],
            ),
          ),
          if (template.showPaymentMethods)
            _TappableSection(
              label: 'Paiement',
              icon: Icons.payments_outlined,
              onTap: onPaymentTap,
              child: _paymentMethodsBlock(template, accent, paymentMethods),
            ),
          const SizedBox(height: 14),
          _SelectableZone(
            id: TemplateSectionId.bottomCenter,
            selected: selectedSection,
            onTap: onSectionTap,
            onSectionSwap: onSectionSwap,
            onAddField: onAddField != null
                ? () => onAddField!(TemplateSectionId.bottomCenter)
                : null,
            child: _footerSection(template.bottomCenter, accent, profile, onFieldTap: onFieldTap),
          ),
        ],
      ),
    );
  }
}

// ── Bold document ─────────────────────────────────────────────────────────────

class _BoldDoc extends StatelessWidget {
  final Color accent;
  final Color headerBg;
  final InvoiceTemplateModel template;
  final PreviewProfile profile;
  final String? logoPath;
  final TemplateSectionId? selectedSection;
  final ValueChanged<TemplateSectionId?>? onSectionTap;
  final List<PaymentMethodModel> paymentMethods;
  final OnInlineFieldTap? onFieldTap;
  final OnSectionAddField? onAddField;
  final OnSectionSwap? onSectionSwap;
  final VoidCallback? onTableTap;
  final VoidCallback? onPaymentTap;

  const _BoldDoc({
    required this.accent,
    required this.headerBg,
    required this.template,
    required this.profile,
    this.logoPath,
    this.selectedSection,
    this.onSectionTap,
    this.paymentMethods = const [],
    this.onFieldTap,
    this.onAddField,
    this.onSectionSwap,
    this.onTableTap,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    final textOnHeader = TemplatePreviewScreen._contrastColor(headerBg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: logoPath != null && logoPath!.isNotEmpty
                    ? ClipOval(
                        child: Image.file(
                          File(logoPath!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.business,
                              color: Colors.white.withOpacity(0.85), size: 22),
                        ),
                      )
                    : Icon(Icons.business,
                        color: Colors.white.withOpacity(0.85), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SelectableZone(
                  id: TemplateSectionId.topCenter,
                  selected: selectedSection,
                  onTap: onSectionTap,
                  onSectionSwap: onSectionSwap,
                  onAddField: onAddField != null
                      ? () => onAddField!(TemplateSectionId.topCenter)
                      : null,
                  child: template.topCenter.isEmpty
                      ? Text(
                          template.titleLabel.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: textOnHeader,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3),
                        )
                      : _renderSection(template.topCenter, profile,
                          boldColor: textOnHeader,
                          baseColor: textOnHeader.withOpacity(0.7),
                          baseFontSize: 11,
                          sectionId: TemplateSectionId.topCenter,
                          onFieldTap: onFieldTap),
                ),
              ),
              _SelectableZone(
                id: TemplateSectionId.topRight,
                selected: selectedSection,
                onTap: onSectionTap,
                onSectionSwap: onSectionSwap,
                onAddField: onAddField != null
                    ? () => onAddField!(TemplateSectionId.topRight)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (template.topRight.isEmpty) ...[
                      Text('Facture Janv. 2026',
                          style: TextStyle(
                              color: textOnHeader,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('N° FAC-2026-A3B4C5',
                          style: TextStyle(
                              color: textOnHeader,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Émis le 01/01/2026',
                          style: TextStyle(
                              color: textOnHeader.withOpacity(0.7), fontSize: 8)),
                      Text('Éch. 31/01/2026',
                          style: TextStyle(
                              color: textOnHeader.withOpacity(0.7),
                              fontSize: 8)),
                    ] else
                      _renderSection(template.topRight, profile,
                          boldColor: textOnHeader,
                          baseColor: textOnHeader.withOpacity(0.7),
                          baseFontSize: 8,
                          sectionId: TemplateSectionId.topRight,
                          onFieldTap: onFieldTap),
                    const SizedBox(height: 4),
                    _statusChipDemo(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 4,
          color: accent.withOpacity(accent.computeLuminance() > 0.5 ? 0.7 : 0.5),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SelectableZone(
                        id: TemplateSectionId.bottomLeft,
                        selected: selectedSection,
                        onTap: onSectionTap,
                        onSectionSwap: onSectionSwap,
                        onAddField: onAddField != null
                            ? () => onAddField!(TemplateSectionId.bottomLeft)
                            : null,
                        child: template.bottomLeft.isEmpty
                            ? _partyBox(
                                title: 'CLIENT',
                                name: 'Jean Dupont',
                                lines: const ['+225 05 00 00 00'],
                                bg: const Color(0xFFF8F9FA),
                              )
                            : _renderSection(template.bottomLeft, profile,
                                boldColor: const Color(0xFF202124),
                                baseFontSize: 9,
                                sectionId: TemplateSectionId.bottomLeft,
                                onFieldTap: onFieldTap),
                      ),
                    ),
                    if (!template.bottomRight.isEmpty || onSectionTap != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SelectableZone(
                          id: TemplateSectionId.bottomRight,
                          selected: selectedSection,
                          onTap: onSectionTap,
                          onSectionSwap: onSectionSwap,
                          onAddField: onAddField != null
                              ? () => onAddField!(TemplateSectionId.bottomRight)
                              : null,
                          child: template.bottomRight.isEmpty
                              ? _customFieldsBox(accent)
                              : _renderSection(template.bottomRight, profile,
                                  boldColor: const Color(0xFF202124),
                                  baseFontSize: 9,
                                  sectionId: TemplateSectionId.bottomRight,
                                  onFieldTap: onFieldTap),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _TappableSection(
                label: 'Tableau',
                icon: Icons.table_chart_outlined,
                onTap: onTableTap,
                child: Column(
                  children: [
                    _tablePreview(template, accent),
                    _amountsBox(accent),
                  ],
                ),
              ),
              if (template.showPaymentMethods)
                _TappableSection(
                  label: 'Paiement',
                  icon: Icons.payments_outlined,
                  onTap: onPaymentTap,
                  child: _paymentMethodsBlock(template, accent, paymentMethods),
                ),
              const SizedBox(height: 14),
              _SelectableZone(
                id: TemplateSectionId.bottomCenter,
                selected: selectedSection,
                onTap: onSectionTap,
                onSectionSwap: onSectionSwap,
                onAddField: onAddField != null
                    ? () => onAddField!(TemplateSectionId.bottomCenter)
                    : null,
                child: _footerSection(template.bottomCenter, accent, profile, onFieldTap: onFieldTap),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared preview widgets ────────────────────────────────────────────────────

Widget _tablePreview(InvoiceTemplateModel template, Color accent) {
  final table = template.customTable;
  if (table.rowCount == 0 || table.columnCount == 0) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        color: accent,
        child: Row(
          children: table.headers.map((h) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Text(h,
                style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis),
            ),
          )).toList(),
        ),
      ),
      ...table.rows.asMap().entries.map((e) => Container(
        decoration: BoxDecoration(
          color: e.key.isOdd ? Colors.grey.shade50 : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 0.3)),
        ),
        child: Row(
          children: e.value.map((cell) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: Text(cell,
                style: const TextStyle(fontSize: 7, color: Color(0xFF202124)),
                overflow: TextOverflow.ellipsis),
            ),
          )).toList(),
        ),
      )),
      const SizedBox(height: 10),
    ],
  );
}

/// Affiche les vrais logos + labels des moyens de paiement sélectionnés.
Widget _paymentMethodsBlock(
  InvoiceTemplateModel template,
  Color accent,
  List<PaymentMethodModel> allMethods,
) {
  final methods = template.selectedPaymentMethodIds.isEmpty
      ? allMethods
      : allMethods
          .where((m) => template.selectedPaymentMethodIds.contains(m.id))
          .toList();

  if (methods.isEmpty) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        Icon(Icons.payment_outlined, size: 9, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text('Moyens de paiement',
            style: TextStyle(fontSize: 7, color: Colors.grey.shade400)),
      ]),
    );
  }

  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PAIEMENT',
          style: TextStyle(
              fontSize: 6,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 0.8)),
      const SizedBox(height: 5),
      Wrap(
        spacing: 5,
        runSpacing: 4,
        children: methods.take(5).map((m) {
          final color = m.type.color;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3), width: 0.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(m.type.icon, size: 10, color: color),
              const SizedBox(width: 3),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.label,
                    style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: color)),
                if (m.fields.isNotEmpty)
                  Text(
                    m.fields.values.first.isNotEmpty
                        ? m.fields.values.first
                        : '—',
                    style: const TextStyle(
                        fontSize: 5.5, color: Color(0xFF9AA0A6)),
                  ),
              ]),
            ]),
          );
        }).toList(),
      ),
    ]),
  );
}


Widget _partyBox({
  required String title,
  required String name,
  required List<String> lines,
  required Color bg,
}) {
  return Container(
    padding: const EdgeInsets.all(9),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(title),
        const SizedBox(height: 3),
        _bold(name, size: 10),
        ...lines.where((l) => l.isNotEmpty).map((l) => _grey(l)),
      ],
    ),
  );
}

Widget _customFieldsBox(Color accent) {
  return Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
        color: accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: accent.withOpacity(0.18), width: 0.5)),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'CHAMPS LIBRES',
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: 7,
              color: Color(0xFF9AA0A6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8),
        ),
        SizedBox(height: 4),
        Text('Conditions de paiement',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 9, color: Color(0xFF5F6368))),
        Text('Références, notes...',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 9, color: Color(0xFF5F6368))),
      ],
    ),
  );
}

Widget _statusChipDemo() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF1A73E8).withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: const Color(0xFF1A73E8), width: 0.5),
    ),
    child: const Text(
      'En cours',
      style: TextStyle(
          color: Color(0xFF1A73E8), fontSize: 7, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _amountsBox(Color accent) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Expanded(
            child: _amountTile(
                'Montant total TTC', '150 000 FCFA', const Color(0xFF202124))),
        Container(width: 0.5, height: 34, color: Colors.grey.shade200),
        Expanded(
            child: _amountTile(
                'Montant payé', '50 000 FCFA', const Color(0xFF34A853))),
        Container(width: 0.5, height: 34, color: Colors.grey.shade200),
        Expanded(
            child: _amountTile(
                'Reste à payer', '100 000 FCFA', const Color(0xFFEA4335),
                large: true)),
      ],
    ),
  );
}

Widget _amountTile(String label, String value, Color color,
    {bool large = false}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(label,
          style: const TextStyle(fontSize: 7, color: Color(0xFF9AA0A6)),
          textAlign: TextAlign.center),
      const SizedBox(height: 3),
      Text(value,
          style: TextStyle(
              fontSize: large ? 10 : 9,
              fontWeight: FontWeight.bold,
              color: color),
          textAlign: TextAlign.center),
    ],
  );
}

// ── Section rendering helpers ─────────────────────────────────────────────────

CrossAxisAlignment _crossAlign(String alignment) => switch (alignment) {
      'center' => CrossAxisAlignment.center,
      'right' => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };

TextAlign _textAlign(String alignment) => switch (alignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

String _fieldValue(TemplateFieldConfig field, PreviewProfile profile) {
  final base = switch (field.source) {
    FieldSource.companyName => profile.companyName,
    FieldSource.companyAddress => profile.address,
    FieldSource.companyPhone => profile.phone,
    FieldSource.companyEmail => profile.email,
    FieldSource.companyRccm => '',
    FieldSource.clientName => 'Jean Dupont',
    FieldSource.clientAddress => 'Abidjan, Plateau',
    FieldSource.clientPhone => '+225 05 00 00 00',
    FieldSource.clientEmail => 'client@email.com',
    FieldSource.invoiceTitle => 'FAC-2026-001',
    FieldSource.invoiceDate => '01/01/2026',
    FieldSource.invoiceDueDate => '31/01/2026',
    FieldSource.invoiceStatus => 'En cours',
    FieldSource.bankInfo => 'Ma Banque — 123456789',
    FieldSource.invoiceNumber => 'N° FAC-2026-A3B4C5',
    FieldSource.today => DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.now()),
    FieldSource.manual => field.manualValue ?? '',
  };
  if (base.isEmpty) return '';
  return field.label != null ? '${field.label} : $base' : base;
}

bool _isColorDark(Color c) {
  final luminance =
      0.2126 * c.red / 255 + 0.7152 * c.green / 255 + 0.0722 * c.blue / 255;
  return luminance < 0.5;
}

Widget _renderSection(
  TemplateSectionModel section,
  PreviewProfile profile, {
  Color baseColor = const Color(0xFF5F6368),
  Color boldColor = const Color(0xFF202124),
  double baseFontSize = 9,
  TextOverflow overflow = TextOverflow.ellipsis,
  TemplateSectionId? sectionId,
  OnInlineFieldTap? onFieldTap,
}) {
  if (section.isEmpty) return const SizedBox.shrink();
  final crossAlign = _crossAlign(section.alignment);
  final tAlign = _textAlign(section.alignment);

  Color? bgColor =
      section.backgroundColor != null ? Color(section.backgroundColor!) : null;
  final onDark = bgColor != null && _isColorDark(bgColor);
  final effectiveBase = onDark ? Colors.white70 : baseColor;
  final effectiveBold = onDark ? Colors.white : boldColor;

  final col = Column(
    crossAxisAlignment: crossAlign,
    children: section.fields.asMap().entries.map<Widget>((entry) {
      final i = entry.key;
      final f = entry.value;
      // Le statut est affiché via le chip hardcodé dans chaque layout — jamais via _renderSection
      if (f.source == FieldSource.invoiceStatus) return const SizedBox.shrink();
      final text = _fieldValue(f, profile);
      final isEditing = onFieldTap != null && sectionId != null;
      if (text.isEmpty && !isEditing) return const SizedBox.shrink();
      final fg = f.textColor != null
          ? Color(f.textColor!)
          : (f.bold ? effectiveBold : effectiveBase);
      Widget w = text.isEmpty
          ? Text(
              '(${f.source.displayName})',
              textAlign: tAlign,
              style: TextStyle(
                fontSize: f.large ? baseFontSize + 3 : baseFontSize,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade400,
              ),
            )
          : Text(
              text,
              textAlign: tAlign,
              overflow: overflow,
              style: TextStyle(
                fontSize: f.large ? baseFontSize + 3 : baseFontSize,
                fontWeight: f.bold ? FontWeight.bold : FontWeight.normal,
                color: fg,
              ),
            );
      if (isEditing) {
        w = GestureDetector(
          onTap: () => onFieldTap(sectionId, i, f),
          child: w,
        );
      }
      return w;
    }).toList(),
  );

  if (bgColor != null) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: col,
    );
  }
  return col;
}

Widget _footerSection(
    TemplateSectionModel section, Color accent, PreviewProfile profile, {
    OnInlineFieldTap? onFieldTap,
}) {
  final tAlign = _textAlign(section.alignment);
  final crossAlign = _crossAlign(section.alignment);
  final bgColor =
      section.backgroundColor != null ? Color(section.backgroundColor!) : null;
  final onDark = bgColor != null && _isColorDark(bgColor);

  final content = Column(
    crossAxisAlignment: crossAlign,
    children: [
      Divider(color: Colors.grey.shade200, thickness: 0.5),
      const SizedBox(height: 4),
      if (section.isEmpty) ...[
        Text('Merci pour votre confiance.',
            style: TextStyle(
                fontSize: 8,
                color: onDark ? Colors.white70 : Colors.grey.shade400),
            textAlign: TextAlign.center),
      ] else
        ...section.fields.asMap().entries.map<Widget>((entry) {
          final i = entry.key;
          final f = entry.value;
          final text = _fieldValue(f, profile);
          if (text.isEmpty && onFieldTap == null) return const SizedBox.shrink();
          final fg = f.textColor != null
              ? Color(f.textColor!)
              : (onDark ? Colors.white70 : Colors.grey.shade500);
          Widget w = text.isEmpty
              ? Text(
                  '(${f.source.displayName})',
                  textAlign: tAlign,
                  style: TextStyle(
                    fontSize: f.large ? 11 : 8,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade400,
                  ),
                )
              : Text(
                  text,
                  textAlign: tAlign,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: f.large ? 11 : 8,
                    fontWeight: f.bold ? FontWeight.bold : FontWeight.normal,
                    color: fg,
                  ),
                );
          if (onFieldTap != null) {
            w = GestureDetector(
              onTap: () => onFieldTap(TemplateSectionId.bottomCenter, i, f),
              child: w,
            );
          }
          return w;
        }),
      const SizedBox(height: 2),
      Text('Document généré par PayRappel',
          style: TextStyle(
              fontSize: 7,
              color: onDark ? Colors.white38 : Colors.grey.shade300),
          textAlign: TextAlign.center),
    ],
  );

  if (bgColor != null) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: content,
    );
  }
  return content;
}

Widget _sectionLabel(String text) => Text(
      text,
      style: const TextStyle(
          fontSize: 7,
          color: Color(0xFF9AA0A6),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8),
    );

Widget _bold(String text, {double size = 11}) => Text(
      text,
      style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF202124)),
    );

Widget _grey(String text) => Text(
      text,
      style: const TextStyle(fontSize: 9, color: Color(0xFF5F6368)),
    );

Widget _metaRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label : ',
              style: const TextStyle(fontSize: 9, color: Color(0xFF9AA0A6))),
          Flexible(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202124))),
          ),
        ],
      ),
    );
