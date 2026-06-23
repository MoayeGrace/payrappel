import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/client_model.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';

// ── Contrôleurs d'une ligne de facturation ─────────────────────────────────────
class _LineItemCtrl {
  final TextEditingController description;
  final TextEditingController qty;
  final TextEditingController unitPrice;
  final Map<String, TextEditingController> extras;

  _LineItemCtrl({
    String desc = '',
    int q = 1,
    double pu = 0,
    Map<String, String> extraVals = const {},
  })  : description = TextEditingController(text: desc),
        qty = TextEditingController(text: q.toString()),
        unitPrice = TextEditingController(text: pu == 0 ? '' : pu.toStringAsFixed(0)),
        extras = Map.fromEntries(
          extraVals.entries.map(
            (e) => MapEntry(e.key, TextEditingController(text: e.value)),
          ),
        );

  void addExtra(String key, {String value = ''}) {
    if (!extras.containsKey(key)) {
      extras[key] = TextEditingController(text: value);
    }
  }

  void removeExtra(String key) {
    extras[key]?.dispose();
    extras.remove(key);
  }

  void attachListener(VoidCallback fn) {
    description.addListener(fn);
    qty.addListener(fn);
    unitPrice.addListener(fn);
    for (final c in extras.values) {
      c.addListener(fn);
    }
  }

  void dispose() {
    description.dispose();
    qty.dispose();
    unitPrice.dispose();
    for (final c in extras.values) {
      c.dispose();
    }
  }

  Map<String, dynamic> toMap() => {
        'description': description.text.trim(),
        'qty': int.tryParse(qty.text.trim()) ?? 1,
        'unitPrice': double.tryParse(unitPrice.text.trim().replaceAll(' ', '')) ?? 0.0,
        ...extras.map((k, c) => MapEntry(k, c.text.trim())),
      };

  double get lineTotal {
    final q = int.tryParse(qty.text.trim()) ?? 0;
    final pu = double.tryParse(unitPrice.text.trim().replaceAll(' ', '')) ?? 0.0;
    return q * pu;
  }
}

// ── Dropdown client ────────────────────────────────────────────────────────────
class _ClientDropdown extends StatelessWidget {
  final String? selectedId;
  final void Function(String id, String name) onSelected;

  const _ClientDropdown({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClientModel>>(
      stream: context.read<ClientProvider>().watchClients(),
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedId,
            decoration: const InputDecoration(
              labelText: 'Client',
              prefixIcon:
                  Icon(Icons.person_outlined, color: Color(0xFF00C6A2)),
              border: InputBorder.none,
            ),
            hint: const Text('Sélectionner un client'),
            items: clients
                .map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (id) {
              if (id == null) return;
              final client = clients.firstWhere((c) => c.id == id);
              onSelected(client.id, client.name);
            },
          ),
        );
      },
    );
  }
}

class _LockedClientField extends StatelessWidget {
  final String name;
  const _LockedClientField({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outlined, color: Color(0xFF00C6A2)),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Widget ─────────────────────────────────────────────────────────────────────
class AddEditInvoiceScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  final String? prefillClientId;
  final String? prefillClientName;

  const AddEditInvoiceScreen({
    super.key,
    this.invoice,
    this.prefillClientId,
    this.prefillClientName,
  });

  @override
  State<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

// ── State ──────────────────────────────────────────────────────────────────────
class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _globalPriceCtrl;

  final List<_LineItemCtrl> _lineCtrl = [];
  List<Map<String, dynamic>> _extraColumns = [];
  final List<TextEditingController> _colNameCtrls = [];
  String? _selectedClientId;
  String? _selectedClientName;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;
  List<Map<String, String>> _customFields = [];

  bool get _isEditing => widget.invoice != null;
  bool get _clientLocked => _isEditing || widget.prefillClientId != null;

  double get _globalPrice =>
      double.tryParse(_globalPriceCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;
  double get _subtotal =>
      _globalPrice > 0 ? _globalPrice : _lineCtrl.fold(0.0, (s, c) => s + c.lineTotal);
  double get _discountAmt =>
      double.tryParse(_discountCtrl.text.trim().replaceAll(' ', '')) ?? 0.0;
  double get _totalAmt =>
      (_subtotal - _discountAmt).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.invoice?.title ?? '');
    _selectedClientId =
        widget.invoice?.clientId ?? widget.prefillClientId;
    _selectedClientName =
        widget.invoice?.clientName ?? widget.prefillClientName;

    if (widget.invoice != null) {
      _dueDate = widget.invoice!.dueDate;
      _customFields = List.from(widget.invoice!.customFields);
      _extraColumns = List.from(widget.invoice!.extraColumns);
      for (final col in _extraColumns) {
        final ctrl = TextEditingController(text: col['name'] as String? ?? '');
        ctrl.addListener(_onChanged);
        _colNameCtrls.add(ctrl);
      }
      final gp = widget.invoice!.globalPrice;
      if (gp != null && gp > 0) {
        _globalPriceCtrl =
            TextEditingController(text: gp.toStringAsFixed(0));
        _lineCtrl.add(_newCtrl());
      } else {
        _globalPriceCtrl = TextEditingController();
        final items = widget.invoice!.lineItems;
        if (items.isNotEmpty) {
          for (final item in items) {
            final extraVals = <String, String>{};
            for (final col in _extraColumns) {
              final key = col['key'] as String;
              extraVals[key] = item[key] as String? ?? '';
            }
            _lineCtrl.add(_newCtrl(
              desc: item['description'] as String? ?? '',
              q: (item['qty'] as num? ?? 1).toInt(),
              pu: (item['unitPrice'] as num? ?? 0).toDouble(),
              extraVals: extraVals,
            ));
          }
        } else {
          _lineCtrl.add(_newCtrl(
            desc: widget.invoice!.title,
            q: 1,
            pu: widget.invoice!.totalAmount + widget.invoice!.discountAmount,
          ));
        }
      }
      _discountCtrl = TextEditingController(
        text: widget.invoice!.discountAmount > 0
            ? widget.invoice!.discountAmount.toStringAsFixed(0)
            : '',
      );
    } else {
      _globalPriceCtrl = TextEditingController();
      _lineCtrl.add(_newCtrl());
      _discountCtrl = TextEditingController();
    }
    _discountCtrl.addListener(_onChanged);
    _globalPriceCtrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  _LineItemCtrl _newCtrl({
    String desc = '',
    int q = 1,
    double pu = 0,
    Map<String, String> extraVals = const {},
  }) {
    final ctrl = _LineItemCtrl(desc: desc, q: q, pu: pu, extraVals: extraVals);
    for (final col in _extraColumns) {
      final key = col['key'] as String;
      ctrl.addExtra(key);
    }
    ctrl.attachListener(_onChanged);
    return ctrl;
  }

  void _removeItem(int index) {
    final ctrl = _lineCtrl[index];
    setState(() => _lineCtrl.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _discountCtrl.dispose();
    _globalPriceCtrl.dispose();
    for (final ctrl in _lineCtrl) {
      ctrl.dispose();
    }
    for (final ctrl in _colNameCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── Gestion des colonnes du tableau ───────────────────────────────────────
  void _addColumn() {
    final key = 'col_${DateTime.now().millisecondsSinceEpoch}';
    final name = 'Col. ${_extraColumns.length + 1}';
    final nameCtrl = TextEditingController(text: name);
    nameCtrl.addListener(_onChanged);
    setState(() {
      _extraColumns.add({'name': name, 'key': key});
      _colNameCtrls.add(nameCtrl);
      for (final lc in _lineCtrl) {
        lc.addExtra(key);
      }
    });
  }

  void _removeColumn(int i) {
    final key = _extraColumns[i]['key'] as String;
    _colNameCtrls[i].dispose();
    setState(() {
      _extraColumns.removeAt(i);
      _colNameCtrls.removeAt(i);
      for (final lc in _lineCtrl) {
        lc.removeExtra(key);
      }
    });
  }

  // ── Champs personnalisés ───────────────────────────────────────────────────
  Future<void> _showFieldDialog({
    String? initLabel,
    String? initValue,
    int? editIndex,
  }) async {
    final labelCtrl = TextEditingController(text: initLabel ?? '');
    final valueCtrl = TextEditingController(text: initValue ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            editIndex != null ? 'Modifier le champ' : 'Nouveau champ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Libellé',
                hintText: 'ex: Référence, TVA, Adresse...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              decoration: InputDecoration(
                labelText: 'Valeur',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (labelCtrl.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(editIndex != null ? 'Enregistrer' : 'Ajouter'),
          ),
        ],
      ),
    );

    final newLabel = labelCtrl.text.trim();
    final newValue = valueCtrl.text.trim();

    if (confirmed == true && mounted && newLabel.isNotEmpty) {
      setState(() {
        final f = {'label': newLabel, 'value': newValue};
        if (editIndex != null) {
          _customFields[editIndex] = f;
        } else {
          _customFields.add(f);
        }
      });
    }
  }

  // ── Decoration ─────────────────────────────────────────────────────────────
  InputDecoration _input(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00C6A2)),
      filled: true,
      fillColor: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : const Color(0xFFF6FBFA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  // ── Soumission ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }
    if (_totalAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le montant total doit être supérieur à 0')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final provider = context.read<InvoiceProvider>();
      final lineItems = _globalPrice > 0
          ? const <Map<String, dynamic>>[]
          : _lineCtrl.map((c) => c.toMap()).toList();
      final extraColumns = _globalPrice > 0 ? const <Map<String, dynamic>>[] : _extraColumns;
      final discount = _discountAmt;
      final amount = _totalAmt;

      if (_isEditing) {
        await provider.updateInvoice(
          widget.invoice!.copyWith(
            title: _titleCtrl.text.trim(),
            totalAmount: amount,
            dueDate: _dueDate,
            updatedAt: DateTime.now(),
            customFields: _customFields,
            lineItems: lineItems,
            extraColumns: extraColumns,
            discountAmount: discount,
            globalPrice: _globalPrice > 0 ? _globalPrice : null,
            clearGlobalPrice: _globalPrice <= 0,
          ),
        );
        if (mounted) context.pop();
      } else {
        final newInvoice = await provider.addInvoice(
          clientId: _selectedClientId!,
          clientName: _selectedClientName!,
          title: _titleCtrl.text.trim(),
          totalAmount: amount,
          dueDate: _dueDate,
          customFields: _customFields,
          lineItems: lineItems,
          extraColumns: extraColumns,
          discountAmount: discount,
          globalPrice: _globalPrice > 0 ? _globalPrice : null,
        );
        if (mounted) context.go('/invoices/${newInvoice.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Widgets lignes ─────────────────────────────────────────────────────────
  Widget _lineHeader() {
    const labelStyle = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E88E5));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Désignation', style: labelStyle),
              )),
          const Expanded(
              flex: 1,
              child: Text('Qté',
                  style: labelStyle, textAlign: TextAlign.center)),
          const Expanded(
              flex: 2,
              child: Text('PU (FCFA)',
                  style: labelStyle, textAlign: TextAlign.center)),
          for (int i = 0; i < _extraColumns.length; i++)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _colNameCtrls[i],
                      onChanged: (v) => _extraColumns[i]['name'] = v,
                      style: labelStyle,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeColumn(i),
                    child: Icon(Icons.close, size: 12, color: Colors.red[400]),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          const Expanded(
              flex: 2,
              child: Text('Total',
                  style: labelStyle, textAlign: TextAlign.end)),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _lineRow(int index, _LineItemCtrl ctrl, bool isDark) {
    final total = ctrl.lineTotal;
    final fill = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xFFF6FBFA);
    final dec = InputDecoration(
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: ctrl.description,
                style: const TextStyle(fontSize: 12),
                decoration: dec.copyWith(hintText: 'Désignation...'),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: ctrl.qty,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                decoration: dec.copyWith(hintText: '1'),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: ctrl.unitPrice,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12),
                decoration: dec.copyWith(hintText: '0'),
              ),
            ),
          ),
          for (final col in _extraColumns) ...[
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: ctrl.extras[col['key'] as String],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  decoration: dec.copyWith(hintText: '—'),
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Container(
              height: 36,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                    : const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                total > 0 ? CurrencyFormatter.format(total) : '—',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: total > 0
                      ? const Color(0xFF1E88E5)
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 24,
            child: _lineCtrl.length > 1
                ? GestureDetector(
                    onTap: () => _removeItem(index),
                    child:
                        Icon(Icons.close, size: 16, color: Colors.red[300]),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, Color color,
      {bool bold = false, bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? color : Colors.grey[700],
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            fontSize: large ? 15 : 14,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: large ? 16 : 14,
          ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xFFF6FBFA);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        title: Text(
          _isEditing ? 'Modifier facture' : 'Nouvelle facture',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),

            // CLIENT
            _clientLocked
                ? _LockedClientField(name: _selectedClientName ?? '')
                : _ClientDropdown(
                    selectedId: _selectedClientId,
                    onSelected: (id, name) => setState(() {
                      _selectedClientId = id;
                      _selectedClientName = name;
                    }),
                  ),

            const SizedBox(height: 16),

            // OBJET
            TextFormField(
              controller: _titleCtrl,
              decoration:
                  _input('Objet de la facture', Icons.description_outlined),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le titre est obligatoire'
                  : null,
            ),

            const SizedBox(height: 16),

            // ÉCHÉANCE
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF00C6A2)),
                    const SizedBox(width: 10),
                    Text(
                      DateFormatter.format(_dueDate),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // PRIX GLOBAL (raccourci)
            TextFormField(
              controller: _globalPriceCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  _input('Prix total FCFA (optionnel)', Icons.sell_outlined),
            ),

            const SizedBox(height: 20),

            // ── LIGNES DE FACTURATION ──────────────────────────────────────
            if (_globalPrice > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6A2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF00C6A2), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Prix global renseigné — lignes de détail non requises',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.table_rows_outlined,
                            size: 18, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 8),
                        const Text(
                          'Lignes de facturation',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _addColumn,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Colonne',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _lineHeader(),
                    ..._lineCtrl.asMap().entries.map(
                          (e) => _lineRow(e.key, e.value, isDark),
                        ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _lineCtrl.add(_newCtrl())),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Ajouter une ligne',
                          style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── TOTAUX ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _totalRow(
                    _globalPrice > 0 ? 'Prix global' : 'Sous-total',
                    _subtotal,
                    Colors.grey[700]!,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Réduction (FCFA)',
                          style: TextStyle(
                              color: Colors.grey[700], fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _discountCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                              hintText: '0',
                              filled: true,
                              fillColor: containerColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _totalRow(
                    'Total TTC',
                    _totalAmt,
                    const Color(0xFF1E88E5),
                    bold: true,
                    large: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── CHAMPS PERSONNALISÉS ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_outlined,
                          size: 18, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 8),
                      const Text(
                        'Champs personnalisés',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showFieldDialog(),
                        icon: const Icon(Icons.add_circle_outline,
                            size: 16),
                        label: const Text('Ajouter',
                            style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E88E5),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  if (_customFields.isEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Référence, numéro de bon, adresse... ajoutez des champs libres qui apparaîtront sur la facture.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    ..._customFields.asMap().entries.map((entry) {
                      final i = entry.key;
                      final f = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF1E88E5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF1E88E5)
                                  .withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f['label'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1E88E5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    f['value'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showFieldDialog(
                                initLabel: f['label'],
                                initValue: f['value'],
                                editIndex: i,
                              ),
                              child: const Icon(Icons.edit_outlined,
                                  size: 16, color: Color(0xFF1E88E5)),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _customFields.removeAt(i)),
                              child: Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red[300]),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // BOUTON VALIDER
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF00C6A2)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Enregistrer' : 'Créer la facture',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

