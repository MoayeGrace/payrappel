enum InvoiceStatus { draft, partial, paid, late }

class InvoiceModel {
  final String id;
  final String userId;
  final String clientId;
  final String clientName;
  final String title;
  final double totalAmount;
  final double paidAmount;
  final double discountAmount;
  final DateTime dueDate;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, String>> customFields;
  final String? templateId;
  final List<Map<String, dynamic>> lineItems;
  final List<Map<String, dynamic>> extraColumns;
  final String notes;
  final double? globalPrice;

  const InvoiceModel({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.totalAmount,
    this.paidAmount = 0,
    this.discountAmount = 0,
    required this.dueDate,
    this.status = InvoiceStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.customFields = const [],
    this.templateId,
    this.lineItems = const [],
    this.extraColumns = const [],
    this.notes = '',
    this.globalPrice,
  });

  double get remainingAmount => totalAmount - paidAmount;
  bool get isFullyPaid => paidAmount >= totalAmount;
  double get subtotal => lineItems.isEmpty
      ? totalAmount
      : lineItems.fold(0.0, (s, item) =>
          s + (item['qty'] as num? ?? 0) * (item['unitPrice'] as num? ?? 0));

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.fromMillisecondsSinceEpoch(
        map['dueDate'] as int? ?? 0,
      ),
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] as int? ?? 0,
      ),
      customFields: (map['customFields'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      templateId: map['templateId'] as String?,
      lineItems: (map['lineItems'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      extraColumns: (map['extraColumns'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      notes: map['notes'] as String? ?? '',
      globalPrice: (map['globalPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientId': clientId,
      'clientName': clientName,
      'title': title,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      if (discountAmount != 0) 'discountAmount': discountAmount,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'customFields': customFields,
      if (templateId != null) 'templateId': templateId,
      if (lineItems.isNotEmpty) 'lineItems': lineItems,
      if (extraColumns.isNotEmpty) 'extraColumns': extraColumns,
      if (notes.isNotEmpty) 'notes': notes,
      if (globalPrice != null && globalPrice! > 0) 'globalPrice': globalPrice,
    };
  }

  InvoiceModel copyWith({
    String? title,
    double? totalAmount,
    double? paidAmount,
    double? discountAmount,
    DateTime? dueDate,
    InvoiceStatus? status,
    DateTime? updatedAt,
    List<Map<String, String>>? customFields,
    String? templateId,
    bool clearTemplateId = false,
    List<Map<String, dynamic>>? lineItems,
    List<Map<String, dynamic>>? extraColumns,
    String? notes,
    double? globalPrice,
    bool clearGlobalPrice = false,
  }) {
    return InvoiceModel(
      id: id,
      userId: userId,
      clientId: clientId,
      clientName: clientName,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customFields: customFields ?? this.customFields,
      templateId: clearTemplateId ? null : (templateId ?? this.templateId),
      lineItems: lineItems ?? this.lineItems,
      extraColumns: extraColumns ?? this.extraColumns,
      notes: notes ?? this.notes,
      globalPrice: clearGlobalPrice ? null : (globalPrice ?? this.globalPrice),
    );
  }
}
