// ignore_for_file: constant_identifier_names

enum TemplateLayout { classic, modern, minimal, bold }

/// Identifie chacune des sections éditables d'un template.
enum TemplateSectionId {
  topLeft,
  topRight,
  bottomCenter,
  // Conservés pour compatibilité ascendante, non affichés dans l'UI :
  topCenter,
  bottomLeft,
  bottomRight,
}

enum FieldSource {
  companyName,
  companyAddress,
  companyPhone,
  companyEmail,
  companyRccm,
  clientName,
  clientAddress,
  clientPhone,
  clientEmail,
  invoiceTitle,
  invoiceDate,
  invoiceDueDate,
  invoiceStatus,
  bankInfo,
  invoiceNumber,
  manual,
}

extension FieldSourceLabel on FieldSource {
  String get displayName => switch (this) {
        FieldSource.companyName => 'Nom entreprise',
        FieldSource.companyAddress => 'Adresse entreprise',
        FieldSource.companyPhone => 'Téléphone entreprise',
        FieldSource.companyEmail => 'Email entreprise',
        FieldSource.companyRccm => 'RCCM / NIF',
        FieldSource.clientName => 'Nom client',
        FieldSource.clientAddress => 'Adresse client',
        FieldSource.clientPhone => 'Téléphone client',
        FieldSource.clientEmail => 'Email client',
        FieldSource.invoiceTitle => 'Titre facture',
        FieldSource.invoiceDate => 'Date d\'émission',
        FieldSource.invoiceDueDate => 'Date d\'échéance',
        FieldSource.invoiceStatus => 'Statut',
        FieldSource.bankInfo => 'Infos bancaires',
        FieldSource.invoiceNumber => 'Numéro de facture',
        FieldSource.manual => 'Texte manuel',
      };
}

// ── Field config ───────────────────────────────────────────────────────────────

class TemplateFieldConfig {
  final FieldSource source;
  final String? label;
  final String? manualValue;
  final bool bold;
  final bool large;
  final int? textColor;

  const TemplateFieldConfig({
    required this.source,
    this.label,
    this.manualValue,
    this.bold = false,
    this.large = false,
    this.textColor,
  });

  factory TemplateFieldConfig.fromMap(Map<String, dynamic> m) =>
      TemplateFieldConfig(
        source: FieldSource.values.firstWhere(
          (s) => s.name == (m['source'] as String?),
          orElse: () => FieldSource.manual,
        ),
        label: m['label'] as String?,
        manualValue: m['manualValue'] as String?,
        bold: m['bold'] as bool? ?? false,
        large: m['large'] as bool? ?? false,
        textColor: m['textColor'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'source': source.name,
        if (label != null) 'label': label,
        if (manualValue != null) 'manualValue': manualValue,
        'bold': bold,
        'large': large,
        if (textColor != null) 'textColor': textColor,
      };

  TemplateFieldConfig copyWith({
    FieldSource? source,
    String? label,
    String? manualValue,
    bool? bold,
    bool? large,
    int? textColor,
    bool clearTextColor = false,
  }) =>
      TemplateFieldConfig(
        source: source ?? this.source,
        label: label ?? this.label,
        manualValue: manualValue ?? this.manualValue,
        bold: bold ?? this.bold,
        large: large ?? this.large,
        textColor: clearTextColor ? null : (textColor ?? this.textColor),
      );
}

// ── Section model ──────────────────────────────────────────────────────────────

class TemplateSectionModel {
  final String alignment; // 'left' | 'center' | 'right'
  final List<TemplateFieldConfig> fields;
  final int? backgroundColor; // ARGB int, null = transparent

  const TemplateSectionModel({
    this.alignment = 'left',
    this.fields = const [],
    this.backgroundColor,
  });

  bool get isEmpty => fields.isEmpty;

  factory TemplateSectionModel.fromMap(Map<String, dynamic> m) =>
      TemplateSectionModel(
        alignment: m['alignment'] as String? ?? 'left',
        fields: (m['fields'] as List?)
                ?.map((e) =>
                    TemplateFieldConfig.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        backgroundColor: m['backgroundColor'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'alignment': alignment,
        'fields': fields.map((f) => f.toMap()).toList(),
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
      };

  TemplateSectionModel copyWith({
    String? alignment,
    List<TemplateFieldConfig>? fields,
    int? backgroundColor,
    bool clearBgColor = false,
  }) =>
      TemplateSectionModel(
        alignment: alignment ?? this.alignment,
        fields: fields ?? this.fields,
        backgroundColor: clearBgColor ? null : (backgroundColor ?? this.backgroundColor),
      );
}

// ── Custom table model ─────────────────────────────────────────────────────────

class TemplateCustomTable {
  final List<String> headers;
  final List<List<String>> rows;

  const TemplateCustomTable({
    this.headers = const ['Description', 'Qté', 'Montant'],
    this.rows = const [
      ['Prestation 1', '1', ''],
      ['Prestation 2', '1', ''],
    ],
  });

  int get columnCount => headers.length;
  int get rowCount => rows.length;

  factory TemplateCustomTable.fromMap(Map<String, dynamic> m) {
    final h = (m['headers'] as List?)?.cast<String>() ??
        ['Description', 'Qté', 'Montant'];
    final rawRows = m['rows'] as List?;
    final r = rawRows
            ?.map((row) {
              if (row is Map) {
                return (row['cells'] as List?)?.cast<String>() ??
                    List.filled(h.length, '');
              }
              if (row is List) return row.cast<String>();
              return List.filled(h.length, '');
            })
            .toList() ??
        [List.filled(h.length, '')];
    return TemplateCustomTable(headers: h, rows: r);
  }

  Map<String, dynamic> toMap() => {
        'headers': headers,
        'rows': rows.map((r) => {'cells': r.toList()}).toList(),
      };

  TemplateCustomTable copyWith({
    List<String>? headers,
    List<List<String>>? rows,
  }) =>
      TemplateCustomTable(
        headers: headers ?? this.headers,
        rows: rows ?? this.rows,
      );

  TemplateCustomTable updateHeader(int col, String value) {
    if (col >= columnCount) return this;
    final h = List<String>.from(headers);
    h[col] = value;
    return copyWith(headers: h);
  }

  TemplateCustomTable updateCell(int row, int col, String value) {
    final r = rows.map((row) => List<String>.from(row)).toList();
    if (row < r.length && col < r[row].length) r[row][col] = value;
    return copyWith(rows: r);
  }

  TemplateCustomTable addColumn() {
    if (columnCount >= 12) return this;
    return copyWith(
      headers: [...headers, 'Col. ${columnCount + 1}'],
      rows: rows.map((r) => [...r, '']).toList(),
    );
  }

  TemplateCustomTable removeLastColumn() {
    if (columnCount <= 1) return this;
    return copyWith(
      headers: headers.sublist(0, columnCount - 1),
      rows: rows.map((r) => r.sublist(0, columnCount - 1)).toList(),
    );
  }

  TemplateCustomTable addRow() {
    if (rowCount >= 100) return this;
    return copyWith(rows: [...rows, List.filled(columnCount, '')]);
  }

  TemplateCustomTable removeLastRow() {
    if (rowCount <= 1) return this;
    return copyWith(rows: rows.sublist(0, rowCount - 1));
  }
}

// ── Template model ─────────────────────────────────────────────────────────────

class InvoiceTemplateModel {
  final String id;
  final String name;
  final bool isBuiltIn;
  final int accentColor;
  final int? headerBgColor;
  final TemplateLayout layout;
  final String titleLabel;
  final bool showLogo;
  final bool showPaymentMethods;
  final List<String> selectedPaymentMethodIds;
  final TemplateSectionModel topCenter;
  final TemplateSectionModel topLeft;
  final TemplateSectionModel topRight;
  final TemplateSectionModel bottomLeft;
  final TemplateSectionModel bottomRight;
  final TemplateSectionModel bottomCenter;
  // ── Tableau personnalisé (corps de la facture) ─────────────────────────────
  final TemplateCustomTable customTable;

  const InvoiceTemplateModel({
    required this.id,
    required this.name,
    this.isBuiltIn = false,
    required this.accentColor,
    this.headerBgColor,
    this.layout = TemplateLayout.classic,
    this.titleLabel = 'FACTURE',
    this.showLogo = true,
    this.showPaymentMethods = false,
    this.selectedPaymentMethodIds = const [],
    required this.topCenter,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.bottomCenter,
    this.customTable = const TemplateCustomTable(),
  });

  factory InvoiceTemplateModel.fromMap(Map<String, dynamic> m, String id) =>
      InvoiceTemplateModel(
        id: id,
        name: m['name'] as String? ?? '',
        isBuiltIn: m['isBuiltIn'] as bool? ?? false,
        accentColor: m['accentColor'] as int? ?? 0xFF1A73E8,
        headerBgColor: m['headerBgColor'] as int?,
        layout: TemplateLayout.values.firstWhere(
          (l) => l.name == (m['layout'] as String?),
          orElse: () => TemplateLayout.classic,
        ),
        titleLabel: m['titleLabel'] as String? ?? 'FACTURE',
        showLogo: m['showLogo'] as bool? ?? true,
        showPaymentMethods: m['showPaymentMethods'] as bool? ?? false,
        selectedPaymentMethodIds:
            (m['selectedPaymentMethodIds'] as List?)?.cast<String>() ?? [],
        topCenter: TemplateSectionModel.fromMap(
            m['topCenter'] as Map<String, dynamic>? ?? {}),
        topLeft: TemplateSectionModel.fromMap(
            m['topLeft'] as Map<String, dynamic>? ?? {}),
        topRight: TemplateSectionModel.fromMap(
            m['topRight'] as Map<String, dynamic>? ?? {}),
        bottomLeft: TemplateSectionModel.fromMap(
            m['bottomLeft'] as Map<String, dynamic>? ?? {}),
        bottomRight: TemplateSectionModel.fromMap(
            m['bottomRight'] as Map<String, dynamic>? ?? {}),
        bottomCenter: TemplateSectionModel.fromMap(
            m['bottomCenter'] as Map<String, dynamic>? ?? {}),
        customTable: m['customTable'] != null
            ? TemplateCustomTable.fromMap(
                m['customTable'] as Map<String, dynamic>)
            : const TemplateCustomTable(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'isBuiltIn': isBuiltIn,
        'accentColor': accentColor,
        if (headerBgColor != null) 'headerBgColor': headerBgColor,
        'layout': layout.name,
        'titleLabel': titleLabel,
        'showLogo': showLogo,
        'showPaymentMethods': showPaymentMethods,
        'selectedPaymentMethodIds': selectedPaymentMethodIds,
        'topCenter': topCenter.toMap(),
        'topLeft': topLeft.toMap(),
        'topRight': topRight.toMap(),
        'bottomLeft': bottomLeft.toMap(),
        'bottomRight': bottomRight.toMap(),
        'bottomCenter': bottomCenter.toMap(),
        'customTable': customTable.toMap(),
      };

  InvoiceTemplateModel copyWith({
    String? name,
    bool? isBuiltIn,
    int? accentColor,
    int? headerBgColor,
    TemplateLayout? layout,
    String? titleLabel,
    bool? showLogo,
    bool? showPaymentMethods,
    List<String>? selectedPaymentMethodIds,
    TemplateSectionModel? topCenter,
    TemplateSectionModel? topLeft,
    TemplateSectionModel? topRight,
    TemplateSectionModel? bottomLeft,
    TemplateSectionModel? bottomRight,
    TemplateSectionModel? bottomCenter,
    TemplateCustomTable? customTable,
  }) =>
      InvoiceTemplateModel(
        id: id,
        name: name ?? this.name,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        accentColor: accentColor ?? this.accentColor,
        headerBgColor: headerBgColor ?? this.headerBgColor,
        layout: layout ?? this.layout,
        titleLabel: titleLabel ?? this.titleLabel,
        showLogo: showLogo ?? this.showLogo,
        showPaymentMethods: showPaymentMethods ?? this.showPaymentMethods,
        selectedPaymentMethodIds:
            selectedPaymentMethodIds ?? this.selectedPaymentMethodIds,
        topCenter: topCenter ?? this.topCenter,
        topLeft: topLeft ?? this.topLeft,
        topRight: topRight ?? this.topRight,
        bottomLeft: bottomLeft ?? this.bottomLeft,
        bottomRight: bottomRight ?? this.bottomRight,
        bottomCenter: bottomCenter ?? this.bottomCenter,
        customTable: customTable ?? this.customTable,
      );
}

// ── Section defaults ───────────────────────────────────────────────────────────

const _sectionCompany = TemplateSectionModel(
  alignment: 'left',
  fields: [
    TemplateFieldConfig(source: FieldSource.companyName, bold: true, large: true),
    TemplateFieldConfig(source: FieldSource.companyAddress),
    TemplateFieldConfig(source: FieldSource.companyPhone),
    TemplateFieldConfig(source: FieldSource.companyEmail),
    TemplateFieldConfig(source: FieldSource.companyRccm),
  ],
);

const _sectionInvoiceMeta = TemplateSectionModel(
  alignment: 'right',
  fields: [
    TemplateFieldConfig(source: FieldSource.invoiceNumber, bold: true),
    TemplateFieldConfig(source: FieldSource.invoiceDate, label: 'Émise le'),
    TemplateFieldConfig(source: FieldSource.invoiceDueDate, label: 'Échéance'),
    TemplateFieldConfig(source: FieldSource.invoiceStatus, label: 'Statut'),
  ],
);

const _sectionClient = TemplateSectionModel(
  alignment: 'left',
  fields: [
    TemplateFieldConfig(source: FieldSource.clientName, bold: true),
    TemplateFieldConfig(source: FieldSource.clientAddress),
    TemplateFieldConfig(source: FieldSource.clientPhone),
    TemplateFieldConfig(source: FieldSource.clientEmail),
  ],
);

const _sectionFooter = TemplateSectionModel(
  alignment: 'center',
  fields: [
    TemplateFieldConfig(
        source: FieldSource.manual,
        manualValue: 'Merci pour votre confiance.'),
  ],
);

const _sectionEmpty = TemplateSectionModel();

// ── 15 Built-in templates ──────────────────────────────────────────────────────

class BuiltInTemplates {
  static const List<InvoiceTemplateModel> all = [
    // 1 — Classique Bleu (default)
    InvoiceTemplateModel(
      id: 'builtin_classic_blue',
      name: 'Classique Bleu',
      isBuiltIn: true,
      accentColor: 0xFF1A73E8,
      layout: TemplateLayout.classic,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 2 — Moderne Teal
    InvoiceTemplateModel(
      id: 'builtin_modern_teal',
      name: 'Moderne Teal',
      isBuiltIn: true,
      accentColor: 0xFF00897B,
      headerBgColor: 0xFF00695C,
      layout: TemplateLayout.modern,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 3 — Minimaliste
    InvoiceTemplateModel(
      id: 'builtin_minimal_grey',
      name: 'Minimaliste',
      isBuiltIn: true,
      accentColor: 0xFF546E7A,
      layout: TemplateLayout.minimal,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 4 — Bordeaux Pro
    InvoiceTemplateModel(
      id: 'builtin_classic_bordeaux',
      name: 'Bordeaux Pro',
      isBuiltIn: true,
      accentColor: 0xFF8B1A1A,
      layout: TemplateLayout.classic,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 5 — Tech Indigo
    InvoiceTemplateModel(
      id: 'builtin_modern_indigo',
      name: 'Tech Indigo',
      isBuiltIn: true,
      accentColor: 0xFF3949AB,
      headerBgColor: 0xFF283593,
      layout: TemplateLayout.modern,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 6 — Tropical Vert
    InvoiceTemplateModel(
      id: 'builtin_classic_green',
      name: 'Tropical Vert',
      isBuiltIn: true,
      accentColor: 0xFF2E7D32,
      layout: TemplateLayout.classic,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 7 — Orange Soleil
    InvoiceTemplateModel(
      id: 'builtin_bold_orange',
      name: 'Orange Soleil',
      isBuiltIn: true,
      accentColor: 0xFFE65100,
      layout: TemplateLayout.bold,
      showPaymentMethods: true,
      topCenter: TemplateSectionModel(
        alignment: 'center',
        fields: [
          TemplateFieldConfig(
              source: FieldSource.manual,
              manualValue: 'FACTURE COMMERCIALE',
              bold: true,
              large: true),
        ],
      ),
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 8 — Nuit Profonde
    InvoiceTemplateModel(
      id: 'builtin_modern_navy',
      name: 'Nuit Profonde',
      isBuiltIn: true,
      accentColor: 0xFF5C6BC0,
      headerBgColor: 0xFF1A237E,
      layout: TemplateLayout.modern,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 9 — Ardoise Pro
    InvoiceTemplateModel(
      id: 'builtin_minimal_slate',
      name: 'Ardoise Pro',
      isBuiltIn: true,
      accentColor: 0xFF37474F,
      layout: TemplateLayout.minimal,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 10 — Doré Prestige
    InvoiceTemplateModel(
      id: 'builtin_bold_gold',
      name: 'Doré Prestige',
      isBuiltIn: true,
      accentColor: 0xFFF9A825,
      headerBgColor: 0xFF212121,
      layout: TemplateLayout.bold,
      showPaymentMethods: true,
      topCenter: TemplateSectionModel(
        alignment: 'center',
        fields: [
          TemplateFieldConfig(
              source: FieldSource.manual,
              manualValue: 'PRESTIGE',
              bold: true,
              large: true),
        ],
      ),
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 11 — Océan Cyan
    InvoiceTemplateModel(
      id: 'builtin_classic_cyan',
      name: 'Océan Cyan',
      isBuiltIn: true,
      accentColor: 0xFF0097A7,
      layout: TemplateLayout.classic,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 12 — Rose Fuchsia
    InvoiceTemplateModel(
      id: 'builtin_modern_rose',
      name: 'Rose Fuchsia',
      isBuiltIn: true,
      accentColor: 0xFFAD1457,
      headerBgColor: 0xFF880E4F,
      layout: TemplateLayout.modern,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 13 — Noir Élégant
    InvoiceTemplateModel(
      id: 'builtin_bold_black',
      name: 'Noir Élégant',
      isBuiltIn: true,
      accentColor: 0xFF424242,
      headerBgColor: 0xFF212121,
      layout: TemplateLayout.bold,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 14 — Forêt Profonde
    InvoiceTemplateModel(
      id: 'builtin_minimal_forest',
      name: 'Forêt Profonde',
      isBuiltIn: true,
      accentColor: 0xFF1B5E20,
      layout: TemplateLayout.minimal,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
    // 15 — Bleu Marine
    InvoiceTemplateModel(
      id: 'builtin_classic_navy2',
      name: 'Bleu Marine',
      isBuiltIn: true,
      accentColor: 0xFF1565C0,
      layout: TemplateLayout.classic,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // ── 12 nouveaux templates ─────────────────────────────────────────────────

    // 16 — Studio Navy Gold
    InvoiceTemplateModel(
      id: 'builtin_modern_navy_gold',
      name: 'Studio Navy Gold',
      isBuiltIn: true,
      accentColor: 0xFFF59E0B,
      headerBgColor: 0xFF1A237E,
      layout: TemplateLayout.modern,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 17 — Charbon Jaune
    InvoiceTemplateModel(
      id: 'builtin_bold_charcoal_yellow',
      name: 'Charbon Jaune',
      isBuiltIn: true,
      accentColor: 0xFFFFD600,
      headerBgColor: 0xFF212121,
      layout: TemplateLayout.bold,
      showPaymentMethods: true,
      topCenter: TemplateSectionModel(
        alignment: 'center',
        fields: [
          TemplateFieldConfig(
              source: FieldSource.manual,
              manualValue: 'FACTURE',
              bold: true,
              large: true),
        ],
      ),
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 18 — Signature Noir
    InvoiceTemplateModel(
      id: 'builtin_minimal_black',
      name: 'Signature Noir',
      isBuiltIn: true,
      accentColor: 0xFF111111,
      layout: TemplateLayout.minimal,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 19 — Corail Créatif
    InvoiceTemplateModel(
      id: 'builtin_classic_coral',
      name: 'Corail Créatif',
      isBuiltIn: true,
      accentColor: 0xFFE91E63,
      layout: TemplateLayout.classic,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 20 — Impact Royal
    InvoiceTemplateModel(
      id: 'builtin_bold_royal_purple',
      name: 'Impact Royal',
      isBuiltIn: true,
      accentColor: 0xFF9C27B0,
      headerBgColor: 0xFF4A148C,
      layout: TemplateLayout.bold,
      showPaymentMethods: true,
      topCenter: TemplateSectionModel(
        alignment: 'center',
        fields: [
          TemplateFieldConfig(
              source: FieldSource.manual,
              manualValue: 'FACTURE OFFICIELLE',
              bold: true,
              large: true),
        ],
      ),
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 21 — Saumon Studio
    InvoiceTemplateModel(
      id: 'builtin_modern_salmon',
      name: 'Saumon Studio',
      isBuiltIn: true,
      accentColor: 0xFFFF6B6B,
      headerBgColor: 0xFFD84315,
      layout: TemplateLayout.modern,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 22 — Vert Sauge
    InvoiceTemplateModel(
      id: 'builtin_minimal_sage',
      name: 'Vert Sauge',
      isBuiltIn: true,
      accentColor: 0xFF558B2F,
      layout: TemplateLayout.minimal,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 23 — Acier Pro
    InvoiceTemplateModel(
      id: 'builtin_classic_steel',
      name: 'Acier Pro',
      isBuiltIn: true,
      accentColor: 0xFF455A64,
      layout: TemplateLayout.classic,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 24 — Impact Nuit
    InvoiceTemplateModel(
      id: 'builtin_bold_midnight',
      name: 'Impact Nuit',
      isBuiltIn: true,
      accentColor: 0xFF3B82F6,
      headerBgColor: 0xFF0A0E2A,
      layout: TemplateLayout.bold,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 25 — Cuivre Luxe
    InvoiceTemplateModel(
      id: 'builtin_modern_copper',
      name: 'Cuivre Luxe',
      isBuiltIn: true,
      accentColor: 0xFFBF8E3D,
      headerBgColor: 0xFF3E2000,
      layout: TemplateLayout.modern,
      showPaymentMethods: true,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 26 — Tech Ciel
    InvoiceTemplateModel(
      id: 'builtin_classic_skyblue',
      name: 'Tech Ciel',
      isBuiltIn: true,
      accentColor: 0xFF0288D1,
      layout: TemplateLayout.classic,
      showPaymentMethods: false,
      topCenter: _sectionEmpty,
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),

    // 27 — Canary Dark
    InvoiceTemplateModel(
      id: 'builtin_bold_canary',
      name: 'Canary Dark',
      isBuiltIn: true,
      accentColor: 0xFFFFEA00,
      headerBgColor: 0xFF1A1A1A,
      layout: TemplateLayout.bold,
      showPaymentMethods: false,
      topCenter: TemplateSectionModel(
        alignment: 'center',
        fields: [
          TemplateFieldConfig(
              source: FieldSource.manual,
              manualValue: 'FACTURE',
              bold: true,
              large: true),
        ],
      ),
      topLeft: _sectionCompany,
      topRight: _sectionInvoiceMeta,
      bottomLeft: _sectionClient,
      bottomRight: _sectionEmpty,
      bottomCenter: _sectionFooter,
    ),
  ];
}
