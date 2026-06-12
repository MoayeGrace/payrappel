import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/invoice_template_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../providers/business_profile_provider.dart';
import '../../providers/invoice_template_provider.dart';
import 'template_preview_screen.dart';

class TemplateEditorScreen extends StatefulWidget {
  final InvoiceTemplateModel template;

  const TemplateEditorScreen({super.key, required this.template});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen>
    with SingleTickerProviderStateMixin {
  late InvoiceTemplateModel _template;
  late final TextEditingController _nameCtrl;
  late final TabController _tabCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _template = widget.template;
    final suffix = _template.isBuiltIn ? ' (Copie)' : '';
    _nameCtrl = TextEditingController(text: '${_template.name}$suffix');
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
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
      await context
          .read<InvoiceTemplateProvider>()
          .saveCustomTemplate(_template.copyWith(name: name));
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
    final accent = Color(_template.accentColor);
    final headerBg = _template.headerBgColor != null
        ? Color(_template.headerBgColor!)
        : accent;

    return Scaffold(
      backgroundColor: const Color(0xFFDDE1E7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: accent,
        foregroundColor: Colors.white,
        title: TextField(
          controller: _nameCtrl,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Nom du template',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Enregistrer',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Aperçu live (feuille document, occupe ~55% de l'écran) ───────
          Expanded(
            flex: 55,
            child: Consumer<BusinessProfileProvider>(
              builder: (_, prov, __) {
                final profile = PreviewProfile.from(prov.profile);
                return Container(
                  color: const Color(0xFFDDE1E7),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.94,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 380,
                          child: InvoiceDocPreview(
                            key: ObjectKey(_template),
                            template: _template,
                            accent: accent,
                            headerBg: headerBg,
                            profile: profile,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Panneau d'édition avec onglets (bas ~45%) ─────────────────────
          Expanded(
            flex: 45,
            child: Material(
              elevation: 8,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabCtrl,
                        labelColor: accent,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: accent,
                        labelStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                        unselectedLabelStyle:
                            const TextStyle(fontSize: 11),
                        tabs: const [
                          Tab(icon: Icon(Icons.palette_outlined, size: 17), text: 'Style'),
                          Tab(icon: Icon(Icons.view_list_outlined, size: 17), text: 'Sections'),
                          Tab(icon: Icon(Icons.table_chart_outlined, size: 17), text: 'Tableau'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          // ── Tab 0 : Style ──────────────────────────────
                          _buildStyleTab(accent),
                          // ── Tab 1 : Sections ───────────────────────────
                          _buildSectionsTab(context),
                          // ── Tab 2 : Tableau ────────────────────────────
                          _buildTableTab(accent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _Card(
          child: Column(
            children: [
              _LabeledRow(
                label: 'Mise en page',
                child: _LayoutPicker(
                  value: _template.layout,
                  onChanged: (v) =>
                      setState(() => _template = _template.copyWith(layout: v)),
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
                contentPadding: EdgeInsets.zero,
                title: const Text('Afficher le logo',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                value: _template.showLogo,
                activeColor: accent,
                onChanged: (v) =>
                    setState(() => _template = _template.copyWith(showLogo: v)),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Moyens de paiement',
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                subtitle: const Text('Affichés en bas de la facture',
                    style: TextStyle(fontSize: 11)),
                value: _template.showPaymentMethods,
                activeColor: accent,
                onChanged: (v) => setState(
                    () =>
                        _template = _template.copyWith(showPaymentMethods: v)),
              ),
              if (_template.showPaymentMethods) ...[
                const Divider(height: 1),
                const SizedBox(height: 6),
                Consumer<BusinessProfileProvider>(
                  builder: (_, profileProv, __) {
                    final methods = profileProv.profile.paymentMethods
                        .where((m) => m.isEnabled)
                        .toList();
                    if (methods.isEmpty) {
                      return Text(
                        'Aucun moyen de paiement configuré.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      );
                    }
                    final selected =
                        _template.selectedPaymentMethodIds.toSet();
                    return Column(
                      children: methods.map((m) {
                        final isChecked =
                            selected.isEmpty || selected.contains(m.id);
                        return _PaymentMethodCheckTile(
                          method: m,
                          checked: isChecked,
                          onChanged: (v) {
                            final ns = Set<String>.from(selected.isEmpty
                                ? methods.map((x) => x.id)
                                : selected);
                            if (v) { ns.add(m.id); } else { ns.remove(m.id); }
                            setState(() => _template = _template.copyWith(
                                selectedPaymentMethodIds: ns.toList()));
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Couleur principale',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 10),
              _ColorPicker(
                value: _template.accentColor,
                onChanged: (v) =>
                    setState(() => _template = _template.copyWith(accentColor: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionsTab(BuildContext context) {
    const sectionMeta = [
      ('En-tête centre', TemplateSectionId.topCenter),
      ('En-tête gauche', TemplateSectionId.topLeft),
      ('En-tête droite', TemplateSectionId.topRight),
      ('Bas gauche', TemplateSectionId.bottomLeft),
      ('Bas droite', TemplateSectionId.bottomRight),
      ('Pied de page', TemplateSectionId.bottomCenter),
    ];

    TemplateSectionModel getSection(TemplateSectionId id) => switch (id) {
          TemplateSectionId.topCenter => _template.topCenter,
          TemplateSectionId.topLeft => _template.topLeft,
          TemplateSectionId.topRight => _template.topRight,
          TemplateSectionId.bottomLeft => _template.bottomLeft,
          TemplateSectionId.bottomRight => _template.bottomRight,
          TemplateSectionId.bottomCenter => _template.bottomCenter,
        };

    InvoiceTemplateModel setSection(
            InvoiceTemplateModel t, TemplateSectionId id,
            TemplateSectionModel s) =>
        switch (id) {
          TemplateSectionId.topCenter => t.copyWith(topCenter: s),
          TemplateSectionId.topLeft => t.copyWith(topLeft: s),
          TemplateSectionId.topRight => t.copyWith(topRight: s),
          TemplateSectionId.bottomLeft => t.copyWith(bottomLeft: s),
          TemplateSectionId.bottomRight => t.copyWith(bottomRight: s),
          TemplateSectionId.bottomCenter => t.copyWith(bottomCenter: s),
        };

    void swapSections(TemplateSectionId a, TemplateSectionId b) {
      final sA = getSection(a);
      final sB = getSection(b);
      setState(() => _template = setSection(setSection(_template, a, sB), b, sA));
    }

    Future<void> showSwapDialog(
        String label, TemplateSectionId sourceId) async {
      final others = sectionMeta.where((e) => e.$2 != sourceId).toList();
      final target = await showDialog<TemplateSectionId>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Déplacer "$label" vers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: others
                .map((e) => ListTile(
                      leading: const Icon(Icons.swap_horiz,
                          color: Color(0xFF1A73E8), size: 20),
                      title: Text(e.$1,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text('Échange le contenu des deux sections',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                      onTap: () => Navigator.pop(ctx, e.$2),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
          ],
        ),
      );
      if (target != null) swapSections(sourceId, target);
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        ...sectionMeta.map(((String label, TemplateSectionId id) rec) {
          final (label, id) = rec;
          final section = getSection(id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SectionEditor(
              label: label,
              section: section,
              onSwap: () => showSwapDialog(label, id),
              onChanged: (updated) => setState(
                  () => _template = setSection(_template, id, updated)),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTableTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _Card(
          child: _CustomTableEditor(
            key: ValueKey(
                '${_template.customTable.columnCount}x${_template.customTable.rowCount}'),
            table: _template.customTable,
            accent: accent,
            onChanged: (t) =>
                setState(() => _template = _template.copyWith(customTable: t)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
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
  final VoidCallback? onSwap;

  const _SectionEditor({
    required this.label,
    required this.section,
    required this.onChanged,
    this.onSwap,
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
          Row(
            children: [
              Expanded(
                child: InkWell(
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
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                            color: Colors.grey[500]),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.onSwap != null)
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  color: const Color(0xFF1A73E8),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Déplacer cette section',
                  onPressed: widget.onSwap,
                ),
            ],
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
            // Background color
            Row(
              children: [
                const Text('Fond : ',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                _NullableColorSwatch(
                  label: 'Couleur de fond',
                  value: widget.section.backgroundColor,
                  onChanged: (v) => widget.onChanged(widget.section.copyWith(
                      backgroundColor: v, clearBgColor: v == null)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
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
              const SizedBox(width: 10),
              _NullableColorSwatch(
                label: 'Couleur du texte',
                value: widget.field.textColor,
                onChanged: (v) => widget.onChanged(widget.field.copyWith(
                    textColor: v, clearTextColor: v == null)),
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

// ── Nullable color swatch (for field textColor / section backgroundColor) ─────

class _NullableColorSwatch extends StatelessWidget {
  final int? value;
  final String label;
  final ValueChanged<int?> onChanged;

  static const _palette = [
    0xFF1A73E8, 0xFF00897B, 0xFF546E7A, 0xFF8B1A1A,
    0xFF3949AB, 0xFF2E7D32, 0xFFE65100, 0xFF1A237E,
    0xFF37474F, 0xFFF9A825, 0xFF0097A7, 0xFFAD1457,
    0xFF424242, 0xFFFFFFFF, 0xFF000000,
  ];

  const _NullableColorSwatch(
      {required this.value, required this.onChanged, this.label = ''});

  void _show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label.isNotEmpty ? label : 'Couleur',
            style: const TextStyle(fontSize: 14)),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: SizedBox(
          width: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _palette.map((c) {
                  final sel = c == value;
                  return GestureDetector(
                    onTap: () {
                      onChanged(c);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? const Color(0xFF1A73E8) : Colors.grey.shade300,
                          width: sel ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged(null);
              Navigator.pop(context);
            },
            child: const Text('Aucune couleur',
                style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value != null ? Color(value!) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: value != null
                    ? Color(value!).withOpacity(0.6)
                    : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: value == null
                ? const Icon(Icons.palette_outlined, size: 12,
                    color: Color(0xFF9AA0A6))
                : null,
          ),
          const SizedBox(width: 4),
          Text(
            value != null ? 'Couleur' : 'Défaut',
            style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
          ),
        ],
      ),
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

// ── Custom table editor ───────────────────────────────────────────────────────

class _CustomTableEditor extends StatefulWidget {
  final TemplateCustomTable table;
  final Color accent;
  final ValueChanged<TemplateCustomTable> onChanged;

  const _CustomTableEditor({
    super.key,
    required this.table,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<_CustomTableEditor> createState() => _CustomTableEditorState();
}

class _CustomTableEditorState extends State<_CustomTableEditor> {
  final List<TextEditingController> _hCtls = [];
  final List<List<TextEditingController>> _cCtls = [];

  @override
  void initState() {
    super.initState();
    _rebuild(widget.table);
  }

  void _rebuild(TemplateCustomTable t) {
    _disposeAll();
    _hCtls.addAll(t.headers.map((h) => TextEditingController(text: h)));
    _cCtls.addAll(
      t.rows.map((row) => row.map((c) => TextEditingController(text: c)).toList()),
    );
  }

  void _disposeAll() {
    for (final c in _hCtls) { c.dispose(); }
    for (final row in _cCtls) {
      for (final c in row) { c.dispose(); }
    }
    _hCtls.clear();
    _cCtls.clear();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.table;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const colW = 105.0;
    final tableW = colW * t.columnCount;
    final divColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contrôles lignes / colonnes
        Row(
          children: [
            _counter(context, 'Colonnes', t.columnCount, 1, 6,
              () => widget.onChanged(t.removeLastColumn()),
              () => widget.onChanged(t.addColumn()),
            ),
            const SizedBox(width: 20),
            _counter(context, 'Lignes', t.rowCount, 1, 20,
              () => widget.onChanged(t.removeLastRow()),
              () => widget.onChanged(t.addRow()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tableau
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: divColor),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.hardEdge,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableW,
              child: Column(
                children: [
                  // En-tête
                  Container(
                    color: widget.accent,
                    child: Row(
                      children: List.generate(t.columnCount, (col) => _cell(
                        context, _hCtls[col],
                        isHeader: true,
                        showDivider: col < t.columnCount - 1,
                        divColor: Colors.white.withOpacity(0.3),
                        onChanged: (v) => widget.onChanged(t.updateHeader(col, v)),
                      )),
                    ),
                  ),
                  // Lignes
                  ...List.generate(t.rowCount, (row) => Container(
                    decoration: BoxDecoration(
                      color: row.isOdd
                          ? (isDark ? Colors.grey.shade800 : Colors.grey.shade50)
                          : (isDark ? const Color(0xFF1E2433) : Colors.white),
                      border: Border(top: BorderSide(color: divColor, width: 0.5)),
                    ),
                    child: Row(
                      children: List.generate(t.columnCount, (col) => _cell(
                        context, _cCtls[row][col],
                        showDivider: col < t.columnCount - 1,
                        divColor: divColor,
                        onChanged: (v) => widget.onChanged(t.updateCell(row, col, v)),
                      )),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _counter(BuildContext context, String label, int value, int min, int max,
      VoidCallback onDec, VoidCallback onInc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        _btn(Icons.remove, value > min ? onDec : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$value',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        _btn(Icons.add, value < max ? onInc : null),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    const blue = Color(0xFF1A73E8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: onTap != null ? blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14,
            color: onTap != null ? Colors.white : Colors.grey.shade500),
      ),
    );
  }

  Widget _cell(BuildContext context, TextEditingController ctl, {
    bool isHeader = false,
    bool showDivider = false,
    Color divColor = const Color(0xFFE0E0E0),
    ValueChanged<String>? onChanged,
  }) {
    return Expanded(
      child: Container(
        decoration: showDivider
            ? BoxDecoration(border: Border(right: BorderSide(color: divColor, width: 0.5)))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: TextField(
          controller: ctl,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? Colors.white : null,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: onChanged,
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
