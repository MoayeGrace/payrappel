import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/client_model.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';

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
            color: Colors.white,
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
        color: Colors.white,
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

// ── State ──────────────────────────────────────────────────────────────────────
class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;

  String? _selectedClientId;
  String? _selectedClientName;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;
  List<Map<String, String>> _customFields = [];

  bool get _isEditing => widget.invoice != null;
  bool get _clientLocked =>
      _isEditing || widget.prefillClientId != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.invoice?.title ?? '');
    _amountCtrl = TextEditingController(
      text: widget.invoice != null
          ? widget.invoice!.totalAmount.toStringAsFixed(0)
          : '',
    );
    _selectedClientId =
        widget.invoice?.clientId ?? widget.prefillClientId;
    _selectedClientName =
        widget.invoice?.clientName ?? widget.prefillClientName;
    if (widget.invoice != null) {
      _dueDate = widget.invoice!.dueDate;
      _customFields = List.from(widget.invoice!.customFields);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
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
            child:
                Text(editIndex != null ? 'Enregistrer' : 'Ajouter'),
          ),
        ],
      ),
    );

    final newLabel = labelCtrl.text.trim();
    final newValue = valueCtrl.text.trim();
    // Pas de dispose() manuel : le dialogue n'est pas encore démonté à ce
    // stade, les TextField appelleraient removeListener sur un contrôleur
    // déjà disposé. Ces variables locales sont GC'd à la fin de la fonction.

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

  // ── Soumission ─────────────────────────────────────────────────────────────
  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00C6A2)),
      filled: true,
      fillColor: const Color(0xFFF6FBFA),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un client')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final provider = context.read<InvoiceProvider>();
      final amount =
          double.parse(_amountCtrl.text.trim().replaceAll(' ', ''));

      if (_isEditing) {
        await provider.updateInvoice(
          widget.invoice!.copyWith(
            title: _titleCtrl.text.trim(),
            totalAmount: amount,
            dueDate: _dueDate,
            updatedAt: DateTime.now(),
            customFields: _customFields,
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
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
              decoration: _input(
                  'Objet de la facture', Icons.description_outlined),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le titre est obligatoire'
                  : null,
            ),

            const SizedBox(height: 16),

            // MONTANT
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _input('Montant (FCFA)', Icons.payments_outlined)
                  .copyWith(suffixText: 'FCFA'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Montant requis';
                final parsed =
                    double.tryParse(v.trim().replaceAll(' ', ''));
                if (parsed == null || parsed <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ÉCHÉANCE
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
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

            const SizedBox(height: 20),

            // ── Champs personnalisés ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Référence, numéro de bon, adresse, TVA... ajoutez des champs libres qui apparaîtront sur la facture.',
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
                          color: const Color(0xFF1E88E5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  const Color(0xFF1E88E5).withOpacity(0.2)),
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
                                  size: 16,
                                  color: Color(0xFF1E88E5)),
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
                        _isEditing
                            ? 'Enregistrer'
                            : 'Créer la facture',
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
