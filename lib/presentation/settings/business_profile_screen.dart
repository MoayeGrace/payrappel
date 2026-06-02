import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/business_profile_model.dart';
import '../../providers/business_profile_provider.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _rccmCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _footerCtrl;

  String? _logoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<BusinessProfileProvider>().profile;
    _companyCtrl = TextEditingController(text: p.companyName);
    _ownerCtrl = TextEditingController(text: p.ownerName);
    _addressCtrl = TextEditingController(text: p.address);
    _phoneCtrl = TextEditingController(text: p.phone);
    _emailCtrl = TextEditingController(text: p.email);
    _rccmCtrl = TextEditingController(text: p.rccm);
    _bankNameCtrl = TextEditingController(text: p.bankName);
    _bankAccountCtrl = TextEditingController(text: p.bankAccount);
    _footerCtrl = TextEditingController(text: p.footerText);
    _logoPath = p.logoPath;
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _ownerCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _rccmCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/business_logo.jpg';
    await File(picked.path).copy(dest);
    setState(() => _logoPath = dest);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final profile = BusinessProfileModel(
        companyName: _companyCtrl.text.trim(),
        ownerName: _ownerCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        rccm: _rccmCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        bankAccount: _bankAccountCtrl.text.trim(),
        footerText: _footerCtrl.text.trim(),
        logoPath: _logoPath,
      );
      await context.read<BusinessProfileProvider>().save(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil entreprise sauvegardé')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil entreprise'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Logo ────────────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _logoPath != null && File(_logoPath!).existsSync()
                          ? FileImage(File(_logoPath!))
                          : null,
                      child: _logoPath == null || !File(_logoPath!).existsSync()
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    size: 28, color: AppColors.primary),
                                const SizedBox(height: 4),
                                Text('Logo',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  if (_logoPath != null && File(_logoPath!).existsSync())
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_logoPath != null)
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _logoPath = null),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Supprimer le logo'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            const SizedBox(height: 24),

            // ── Informations entreprise ──────────────────────────────────────
            _SectionLabel('Informations entreprise'),
            TextFormField(
              controller: _companyCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entreprise *',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ownerCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du responsable',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rccmCtrl,
              decoration: const InputDecoration(
                labelText: 'RCCM / NIF (optionnel)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ── Informations bancaires ───────────────────────────────────────
            _SectionLabel('Coordonnées bancaires (optionnel)'),
            TextFormField(
              controller: _bankNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la banque',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankAccountCtrl,
              decoration: const InputDecoration(
                labelText: 'Numéro de compte',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ── Pied de page PDF ─────────────────────────────────────────────
            _SectionLabel('Pied de page de vos factures'),
            TextFormField(
              controller: _footerCtrl,
              decoration: const InputDecoration(
                labelText: 'Message de bas de page (optionnel)',
                hintText: 'Ex : Merci pour votre confiance !',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Enregistrer le profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
