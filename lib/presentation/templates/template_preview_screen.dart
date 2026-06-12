import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/business_profile_model.dart';
import '../../data/models/invoice_template_model.dart';
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
            icon: Icon(Icons.tune_outlined,
                color: _contrastColor(accent), size: 18),
            label: Text('Éditer',
                style: TextStyle(
                    color: _contrastColor(accent),
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Bandeau layout + couleur
          Container(
            color: accent.withOpacity(0.1),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _LayoutChip(label: _layoutLabel(template.layout), color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aperçu avec données de démonstration',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
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
          // Zone preview zoomable
          Expanded(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 4.0,
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Consumer<BusinessProfileProvider>(
                    builder: (_, prov, __) => InvoiceDocPreview(
                      template: template,
                      accent: accent,
                      headerBg: headerBg,
                      profile: PreviewProfile.from(prov.profile),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bouton "Personnaliser"
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

// ── Document preview ──────────────────────────────────────────────────────────

class InvoiceDocPreview extends StatelessWidget {
  final InvoiceTemplateModel template;
  final Color accent;
  final Color headerBg;
  final PreviewProfile profile;
  final double elevation;

  const InvoiceDocPreview({
    super.key,
    required this.template,
    required this.accent,
    required this.headerBg,
    required this.profile,
    this.elevation = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: switch (template.layout) {
          TemplateLayout.classic =>
            _ClassicDoc(accent: accent, template: template, profile: profile),
          TemplateLayout.modern =>
            _ModernDoc(accent: accent, headerBg: headerBg, template: template, profile: profile),
          TemplateLayout.minimal =>
            _MinimalDoc(accent: accent, template: template, profile: profile),
          TemplateLayout.bold =>
            _BoldDoc(accent: accent, headerBg: headerBg, template: template, profile: profile),
        },
      ),
    );
  }
}

// ── Classic document ──────────────────────────────────────────────────────────

class _ClassicDoc extends StatelessWidget {
  final Color accent;
  final InvoiceTemplateModel template;
  final PreviewProfile profile;
  const _ClassicDoc({required this.accent, required this.template, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête redesigné : bordure gauche accent ─────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(5),
              border: Border(
                left: BorderSide(color: accent, width: 3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gauche : logo + société
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
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(Icons.business, color: accent, size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: template.topLeft.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _bold(profile.companyName, size: 12),
                                  if (profile.address.isNotEmpty)
                                    _grey(profile.address),
                                  if (profile.phone.isNotEmpty)
                                    _grey(profile.phone),
                                ],
                              )
                            : _renderSection(template.topLeft, profile,
                                boldColor: const Color(0xFF202124),
                                baseFontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Droite : badge titre + numéro + méta
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
                            color: TemplatePreviewScreen._contrastColor(accent),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'N° FAC-2026-A3B4C5',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: accent),
                    ),
                    const SizedBox(height: 3),
                    if (template.topRight.isEmpty) ...[
                      _metaRow('Émise le', '01/01/2026'),
                      _metaRow('Échéance', '31/01/2026'),
                    ] else
                      _renderSection(template.topRight, profile,
                          baseFontSize: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Parties
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _partyBox(
                    title: 'ÉMETTEUR',
                    name: profile.companyName,
                    lines: [
                      if (profile.address.isNotEmpty) profile.address,
                      if (profile.phone.isNotEmpty) profile.phone,
                    ],
                    bg: accent.withOpacity(0.07),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _partyBox(
                    title: 'CLIENT',
                    name: 'Jean Dupont',
                    lines: const ['+225 05 00 00 00'],
                    bg: const Color(0xFFF8F9FA),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(child: _invoiceInfoBox(accent)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _tablePreview(template, accent),
          _amountsBox(accent),
          if (template.showPaymentMethods) _paymentMethodsHint(accent),
          const SizedBox(height: 14),
          _footerSection(template.bottomCenter, accent, profile),
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
  const _ModernDoc({required this.accent, required this.headerBg, required this.template, required this.profile});

  @override
  Widget build(BuildContext context) {
    final textOnHeader = TemplatePreviewScreen._contrastColor(headerBg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bandeau coloré pleine largeur
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
                  child: Icon(Icons.business,
                      color: Colors.white.withOpacity(0.85), size: 22),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
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
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                          color: textOnHeader.withOpacity(0.7), fontSize: 9)),
                  Text('Éch. : 31/01/2026',
                      style: TextStyle(
                          color: textOnHeader.withOpacity(0.7), fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
        // Corps
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _partyBox(
                        title: 'CLIENT',
                        name: 'Jean Dupont',
                        lines: const ['+225 05 00 00 00'],
                        bg: const Color(0xFFF8F9FA),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _invoiceInfoBox(accent)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _tablePreview(template, accent),
              _amountsBox(accent),
              if (template.showPaymentMethods) _paymentMethodsHint(accent),
              const SizedBox(height: 14),
              _footerSection(template.bottomCenter, accent, profile),
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
  const _MinimalDoc({required this.accent, required this.template, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : nom + FACTURE en couleur accent
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bold(profile.companyName, size: 14),
                    if (profile.phone.isNotEmpty) _grey(profile.phone),
                    if (profile.email.isNotEmpty) _grey(profile.email),
                  ],
                ),
              ),
              Text(
                template.titleLabel,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1.5, color: accent),
          const SizedBox(height: 12),
          // Détails : infos facture | client côte à côte
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('FACTURE'),
                      const SizedBox(height: 3),
                      _bold('Facture Janv. 2026', size: 11),
                      const SizedBox(height: 2),
                      Text('N° FAC-2026-A3B4C5',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: accent)),
                      const SizedBox(height: 4),
                      _metaRow('Émise', '01/01/2026'),
                      _metaRow('Échéance', '31/01/2026'),
                      _metaRow('Statut', 'En cours'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('CLIENT'),
                      const SizedBox(height: 3),
                      _bold('Jean Dupont', size: 11),
                      _grey('+225 05 00 00 00'),
                      _grey('jean@email.com'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200, thickness: 0.5),
          const SizedBox(height: 10),
          _tablePreview(template, accent),
          _amountsBox(accent),
          if (template.showPaymentMethods) _paymentMethodsHint(accent),
          const SizedBox(height: 14),
          _footerSection(template.bottomCenter, accent, profile),
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
  const _BoldDoc(
      {required this.accent,
      required this.headerBg,
      required this.template,
      required this.profile});

  @override
  Widget build(BuildContext context) {
    final textOnHeader = TemplatePreviewScreen._contrastColor(headerBg);
    final topTitle = template.topCenter.fields.isNotEmpty
        ? (template.topCenter.fields.first.manualValue ??
            template.titleLabel)
        : template.titleLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bandeau épais
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
                child: Icon(Icons.business,
                    color: Colors.white.withOpacity(0.85), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  topTitle.toUpperCase(),
                  style: TextStyle(
                      color: textOnHeader,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                          color: textOnHeader.withOpacity(0.7), fontSize: 8)),
                ],
              ),
            ],
          ),
        ),
        // Barre accent
        Container(
          height: 4,
          color: accent.withOpacity(
              accent.computeLuminance() > 0.5 ? 0.7 : 0.5),
        ),
        // Corps
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _partyBox(
                        title: 'ÉMETTEUR',
                        name: profile.companyName,
                        lines: [
                          if (profile.address.isNotEmpty) profile.address,
                          if (profile.phone.isNotEmpty) profile.phone,
                        ],
                        bg: accent.withOpacity(0.07),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _partyBox(
                        title: 'CLIENT',
                        name: 'Jean Dupont',
                        lines: const ['+225 05 00 00 00'],
                        bg: const Color(0xFFF8F9FA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _tablePreview(template, accent),
              _amountsBox(accent),
              if (template.showPaymentMethods) _paymentMethodsHint(accent),
              const SizedBox(height: 14),
              _footerSection(template.bottomCenter, accent, profile),
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

Widget _paymentMethodsHint(Color accent) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Icon(Icons.payment_outlined, size: 9, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text('Moyens de paiement',
            style: TextStyle(fontSize: 7, color: Colors.grey.shade400)),
      ],
    ),
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
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(5)),
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

Widget _invoiceInfoBox(Color accent) {
  return Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('FACTURE'),
        const SizedBox(height: 3),
        _bold('Facture Janv. 2026', size: 10),
        const SizedBox(height: 2),
        Text('N° FAC-2026-A3B4C5',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: accent)),
        const SizedBox(height: 3),
        _metaRow('Émise', '01/01/2026'),
        _metaRow('Éch.', '31/01/2026'),
      ],
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
            child: _amountTile('Montant total', '150 000 FCFA',
                const Color(0xFF202124))),
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
    FieldSource.companyRccm => 'RC/ABJ/2024/001',
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
    children: section.fields.map<Widget>((f) {
      final text = _fieldValue(f, profile);
      if (text.isEmpty) return const SizedBox.shrink();
      final fg = f.textColor != null
          ? Color(f.textColor!)
          : (f.bold ? effectiveBold : effectiveBase);
      return Text(
        text,
        textAlign: tAlign,
        overflow: overflow,
        style: TextStyle(
          fontSize: f.large ? baseFontSize + 3 : baseFontSize,
          fontWeight: f.bold ? FontWeight.bold : FontWeight.normal,
          color: fg,
        ),
      );
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
    TemplateSectionModel section, Color accent, PreviewProfile profile) {
  final tAlign = _textAlign(section.alignment);
  final crossAlign = _crossAlign(section.alignment);
  return Column(
    crossAxisAlignment: crossAlign,
    children: [
      Divider(color: Colors.grey.shade200, thickness: 0.5),
      const SizedBox(height: 4),
      if (section.isEmpty) ...[
        Text('Ma Banque — Compte 123456789',
            style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text('Merci pour votre confiance.',
            style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
            textAlign: TextAlign.center),
      ] else
        ...section.fields.map<Widget>((f) {
          final text = _fieldValue(f, profile);
          if (text.isEmpty) return const SizedBox.shrink();
          return Text(
            text,
            textAlign: tAlign,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: f.large ? 11 : 8,
              fontWeight: f.bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade500,
            ),
          );
        }),
      const SizedBox(height: 2),
      Text('Document généré par PayRappel',
          style: TextStyle(fontSize: 7, color: Colors.grey.shade300),
          textAlign: TextAlign.center),
    ],
  );
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
