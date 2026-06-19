import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/invoice_template_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../providers/business_profile_provider.dart';
import '../../providers/invoice_template_provider.dart';
import 'template_preview_screen.dart';

// ── Editor screen ─────────────────────────────────────────────────────────────

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
  TemplateSectionId? _selectedSection;
  bool _saving = false;
  int? _selectedFieldIndex;
  Timer? _debounceTimer;

  static const _blue = Color(0xFF1A73E8);

  static const _sectionsMeta = [
    _SectionMeta(
        id: TemplateSectionId.topLeft,
        label: 'En-tête G.',
        icon: Icons.business_outlined),
    _SectionMeta(
        id: TemplateSectionId.topRight,
        label: 'En-tête D.',
        icon: Icons.receipt_long_outlined),
    _SectionMeta(
        id: TemplateSectionId.bottomLeft,
        label: 'Client',
        icon: Icons.person_outline),
    _SectionMeta(
        id: TemplateSectionId.bottomRight,
        label: 'Champs libres',
        icon: Icons.edit_note_outlined),
    _SectionMeta(
        id: TemplateSectionId.bottomCenter,
        label: 'Pied de page',
        icon: Icons.article_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _template = widget.template;
    final suffix = _template.isBuiltIn ? ' (Copie)' : '';
    _nameCtrl = TextEditingController(text: '${_template.name}$suffix');
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
    final wasBuiltIn = _template.isBuiltIn;
    try {
      final saved = await context
          .read<InvoiceTemplateProvider>()
          .saveCustomTemplate(_template.copyWith(name: name));
      if (mounted) {
        // After saving a built-in, switch the editor state to the copy so
        // auto-save and future manual saves will update the copy, not create another.
        if (wasBuiltIn) setState(() => _template = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasBuiltIn
                ? 'Copie enregistrée dans Mes templates'
                : 'Template enregistré'),
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onSectionTap(TemplateSectionId? id) {
    setState(() {
      _selectedSection = id;
      _selectedFieldIndex = null;
      if (id != null) _tabCtrl.animateTo(2);
    });
  }

  void _onInlineFieldTap(
      TemplateSectionId sectionId, int fieldIndex, TemplateFieldConfig field) {
    setState(() {
      _selectedSection = sectionId;
      _selectedFieldIndex = fieldIndex;
    });
    _tabCtrl.animateTo(2);
  }

  void _onAddField(TemplateSectionId sectionId) {
    final section = _getSection(sectionId);
    final newFields = List<TemplateFieldConfig>.from(section.fields)
      ..add(const TemplateFieldConfig(source: FieldSource.manual));
    setState(() {
      _template = _setSection(sectionId, section.copyWith(fields: newFields));
      _selectedSection = sectionId;
      _tabCtrl.animateTo(2);
    });
    _debouncedAutoSave();
  }

  // Auto-sauvegarde avec debounce 500 ms, uniquement pour les templates custom.
  void _debouncedAutoSave() {
    if (_template.isBuiltIn) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) return;
      try {
        await context
            .read<InvoiceTemplateProvider>()
            .saveCustomTemplate(_template.copyWith(name: name));
      } catch (_) {}
    });
  }

  TemplateSectionModel _getSection(TemplateSectionId id) => switch (id) {
        TemplateSectionId.topLeft => _template.topLeft,
        TemplateSectionId.topRight => _template.topRight,
        TemplateSectionId.bottomLeft => _template.bottomLeft,
        TemplateSectionId.bottomRight => _template.bottomRight,
        TemplateSectionId.bottomCenter => _template.bottomCenter,
        _ => _template.topLeft,
      };

  InvoiceTemplateModel _setSection(
          TemplateSectionId id, TemplateSectionModel s) =>
      switch (id) {
        TemplateSectionId.topLeft => _template.copyWith(topLeft: s),
        TemplateSectionId.topRight => _template.copyWith(topRight: s),
        TemplateSectionId.bottomLeft => _template.copyWith(bottomLeft: s),
        TemplateSectionId.bottomRight => _template.copyWith(bottomRight: s),
        TemplateSectionId.bottomCenter => _template.copyWith(bottomCenter: s),
        _ => _template,
      };

  void _onTableTap() => _tabCtrl.animateTo(3);
  void _onPaymentTap() => _tabCtrl.animateTo(4);

  void _swapSections(TemplateSectionId from, TemplateSectionId to) {
    if (from == to) return;
    final a = _getSection(from);
    final b = _getSection(to);
    setState(() {
      _template = _setSection(from, b);
      _template = _setSection(to, a);
    });
    _debouncedAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_template.accentColor);
    final headerBg = _template.headerBgColor != null
        ? Color(_template.headerBgColor!)
        : accent;

    return Scaffold(
      backgroundColor: const Color(0xFFDDE1E7),
      appBar: _buildAppBar(accent),
      body: Column(
        children: [
          // ── Canvas live preview ~55% ───────────────────────────────────────
          Expanded(
            flex: 55,
            child: Consumer<BusinessProfileProvider>(
              builder: (_, prov, __) {
                final profile = PreviewProfile.from(prov.profile);
                final paymentMethods = prov.profile.paymentMethods
                    .where((m) => m.isEnabled)
                    .toList();
                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: const Color(0xFFDDE1E7),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                                  logoPath: prov.profile.logoPath,
                                  selectedSection: _selectedSection,
                                  onSectionTap: _onSectionTap,
                                  onFieldTap: _onInlineFieldTap,
                                  onAddField: _onAddField,
                                  onSectionSwap: _swapSections,
                                  paymentMethods: paymentMethods,
                                  onTableTap: _onTableTap,
                                  onPaymentTap: _onPaymentTap,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildSectionChips(accent),
                  ],
                );
              },
            ),
          ),
          // ── Quick toolbar (visible quand une section est sélectionnée) ─────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _selectedSection != null
                ? _buildQuickToolbar(accent)
                : const SizedBox.shrink(),
          ),
          // ── Panneau d'édition 6 onglets ~45% ──────────────────────────────
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
                    _buildTabBar(accent),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildDesignTab(accent),
                          _buildSectionsTab(accent),
                          _buildChampsTab(accent),
                          _buildTableauTab(accent),
                          _buildPaiementTab(accent),
                          _buildAutomatisationTab(),
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

  // ── AppBar ────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(Color accent) {
    return AppBar(
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
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
              ),
              child: const Text('Enregistrer'),
            ),
          ),
      ],
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────────

  Widget _buildTabBar(Color accent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: accent,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: accent,
        indicatorWeight: 2.5,
        dividerColor: Colors.grey[200],
        labelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.palette_outlined, size: 16), text: 'Design'),
          Tab(
              icon: Icon(Icons.view_quilt_outlined, size: 16),
              text: 'Sections'),
          Tab(
              icon: Icon(Icons.text_fields_outlined, size: 16),
              text: 'Champs'),
          Tab(
              icon: Icon(Icons.table_chart_outlined, size: 16),
              text: 'Tableau'),
          Tab(
              icon: Icon(Icons.payments_outlined, size: 16),
              text: 'Paiement'),
          Tab(
              icon: Icon(Icons.auto_awesome_outlined, size: 16),
              text: 'Auto.'),
        ],
      ),
    );
  }

  // ── Section chips (sous le document) ─────────────────────────────────────────

  Widget _buildSectionChips(Color accent) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _sectionsMeta.map((meta) {
          final isSelected = _selectedSection == meta.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => _onSectionTap(isSelected ? null : meta.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? accent : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? accent : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: accent.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meta.icon,
                        size: 12,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  // ── Quick toolbar ─────────────────────────────────────────────────────────────

  Widget _buildQuickToolbar(Color accent) {
    if (_selectedSection == null) return const SizedBox.shrink();
    final section = _getSection(_selectedSection!);
    final meta = _sectionsMeta.firstWhere(
        (m) => m.id == _selectedSection,
        orElse: () => _SectionMeta(
            id: _selectedSection!,
            label: _selectedSection!.name,
            icon: Icons.view_column_outlined));

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(meta.icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(meta.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent)),
          const SizedBox(width: 10),
          Container(width: 1, height: 18, color: Colors.grey[300]),
          const SizedBox(width: 8),
          // Alignement
          _QuickAlignBtn(
            icon: Icons.format_align_left,
            selected: section.alignment == 'left',
            accent: accent,
            onTap: () => setState(() => _template = _setSection(
                _selectedSection!, section.copyWith(alignment: 'left'))),
          ),
          _QuickAlignBtn(
            icon: Icons.format_align_center,
            selected: section.alignment == 'center',
            accent: accent,
            onTap: () => setState(() => _template = _setSection(
                _selectedSection!, section.copyWith(alignment: 'center'))),
          ),
          _QuickAlignBtn(
            icon: Icons.format_align_right,
            selected: section.alignment == 'right',
            accent: accent,
            onTap: () => setState(() => _template = _setSection(
                _selectedSection!, section.copyWith(alignment: 'right'))),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 18, color: Colors.grey[300]),
          const SizedBox(width: 8),
          // Fond
          GestureDetector(
            onTap: () => _showBgColorPicker(section),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: section.backgroundColor != null
                        ? Color(section.backgroundColor!)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: Colors.grey[400]!, width: 1),
                  ),
                  child: section.backgroundColor == null
                      ? Icon(Icons.format_color_fill,
                          size: 11, color: Colors.grey[500])
                      : null,
                ),
                const SizedBox(width: 4),
                Text('Fond',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _selectedSection = null),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.close, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 3),
                  Text('Fermer',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBgColorPicker(TemplateSectionModel section) {
    const palette = [
      0xFF1A73E8, 0xFF00897B, 0xFF546E7A, 0xFF8B1A1A,
      0xFF3949AB, 0xFF2E7D32, 0xFFE65100, 0xFF1A237E,
      0xFF37474F, 0xFFF9A825, 0xFF0097A7, 0xFFAD1457,
      0xFF424242, 0xFFFFFFFF, 0xFF000000,
    ];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text('Couleur de fond', style: TextStyle(fontSize: 14)),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: SizedBox(
          width: 220,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: palette.map((c) {
              final sel = c == section.backgroundColor;
              return GestureDetector(
                onTap: () {
                  setState(() => _template = _setSection(
                      _selectedSection!,
                      section.copyWith(backgroundColor: c)));
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
                      color: sel ? _blue : Colors.grey.shade300,
                      width: sel ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _template = _setSection(
                  _selectedSection!,
                  section.copyWith(
                      backgroundColor: null, clearBgColor: true)));
              Navigator.pop(context);
            },
            child: const Text('Aucune', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Tab 0 : Design ────────────────────────────────────────────────────────────

  Widget _buildDesignTab(Color accent) {
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
                  onChanged: (v) => setState(
                      () => _template = _template.copyWith(layout: v)),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                value: _template.showLogo,
                activeColor: accent,
                onChanged: (v) => setState(
                    () => _template = _template.copyWith(showLogo: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Couleur principale',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 10),
              _ColorPicker(
                value: _template.accentColor,
                onChanged: (v) => setState(
                    () => _template = _template.copyWith(accentColor: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Tab 1 : Sections ──────────────────────────────────────────────────────────

  Widget _buildSectionsTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        ..._sectionsMeta.map((meta) {
          final section = _getSection(meta.id);
          final isHighlighted = _selectedSection == meta.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SectionEditor(
              label: meta.label,
              icon: meta.icon,
              section: section,
              accent: accent,
              isHighlighted: isHighlighted,
              onTap: () => setState(() =>
                  _selectedSection = isHighlighted ? null : meta.id),
              onChanged: (updated) => setState(
                  () => _template = _setSection(meta.id, updated)),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Tab 2 : Champs ────────────────────────────────────────────────────────────

  Widget _buildChampsTab(Color accent) {
    if (_selectedSection == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.touch_app_outlined,
                  size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Appuyez sur une section',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            Text(
              'Touchez une zone du document\nou un chip ci-dessus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final meta = _sectionsMeta.firstWhere(
        (m) => m.id == _selectedSection,
        orElse: () => _SectionMeta(
            id: _selectedSection!,
            label: _selectedSection!.name,
            icon: Icons.view_column_outlined));
    final section = _getSection(_selectedSection!);

    return Column(
      children: [
        Container(
          color: accent.withOpacity(0.08),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(meta.icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(meta.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent)),
              const Spacer(),
              Text('${section.fields.length} champ(s)',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
        Expanded(
          child: _FieldsEditor(
            key: ValueKey(_selectedSection),
            section: section,
            accent: accent,
            shrinkWrap: false,
            selectedFieldIndex: _selectedFieldIndex,
            onChanged: (updated) {
              setState(
                  () => _template = _setSection(_selectedSection!, updated));
              _debouncedAutoSave();
            },
          ),
        ),
      ],
    );
  }

  // ── Tab 3 : Tableau ───────────────────────────────────────────────────────────

  Widget _buildTableauTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _Card(
          child: _CustomTableEditor(
            key: ValueKey(
                '${_template.customTable.columnCount}x${_template.customTable.rowCount}'),
            table: _template.customTable,
            accent: accent,
            onChanged: (t) => setState(
                () => _template = _template.copyWith(customTable: t)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Tab 4 : Paiement ──────────────────────────────────────────────────────────

  Widget _buildPaiementTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Afficher les moyens de paiement',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                subtitle: const Text('Section visible en bas de la facture',
                    style: TextStyle(fontSize: 11)),
                value: _template.showPaymentMethods,
                activeColor: accent,
                onChanged: (v) => setState(() =>
                    _template = _template.copyWith(showPaymentMethods: v)),
              ),
              if (_template.showPaymentMethods) ...[
                const Divider(height: 1),
                const SizedBox(height: 10),
                Consumer<BusinessProfileProvider>(
                  builder: (_, profileProv, __) {
                    final methods = profileProv.profile.paymentMethods
                        .where((m) => m.isEnabled)
                        .toList();
                    if (methods.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Aucun moyen de paiement configuré.\nAllez dans Paramètres → Moyens de paiement.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      );
                    }
                    final selected =
                        _template.selectedPaymentMethodIds.toSet();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cochez les moyens à afficher',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        ...methods.map((m) {
                          final isChecked =
                              selected.isEmpty || selected.contains(m.id);
                          return _PaymentMethodCheckTile(
                            method: m,
                            checked: isChecked,
                            onChanged: (v) {
                              final ns = Set<String>.from(
                                  selected.isEmpty
                                      ? methods.map((x) => x.id)
                                      : selected);
                              if (v) {
                                ns.add(m.id);
                              } else {
                                ns.remove(m.id);
                              }
                              setState(() => _template =
                                  _template.copyWith(
                                      selectedPaymentMethodIds:
                                          ns.toList()));
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
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Tab 5 : Automatisation ────────────────────────────────────────────────────

  Widget _buildAutomatisationTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_outlined,
                size: 40, color: Colors.amber[700]),
          ),
          const SizedBox(height: 16),
          Text(
            'Bientôt disponible',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatisez l\'envoi de rappels\nselon le statut de la facture.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ── Helper record ─────────────────────────────────────────────────────────────

class _SectionMeta {
  final TemplateSectionId id;
  final String label;
  final IconData icon;
  const _SectionMeta(
      {required this.id, required this.label, required this.icon});
}

// ── Quick align button ────────────────────────────────────────────────────────

class _QuickAlignBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _QuickAlignBtn({
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? accent : Colors.grey.shade300, width: 1),
        ),
        child: Icon(icon,
            size: 14, color: selected ? accent : Colors.grey[500]),
      ),
    );
  }
}

// ── Section editor (onglet Sections) ─────────────────────────────────────────

class _SectionEditor extends StatefulWidget {
  final String label;
  final IconData icon;
  final TemplateSectionModel section;
  final Color accent;
  final bool isHighlighted;
  final VoidCallback onTap;
  final ValueChanged<TemplateSectionModel> onChanged;

  const _SectionEditor({
    required this.label,
    required this.icon,
    required this.section,
    required this.accent,
    required this.isHighlighted,
    required this.onTap,
    required this.onChanged,
  });

  @override
  State<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends State<_SectionEditor> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_SectionEditor old) {
    super.didUpdateWidget(old);
    if (widget.isHighlighted && !old.isHighlighted) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isHighlighted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? widget.accent : Colors.transparent,
          width: isHighlighted ? 1.5 : 0,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                widget.onTap();
                setState(() => _expanded = !_expanded);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isHighlighted
                                ? widget.accent
                                : const Color(0xFF1A73E8))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon,
                          size: 16,
                          color: isHighlighted
                              ? widget.accent
                              : const Color(0xFF1A73E8)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                    Text(
                      '${widget.section.fields.length} champ(s)',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              _FieldsEditor(
                section: widget.section,
                accent: widget.accent,
                shrinkWrap: true,
                onChanged: widget.onChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Fields editor ─────────────────────────────────────────────────────────────

class _FieldsEditor extends StatefulWidget {
  final TemplateSectionModel section;
  final Color accent;
  final ValueChanged<TemplateSectionModel> onChanged;
  final bool shrinkWrap;
  final int? selectedFieldIndex;

  const _FieldsEditor({
    super.key,
    required this.section,
    required this.accent,
    required this.onChanged,
    this.shrinkWrap = false,
    this.selectedFieldIndex,
  });

  @override
  State<_FieldsEditor> createState() => _FieldsEditorState();
}

class _FieldsEditorState extends State<_FieldsEditor> {
  final List<GlobalKey> _fieldKeys = [];

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    if (widget.selectedFieldIndex != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void didUpdateWidget(_FieldsEditor old) {
    super.didUpdateWidget(old);
    _ensureKeys();
    if (widget.selectedFieldIndex != null &&
        widget.selectedFieldIndex != old.selectedFieldIndex) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _ensureKeys() {
    while (_fieldKeys.length < widget.section.fields.length) {
      _fieldKeys.add(GlobalKey());
    }
    if (_fieldKeys.length > widget.section.fields.length) {
      _fieldKeys.length = widget.section.fields.length;
    }
  }

  void _scrollToSelected() {
    final idx = widget.selectedFieldIndex;
    if (idx == null || idx >= _fieldKeys.length) return;
    final ctx = _fieldKeys[idx].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final accent = widget.accent;
    return ListView(
      padding: const EdgeInsets.all(12),
      shrinkWrap: widget.shrinkWrap,
      physics:
          widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: [
        Row(
          children: [
            Text('Alignement',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(width: 10),
            _AlignmentToggle(
              value: section.alignment,
              accent: accent,
              onChanged: (a) =>
                  widget.onChanged(section.copyWith(alignment: a)),
            ),
            const Spacer(),
            _NullableColorSwatch(
              label: 'Couleur de fond',
              value: section.backgroundColor,
              onChanged: (v) => widget.onChanged(section.copyWith(
                  backgroundColor: v, clearBgColor: v == null)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...section.fields.asMap().entries.map((entry) {
          final i = entry.key;
          final field = entry.value;
          return _FieldRow(
            key: _fieldKeys[i],
            field: field,
            accent: accent,
            isSelected: i == widget.selectedFieldIndex,
            onChanged: (updated) {
              final newFields =
                  List<TemplateFieldConfig>.from(section.fields);
              newFields[i] = updated;
              widget.onChanged(section.copyWith(fields: newFields));
            },
            onDelete: () {
              final newFields =
                  List<TemplateFieldConfig>.from(section.fields)
                    ..removeAt(i);
              widget.onChanged(section.copyWith(fields: newFields));
            },
          );
        }),
        TextButton.icon(
          onPressed: () {
            final newFields =
                List<TemplateFieldConfig>.from(section.fields)
                  ..add(const TemplateFieldConfig(
                      source: FieldSource.manual));
            widget.onChanged(section.copyWith(fields: newFields));
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Ajouter un champ',
              style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

// ── Field row ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatefulWidget {
  final TemplateFieldConfig field;
  final ValueChanged<TemplateFieldConfig> onChanged;
  final VoidCallback onDelete;
  final bool isSelected;
  final Color accent;

  const _FieldRow({
    super.key,
    required this.field,
    required this.onChanged,
    required this.onDelete,
    this.isSelected = false,
    this.accent = const Color(0xFF1A73E8),
  });

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  late TextEditingController _labelCtrl;
  late TextEditingController _valueCtrl;
  late FocusNode _labelFocus;
  late FocusNode _valueFocus;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.field.label ?? '');
    _valueCtrl = TextEditingController(text: widget.field.manualValue ?? '');
    _labelFocus = FocusNode();
    _valueFocus = FocusNode();
  }

  @override
  void didUpdateWidget(_FieldRow old) {
    super.didUpdateWidget(old);
    // Only sync from outside when the user is NOT actively typing in that field
    if (!_labelFocus.hasFocus && widget.field.label != old.field.label) {
      _labelCtrl.text = widget.field.label ?? '';
    }
    if (!_valueFocus.hasFocus &&
        widget.field.manualValue != old.field.manualValue) {
      _valueCtrl.text = widget.field.manualValue ?? '';
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _valueCtrl.dispose();
    _labelFocus.dispose();
    _valueFocus.dispose();
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
          color: widget.isSelected
              ? widget.accent
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          width: widget.isSelected ? 2 : 1,
        ),
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
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
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
          TextFormField(
            controller: _labelCtrl,
            focusNode: _labelFocus,
            decoration: const InputDecoration(
              labelText: 'Préfixe (optionnel)',
              hintText: 'Ex: Émise le',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (v) => widget.onChanged(
                widget.field.copyWith(
                    label: v.isEmpty ? null : v, clearLabel: v.isEmpty)),
          ),
          if (isManual) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _valueCtrl,
              focusNode: _valueFocus,
              decoration: const InputDecoration(
                labelText: 'Texte',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) => widget.onChanged(widget.field.copyWith(
                  manualValue: v.isEmpty ? null : v,
                  clearManualValue: v.isEmpty)),
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CheckChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckChip(
      {required this.label,
      required this.value,
      required this.onChanged});

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
  final Color accent;
  final ValueChanged<String> onChanged;

  const _AlignmentToggle(
      {required this.value,
      required this.accent,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AlignBtn(
            icon: Icons.format_align_left,
            selected: value == 'left',
            accent: accent,
            onTap: () => onChanged('left')),
        _AlignBtn(
            icon: Icons.format_align_center,
            selected: value == 'center',
            accent: accent,
            onTap: () => onChanged('center')),
        _AlignBtn(
            icon: Icons.format_align_right,
            selected: value == 'right',
            accent: accent,
            onTap: () => onChanged('right')),
      ],
    );
  }
}

class _AlignBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _AlignBtn({
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? accent : Colors.grey.shade300, width: 1),
        ),
        child:
            Icon(icon, size: 14, color: selected ? accent : Colors.grey),
      ),
    );
  }
}

class _LayoutPicker extends StatelessWidget {
  final TemplateLayout value;
  final ValueChanged<TemplateLayout> onChanged;

  const _LayoutPicker(
      {required this.value, required this.onChanged});

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
            value: TemplateLayout.minimal,
            child: Text('Minimaliste')),
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

  const _TitlePicker(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      'FACTURE',
      'DEVIS',
      'BON DE COMMANDE',
      'PROFORMA',
      'REÇU'
    ];
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

// ── Nullable color swatch ─────────────────────────────────────────────────────

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
      {required this.value,
      required this.onChanged,
      this.label = ''});

  void _show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label.isNotEmpty ? label : 'Couleur',
            style: const TextStyle(fontSize: 14)),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: SizedBox(
          width: 220,
          child: Wrap(
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
                      color: sel
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade300,
                      width: sel ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
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
              color: value != null
                  ? Color(value!)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: value != null
                    ? Color(value!).withOpacity(0.6)
                    : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: value == null
                ? const Icon(Icons.palette_outlined,
                    size: 12, color: Color(0xFF9AA0A6))
                : null,
          ),
          const SizedBox(width: 4),
          Text(
            value != null ? 'Couleur' : 'Défaut',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF5F6368)),
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ColorPicker(
      {required this.value, required this.onChanged});

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
                          spreadRadius: 1)
                    ]
                  : [],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared layout ─────────────────────────────────────────────────────────────

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
                      child: Image.asset(method.type.assetPath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                              method.type.icon,
                              size: 16,
                              color: color)),
                    )
                  : Icon(method.type.icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(method.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
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
    _cCtls.addAll(t.rows
        .map((row) => row.map((c) => TextEditingController(text: c)).toList()));
  }

  void _disposeAll() {
    for (final c in _hCtls) {
      c.dispose();
    }
    for (final row in _cCtls) {
      for (final c in row) {
        c.dispose();
      }
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
    final divColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _counter(context, 'Colonnes', t.columnCount, 1, 12,
                () => widget.onChanged(t.removeLastColumn()),
                () => widget.onChanged(t.addColumn())),
            const SizedBox(width: 20),
            _counter(context, 'Lignes', t.rowCount, 1, 100,
                () => widget.onChanged(t.removeLastRow()),
                () => widget.onChanged(t.addRow())),
          ],
        ),
        const SizedBox(height: 12),
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
                  Container(
                    color: widget.accent,
                    child: Row(
                      children: List.generate(
                          t.columnCount,
                          (col) => _cell(context, _hCtls[col],
                              isHeader: true,
                              showDivider: col < t.columnCount - 1,
                              divColor:
                                  Colors.white.withOpacity(0.3),
                              onChanged: (v) => widget
                                  .onChanged(t.updateHeader(col, v)))),
                    ),
                  ),
                  ...List.generate(
                      t.rowCount,
                      (row) => Container(
                            decoration: BoxDecoration(
                              color: row.isOdd
                                  ? (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50)
                                  : (isDark
                                      ? const Color(0xFF1E2433)
                                      : Colors.white),
                              border: Border(
                                  top: BorderSide(
                                      color: divColor, width: 0.5)),
                            ),
                            child: Row(
                              children: List.generate(
                                  t.columnCount,
                                  (col) => _cell(
                                      context, _cCtls[row][col],
                                      showDivider:
                                          col < t.columnCount - 1,
                                      divColor: divColor,
                                      onChanged: (v) =>
                                          widget.onChanged(
                                              t.updateCell(
                                                  row, col, v)))),
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

  Widget _counter(BuildContext context, String label, int value,
      int min, int max, VoidCallback onDec, VoidCallback onInc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        _btn(Icons.remove, value > min ? onDec : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$value',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
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
        child: Icon(icon,
            size: 14,
            color: onTap != null
                ? Colors.white
                : Colors.grey.shade500),
      ),
    );
  }

  Widget _cell(BuildContext context, TextEditingController ctl,
      {bool isHeader = false,
      bool showDivider = false,
      Color divColor = const Color(0xFFE0E0E0),
      ValueChanged<String>? onChanged}) {
    return Expanded(
      child: Container(
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                    right: BorderSide(color: divColor, width: 0.5)))
            : null,
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: TextField(
          controller: ctl,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isHeader ? FontWeight.bold : FontWeight.normal,
            color: isHeader ? Colors.white : null,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 0, vertical: 6),
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
