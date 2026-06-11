import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/invoice_template_model.dart';

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
                  child: _InvoiceDocPreview(
                    template: template,
                    accent: accent,
                    headerBg: headerBg,
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

class _InvoiceDocPreview extends StatelessWidget {
  final InvoiceTemplateModel template;
  final Color accent;
  final Color headerBg;

  const _InvoiceDocPreview({
    required this.template,
    required this.accent,
    required this.headerBg,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: switch (template.layout) {
          TemplateLayout.classic => _ClassicDoc(accent: accent),
          TemplateLayout.modern =>
            _ModernDoc(accent: accent, headerBg: headerBg),
          TemplateLayout.minimal => _MinimalDoc(accent: accent),
          TemplateLayout.bold =>
            _BoldDoc(accent: accent, headerBg: headerBg, template: template),
        },
      ),
    );
  }
}

// ── Classic document ──────────────────────────────────────────────────────────

class _ClassicDoc extends StatelessWidget {
  final Color accent;
  const _ClassicDoc({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : logo placeholder + infos société | badge FACTURE + méta
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.business, color: accent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bold('Mon Entreprise', size: 13),
                          _grey('Abidjan, Plateau'),
                          _grey('+225 07 00 00 00'),
                          _grey('contact@entreprise.com'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'FACTURE',
                      style: TextStyle(
                          color: TemplatePreviewScreen._contrastColor(accent),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _metaRow('Émise le', '01/01/2026'),
                  _metaRow('Échéance', '31/01/2026'),
                  _metaRow('Statut', 'En cours'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200, thickness: 0.5),
          const SizedBox(height: 10),
          // Parties
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _partyBox(
                    title: 'ÉMETTEUR',
                    name: 'Mon Entreprise',
                    lines: const ['Abidjan, Plateau', '+225 07 00 00 00'],
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
                Expanded(child: _invoiceInfoBox()),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _amountsBox(accent),
          const SizedBox(height: 14),
          _footer(accent),
        ],
      ),
    );
  }
}

// ── Modern document ───────────────────────────────────────────────────────────

class _ModernDoc extends StatelessWidget {
  final Color accent;
  final Color headerBg;
  const _ModernDoc({required this.accent, required this.headerBg});

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mon Entreprise',
                        style: TextStyle(
                            color: textOnHeader,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    Text('Abidjan, Plateau',
                        style: TextStyle(
                            color: textOnHeader.withOpacity(0.7),
                            fontSize: 9)),
                    Text('+225 07 00 00 00',
                        style: TextStyle(
                            color: textOnHeader.withOpacity(0.7),
                            fontSize: 9)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('FACTURE',
                      style: TextStyle(
                          color: textOnHeader,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 3),
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
                    Expanded(child: _invoiceInfoBox()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _amountsBox(accent),
              const SizedBox(height: 14),
              _footer(accent),
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
  const _MinimalDoc({required this.accent});

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
                    _bold('Mon Entreprise', size: 14),
                    _grey('+225 07 00 00 00'),
                    _grey('contact@entreprise.com'),
                  ],
                ),
              ),
              Text(
                'FACTURE',
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
          _amountsBox(accent),
          const SizedBox(height: 14),
          _footer(accent),
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
  const _BoldDoc(
      {required this.accent,
      required this.headerBg,
      required this.template});

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
                        name: 'Mon Entreprise',
                        lines: const ['Abidjan, Plateau', '+225 07 00 00 00'],
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
              _amountsBox(accent),
              const SizedBox(height: 14),
              _footer(accent),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared preview widgets ────────────────────────────────────────────────────

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

Widget _invoiceInfoBox() {
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
        _bold('FAC-2026-001', size: 10),
        const SizedBox(height: 4),
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

Widget _footer(Color accent) {
  return Column(
    children: [
      Divider(color: Colors.grey.shade200, thickness: 0.5),
      const SizedBox(height: 4),
      Text('Ma Banque — Compte 123456789',
          style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
          textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text('Merci pour votre confiance.',
          style: TextStyle(fontSize: 8, color: Colors.grey.shade400),
          textAlign: TextAlign.center),
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
        children: [
          Text('$label : ',
              style: const TextStyle(fontSize: 9, color: Color(0xFF9AA0A6))),
          Text(value,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202124))),
        ],
      ),
    );
