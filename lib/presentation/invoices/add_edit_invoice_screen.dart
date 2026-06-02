import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_sizes.dart';
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

class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;

  String? _selectedClientId;
  String? _selectedClientName;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;

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
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
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
        const SnackBar(content: Text('Veuillez sélectionner un client')),
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
          ),
        );
      } else {
        final newInvoice = await provider.addInvoice(
          clientId: _selectedClientId!,
          clientName: _selectedClientName!,
          title: _titleCtrl.text.trim(),
          totalAmount: amount,
          dueDate: _dueDate,
        );
        if (mounted) context.go('/invoices/${newInvoice.id}');
        return;
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la facture' : 'Nouvelle facture'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          children: [
            if (_clientLocked)
              _LockedClientField(name: _selectedClientName ?? '')
            else
              _ClientDropdown(
                selectedId: _selectedClientId,
                onSelected: (id, name) => setState(() {
                  _selectedClientId = id;
                  _selectedClientName = name;
                }),
              ),
            const SizedBox(height: AppSizes.paddingMedium),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Objet / titre *',
                prefixIcon: Icon(Icons.description_outlined),
                hintText: 'Ex : Prestation mars 2025',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Le titre est obligatoire'
                  : null,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant total (FCFA) *',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'FCFA',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Le montant est obligatoire';
                }
                final parsed =
                    double.tryParse(v.trim().replaceAll(' ', ''));
                if (parsed == null || parsed <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Date d'échéance *",
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormatter.format(_dueDate)),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Enregistrer' : 'Créer la facture'),
            ),
          ],
        ),
      ),
    );
  }
}

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
        return DropdownButtonFormField<String>(
          value: selectedId,
          decoration: const InputDecoration(
            labelText: 'Client *',
            prefixIcon: Icon(Icons.person_outlined),
          ),
          hint: const Text('Sélectionner un client'),
          items: clients
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final client = clients.firstWhere((c) => c.id == id);
            onSelected(client.id, client.name);
          },
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
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Client',
        prefixIcon: Icon(Icons.person_outlined),
      ),
      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
