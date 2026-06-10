import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../data/models/business_profile_model.dart';
import '../../providers/business_profile_provider.dart';

const _blue = Color(0xFF1A73E8);
const _teal = Color(0xFF00BFA5);

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
          const SnackBar(
            content: Text('Profil entreprise sauvegardé'),
            backgroundColor: _teal,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = _logoPath != null && File(_logoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Profil entreprise',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // ── Bandeau logo ─────────────────────────────────────────────────
            Container(
              color: _blue,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 2),
                            image: hasLogo
                                ? DecorationImage(
                                    image: FileImage(File(_logoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: hasLogo
                              ? null
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_a_photo_outlined,
                                        color: Colors.white, size: 28),
                                    SizedBox(height: 4),
                                    Text(
                                      'Logo',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                        ),
                        if (hasLogo)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _teal,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasLogo ? 'Appuyez pour changer le logo' : 'Ajouter un logo',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (hasLogo) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => setState(() => _logoPath = null),
                      icon: const Icon(Icons.delete_outline,
                          size: 14, color: Colors.white60),
                      label: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Informations entreprise ──────────────────────────────────────
            _SectionLabel('Informations entreprise'),
            _FormCard(
              children: [
                _Field(
                  controller: _companyCtrl,
                  label: "Nom de l'entreprise *",
                  icon: Icons.business_outlined,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                _Field(
                  controller: _ownerCtrl,
                  label: 'Nom du responsable',
                  icon: Icons.person_outlined,
                  capitalization: TextCapitalization.words,
                ),
                _Field(
                  controller: _addressCtrl,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  isLast: false,
                ),
                _Field(
                  controller: _phoneCtrl,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                _Field(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                _Field(
                  controller: _rccmCtrl,
                  label: 'RCCM / NIF (optionnel)',
                  icon: Icons.badge_outlined,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Informations bancaires ───────────────────────────────────────
            _SectionLabel('Coordonnées bancaires (optionnel)'),
            _FormCard(
              children: [
                _Field(
                  controller: _bankNameCtrl,
                  label: 'Nom de la banque',
                  icon: Icons.account_balance_outlined,
                  capitalization: TextCapitalization.words,
                ),
                _Field(
                  controller: _bankAccountCtrl,
                  label: 'Numéro de compte',
                  icon: Icons.credit_card_outlined,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Pied de page PDF ─────────────────────────────────────────────
            _SectionLabel('Pied de page de vos factures'),
            _FormCard(
              children: [
                _Field(
                  controller: _footerCtrl,
                  label: 'Message de bas de page (optionnel)',
                  icon: Icons.notes_outlined,
                  hint: 'Ex : Merci pour votre confiance !',
                  maxLines: 2,
                  isLast: true,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Bouton enregistrer ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_blue, _teal],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Enregistrement...' : 'Enregistrer le profil',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final int maxLines;
  final bool isLast;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.isLast = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon, color: _teal, size: 20),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _blue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFE53935), width: 1.5),
              ),
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey[100],
          ),
      ],
    );
  }
}
