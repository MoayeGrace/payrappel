import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/invoice_template_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../providers/business_profile_provider.dart';
import '../../providers/invoice_template_provider.dart';
import 'template_preview_widget.dart';

class TemplateEditorScreen extends StatefulWidget {
  final InvoiceTemplateModel template;

  const TemplateEditorScreen({super.key, required this.template});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late InvoiceTemplateModel _template;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _tableDescCtrl;
  late final TextEditingController _tableQtyCtrl;
  late final TextEditingController _tablePriceCtrl;
  late final TextEditingController _tableTotalCtrl;
  final ScrollController _scrollCtrl = ScrollController();
  bool _saving = false;

  // One GlobalKey per section — used by the live preview to scroll-to-section.
  final Map<TemplateSectionId, GlobalKey> _sectionKeys = {
    for (final id in TemplateSectionId.values) id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _template = widget.template;
    final suffix = _template.isBuiltIn ? ' (Copie)' : '';
    _nameCtrl = TextEditingController(text: '${_template.name}$suffix');
    _tableDescCtrl = TextEditingController(text: _template.tableDescLabel);
    _tableQtyCtrl = TextEditingController(text: _template.tableQtyLabel);
    _tablePriceCtrl = TextEditingController(text: _template.tablePriceLabel);
    _tableTotalCtrl = TextEditingController(text: _template.tableTotalLabel);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tableDescCtrl.dispose();
    _tableQtyCtrl.dispose();
    _tablePriceCtrl.dispose();
    _tableTotalCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToSection(TemplateSectionId id) {
    final key = _sectionKeys[id];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donnez un nom à votre template')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final toSave = InvoiceTemplateModel(
        id: _template.id,
        name: name,
        isBuiltIn: _template.isBuiltIn,
        accentColor: _template.accentColor,
        headerBgColor: _template.headerBgColor,
        layout: _template.layout,
        titleLabel: _template.titleLabel,
        showLogo: _template.showLogo,
        showPaymentMethods: _template.showPaymentMethods,
        selectedPaymentMethodIds: _template.selectedPaymentMethodIds,
        topCenter: _template.topCenter,
        topLeft: _template.topLeft,
        topRight: _template.topRight,
        bottomLeft: _template.bottomLeft,
        bottomRight: _template.bottomRight,
        bottomCenter: _template.bottomCenter,
        tableDescLabel: _template.tableDescLabel,
        tableQtyLabel: _template.tableQtyLabel,
        tablePriceLabel: _template.tablePriceLabel,
        tableTotalLabel: _template.tableTotalLabel,
        tableShowQty: _template.tableShowQty,
        tableShowUnitPrice: _template.tableShowUnitPrice,
      );
      await context.read<InvoiceTemplateProvider>().saveCustomTemplate(toSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template enregistré')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: Text(
          _template.isBuiltIn ? 'Personnaliser le template' : 'Modifier le template',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Enregistrer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Prévisualisation live (fixe, toujours visible) ─────────────
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _LivePreviewCard(
              template: _template,
              onTapSection: _scrollToSection,
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // ── Options (défilables) ───────────────────────────────────────
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
          // ── Nom ──────────────────────────────────────────────────────────
          _SectionHeader('Nom du template'),
          _Card(
            child: TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Facture Entreprise Pro',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Style ─────────────────────────────────────────────────────────
          _SectionHeader('Style visuel'),
          _Card(
            child: Column(
              children: [
                _LabeledRow(
                  label: 'Mise en page',
                  child: _LayoutPicker(
                    value: _template.layout,
                    onChanged: (v) => setState(() =>
                        _template = _template.copyWith(layout: v)),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Couleur principale',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(height: 10),
                      _ColorPicker(
                        value: _template.accentColor,
                        onChanged: (v) => setState(
                            () => _template =
                                _template.copyWith(accentColor: v)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _LabeledRow(
                  label: 'Libellé du document',
                  child: _TitlePicker(
                    value: _template.titleLabel,
                    onChanged: (v) => setState(
                        () => _template = _template.copyWith(titleLabel: v)),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text('Afficher le logo',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  value: _template.showLogo,
                  activeColor: const Color(0xFF1A73E8),
                  onChanged: (v) =>
                      setState(() => _template = _template.copyWith(showLogo: v)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text('Afficher les moyens de paiement',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: const Text('Affichés en bas de la facture',
                      style: TextStyle(fontSize: 11)),
                  value: _template.showPaymentMethods,
                  activeColor: const Color(0xFF1A73E8),
                  onChanged: (v) => setState(
                      () => _template = _template.copyWith(showPaymentMethods: v)),
                ),
                if (_template.showPaymentMethods) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Consumer<BusinessProfileProvider>(
                    builder: (_, profileProv, __) {
                      final methods = profileProv.profile.paymentMethods
                          .where((m) => m.isEnabled)
                          .toList();
                      if (methods.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aucun moyen de paiement configuré. Allez dans Paramètres → Moyens de paiement.',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ),
                          ]),
                        );
                      }
                      final selected = _template.selectedPaymentMethodIds.toSet();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('Choisir les méthodes à afficher',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ),
                          ...methods.map((m) {
                            final isChecked = selected.isEmpty || selected.contains(m.id);
                            return _PaymentMethodCheckTile(
                              method: m,
                              checked: isChecked,
                              onChanged: (v) {
                                final newSelected = Set<String>.from(selected.isEmpty
                                    ? methods.map((x) => x.id)
                                    : selected);
                                if (v) { newSelected.add(m.id); } else { newSelected.remove(m.id); }
                                setState(() => _template = _template.copyWith(
                                    selectedPaymentMethodIds: newSelected.toList()));
                              },
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Tableau des prestations ───────────────────────────────────────
          _SectionHeader('Tableau des prestations'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text('Colonne Quantité',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: const Text('Afficher la colonne Qté dans le tableau',
                      style: TextStyle(fontSize: 11)),
                  value: _template.tableShowQty,
                  activeColor: const Color(0xFF1A73E8),
                  onChanged: (v) => setState(
                      () => _template = _template.copyWith(tableShowQty: v)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text('Colonne Prix unitaire',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: const Text('Afficher la colonne Prix unit. dans le tableau',
                      style: TextStyle(fontSize: 11)),
                  value: _template.tableShowUnitPrice,
                  activeColor: const Color(0xFF1A73E8),
                  onChanged: (v) => setState(
                      () => _template = _template.copyWith(tableShowUnitPrice: v)),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tableDescCtrl,
                  decoration: const InputDecoration(
                    labelText: 'En-tête : Description',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => setState(() => _template = _template.copyWith(
                      tableDescLabel: v.trim().isEmpty ? 'Description' : v.trim())),
                ),
                const SizedBox(height: 8),
                if (_template.tableShowQty) ...[
                  TextFormField(
                    controller: _tableQtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'En-tête : Quantité',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => setState(() => _template = _template.copyWith(
                        tableQtyLabel: v.trim().isEmpty ? 'Qté' : v.trim())),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_template.tableShowUnitPrice) ...[
                  TextFormField(
                    controller: _tablePriceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'En-tête : Prix unitaire',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => setState(() => _template = _template.copyWith(
                        tablePriceLabel:
                            v.trim().isEmpty ? 'Prix unit.' : v.trim())),
                  ),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: _tableTotalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'En-tête : Total',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => setState(() => _template = _template.copyWith(
                      tableTotalLabel: v.trim().isEmpty ? 'Montant' : v.trim())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Sections ──────────────────────────────────────────────────────
          _SectionHeader('Contenu des sections'),
          ..._buildSectionEditors(cs),

          const SizedBox(height: 32),
        ],
      ),
    ),
  ],
),
    );
  }

  List<Widget> _buildSectionEditors(ColorScheme cs) {
    final sections = [
      ('En-tête centre', _template.topCenter, TemplateSectionId.topCenter),
      ('En-tête gauche', _template.topLeft, TemplateSectionId.topLeft),
      ('En-tête droite', _template.topRight, TemplateSectionId.topRight),
      ('Bas gauche', _template.bottomLeft, TemplateSectionId.bottomLeft),
      ('Bas droite', _template.bottomRight, TemplateSectionId.bottomRight),
      ('Pied de page', _template.bottomCenter, TemplateSectionId.bottomCenter),
    ];

    return sections.map(((String label, TemplateSectionModel section, TemplateSectionId id) rec) {
      final (label, section, id) = rec;
      return Padding(
        key: _sectionKeys[id],
        padding: const EdgeInsets.only(bottom: 10),
        child: _SectionEditor(
          label: label,
          section: section,
          onChanged: (updated) => setState(() {
            _template = switch (id) {
              TemplateSectionId.topCenter =>
                _template.copyWith(topCenter: updated),
              TemplateSectionId.topLeft =>
                _template.copyWith(topLeft: updated),
              TemplateSectionId.topRight =>
                _template.copyWith(topRight: updated),
              TemplateSectionId.bottomLeft =>
                _template.copyWith(bottomLeft: updated),
              TemplateSectionId.bottomRight =>
                _template.copyWith(bottomRight: updated),
              TemplateSectionId.bottomCenter =>
                _template.copyWith(bottomCenter: updated),
            };
          }),
        ),
      );
    }).toList();
  }
}

enum TemplateSectionId {
  topCenter, topLeft, topRight, bottomLeft, bottomRight, bottomCenter
}

// ── Section editor ────────────────────────────────────────────────────────────

class _SectionEditor extends StatefulWidget {
  final String label;
  final TemplateSectionModel section;
  final ValueChanged<TemplateSectionModel> onChanged;

  const _SectionEditor({
    required this.label,
    required this.section,
    required this.onChanged,
  });

  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  Text(
                    '${widget.section.fields.length} champ(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            // Alignment
            Row(
              children: [
                const Text('Alignement : ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                _AlignmentToggle(
                  value: widget.section.alignment,
                  onChanged: (a) =>
                      widget.onChanged(widget.section.copyWith(alignment: a)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fields
            ...widget.section.fields.asMap().entries.map((entry) {
              final i = entry.key;
              final field = entry.value;
              return _FieldRow(
                field: field,
                onChanged: (updated) {
                  final newFields = List<TemplateFieldConfig>.from(
                      widget.section.fields);
                  newFields[i] = updated;
                  widget.onChanged(
                      widget.section.copyWith(fields: newFields));
                },
                onDelete: () {
                  final newFields = List<TemplateFieldConfig>.from(
                      widget.section.fields)
                    ..removeAt(i);
                  widget.onChanged(
                      widget.section.copyWith(fields: newFields));
                },
              );
            }),
            // Add field button
            TextButton.icon(
              onPressed: () {
                final newFields = List<TemplateFieldConfig>.from(
                    widget.section.fields)
                  ..add(const TemplateFieldConfig(source: FieldSource.manual));
                widget.onChanged(widget.section.copyWith(fields: newFields));
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter un champ', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Field row ──────────────────────────────────────────────────────────────────

class _FieldRow extends StatefulWidget {
  final TemplateFieldConfig field;
  final ValueChanged<TemplateFieldConfig> onChanged;
  final VoidCallback onDelete;

  const _FieldRow({
    required this.field,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  late TextEditingController _labelCtrl;
  late TextEditingController _valueCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.field.label ?? '');
    _valueCtrl =
        TextEditingController(text: widget.field.manualValue ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isManual = widget.field.source == FieldSource.manual;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.field.source.name,
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: FieldSource.values
                      .map((s) => DropdownMenuItem(
                            value: s.name,
                            child: Text(s.displayName,
                                style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final src = FieldSource.values
                        .firstWhere((s) => s.name == v);
                    widget.onChanged(widget.field.copyWith(source: src));
                  },
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red[300],
                onPressed: widget.onDelete,
                tooltip: 'Supprimer',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Label prefix
          TextFormField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Préfixe (optionnel)',
              hintText: 'Ex: Émise le',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (v) =>
                widget.onChanged(widget.field.copyWith(label: v.isEmpty ? null : v)),
          ),
          if (isManual) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _valueCtrl,
              decoration: const InputDecoration(
                labelText: 'Texte',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) => widget.onChanged(
                  widget.field.copyWith(manualValue: v.isEmpty ? null : v)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _CheckChip(
                label: 'Gras',
                value: widget.field.bold,
                onChanged: (v) =>
                    widget.onChanged(widget.field.copyWith(bold: v)),
              ),
              const SizedBox(width: 6),
              _CheckChip(
                label: 'Grand',
                value: widget.field.large,
                onChanged: (v) =>
                    widget.onChanged(widget.field.copyWith(large: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _CheckChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckChip(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: value,
      onSelected: onChanged,
      selectedColor: const Color(0xFF1A73E8).withOpacity(0.15),
      checkmarkColor: const Color(0xFF1A73E8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _AlignmentToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _AlignmentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AlignBtn(icon: Icons.format_align_left, align: 'left',
            selected: value == 'left', onTap: () => onChanged('left')),
        _AlignBtn(icon: Icons.format_align_center, align: 'center',
            selected: value == 'center', onTap: () => onChanged('center')),
        _AlignBtn(icon: Icons.format_align_right, align: 'right',
            selected: value == 'right', onTap: () => onChanged('right')),
      ],
    );
  }
}

class _AlignBtn extends StatelessWidget {
  final IconData icon;
  final String align;
  final bool selected;
  final VoidCallback onTap;

  const _AlignBtn({
    required this.icon,
    required this.align,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1A73E8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? blue : Colors.grey.shade300, width: 1),
        ),
        child: Icon(icon, size: 14, color: selected ? blue : Colors.grey),
      ),
    );
  }
}

class _LayoutPicker extends StatelessWidget {
  final TemplateLayout value;
  final ValueChanged<TemplateLayout> onChanged;

  const _LayoutPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<TemplateLayout>(
      value: value,
      underline: const SizedBox(),
      isDense: true,
      items: const [
        DropdownMenuItem(
            value: TemplateLayout.classic, child: Text('Classique')),
        DropdownMenuItem(
            value: TemplateLayout.modern, child: Text('Moderne')),
        DropdownMenuItem(
            value: TemplateLayout.minimal, child: Text('Minimaliste')),
        DropdownMenuItem(
            value: TemplateLayout.bold, child: Text('Audacieux')),
      ],
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _TitlePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TitlePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = ['FACTURE', 'DEVIS', 'BON DE COMMANDE', 'PROFORMA', 'REÇU'];
    return DropdownButton<String>(
      value: options.contains(value) ? value : 'FACTURE',
      underline: const SizedBox(),
      isDense: true,
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ColorPicker({required this.value, required this.onChanged});

  static const _palette = [
    0xFF1A73E8, 0xFF00897B, 0xFF546E7A, 0xFF8B1A1A,
    0xFF3949AB, 0xFF2E7D32, 0xFFE65100, 0xFF1A237E,
    0xFF37474F, 0xFFF9A825, 0xFF0097A7, 0xFFAD1457,
    0xFF424242, 0xFF1B5E20, 0xFF1565C0,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: _palette.map((c) {
        final selected = c == value;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Color(c).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared layout widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ── Live preview card ─────────────────────────────────────────────────────────

class _LivePreviewCard extends StatelessWidget {
  final InvoiceTemplateModel template;
  final void Function(TemplateSectionId id)? onTapSection;

  const _LivePreviewCard({required this.template, this.onTapSection});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 190,
        child: AspectRatio(
          aspectRatio: 0.72,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TemplateMiniPreview(template: template),
                if (onTapSection != null)
                  Positioned.fill(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 55,
                          child: _TapZone(
                            label: 'En-tête',
                            labelAlign: Alignment.topRight,
                            onTap: () => onTapSection!(TemplateSectionId.topCenter),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 35,
                          child: _TapZone(
                            label: 'Pied de page',
                            labelAlign: Alignment.bottomRight,
                            onTap: () => onTapSection!(TemplateSectionId.bottomCenter),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TapZone extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Alignment labelAlign;

  const _TapZone({
    required this.label,
    required this.onTap,
    this.labelAlign = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: labelAlign,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 7, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Payment method check tile ─────────────────────────────────────────────────

class _PaymentMethodCheckTile extends StatelessWidget {
  final PaymentMethodModel method;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const _PaymentMethodCheckTile({
    required this.method,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = method.type.color;
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: method.type.assetPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(method.type.assetPath!, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(method.type.icon, size: 16, color: color)),
                    )
                  : Icon(method.type.icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(method.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Checkbox(
              value: checked,
              activeColor: const Color(0xFF1A73E8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => onChanged(v ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Labeled row ───────────────────────────────────────────────────────────────

class _LabeledRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          child,
        ],
      ),
    );
  }
}
