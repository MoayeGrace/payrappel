import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../core/constants/app_sizes.dart';

class AddEditClientScreen extends StatefulWidget {
  final ClientModel? client;
  const AddEditClientScreen({super.key, this.client});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _noteCtrl;
  bool _submitting = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.client?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.client?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.client?.email ?? '');
    _noteCtrl = TextEditingController(text: widget.client?.note ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF00C6A2)),
      filled: true,
      fillColor: const Color(0xFFF6FBFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6F2F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final provider = context.read<ClientProvider>();

      if (_isEditing) {
        final updated = widget.client!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
        );
        await provider.updateClient(updated);
      } else {
        await provider.addClient(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          note: _noteCtrl.text.trim(),
        );
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
      backgroundColor: const Color(0xFFF2F7F9),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        title: Text(
          _isEditing ? 'Modifier le client' : 'Nouveau client',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          children: [

            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF00C6A2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _isEditing
                    ? "Mise à jour des informations client"
                    : "Ajoute un nouveau client à PayRappel",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingLarge),

            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDecoration('Nom complet *', Icons.person),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Le nom est obligatoire'
                      : null,
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              decoration: _inputDecoration('Téléphone *', Icons.phone),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Le téléphone est obligatoire'
                      : null,
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Email
            TextFormField(
              controller: _emailCtrl,
              decoration: _inputDecoration('Email (optionnel)', Icons.email),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: _inputDecoration('Note (optionnel)', Icons.note),
              maxLines: 3,
            ),

            const SizedBox(height: AppSizes.paddingXL),

            // Submit button (premium gradient)
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Enregistrer' : 'Ajouter le client',
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