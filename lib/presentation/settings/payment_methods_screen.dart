import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/payment_method_model.dart';
import '../../providers/business_profile_provider.dart';

const _blue = Color(0xFF1A73E8);
const _teal = Color(0xFF00BFA5);

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Moyens de paiement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<BusinessProfileProvider>(
        builder: (context, provider, _) {
          final methods = provider.profile.paymentMethods;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête explicatif
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withOpacity(0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: _blue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Configurez les moyens de paiement que vous acceptez. Ils seront affichés sur vos factures.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Liste des méthodes configurées
              if (methods.isNotEmpty) ...[
                const _SectionLabel('Vos moyens de paiement'),
                const SizedBox(height: 8),
                ...methods.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final m = entry.value;
                  return _MethodTile(
                    method: m,
                    onToggle: (enabled) =>
                        _updateMethod(context, provider, idx,
                            m.copyWith(isEnabled: enabled)),
                    onEdit: () => _openEditor(context, provider,
                        existing: m, index: idx),
                    onDelete: () =>
                        _deleteMethod(context, provider, idx),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Ajouter un moyen prédéfini
              const _SectionLabel('Ajouter un moyen de paiement'),
              const SizedBox(height: 8),
              _AddGrid(
                existing: methods,
                onTap: (type) => _openEditor(context, provider,
                    prefillType: type),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateMethod(BuildContext context, BusinessProfileProvider provider,
      int index, PaymentMethodModel updated) {
    final list = List<PaymentMethodModel>.from(
        provider.profile.paymentMethods);
    list[index] = updated;
    provider.save(provider.profile.copyWith(paymentMethods: list));
  }

  Future<void> _deleteMethod(BuildContext context,
      BusinessProfileProvider provider, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce moyen de paiement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final list = List<PaymentMethodModel>.from(
          provider.profile.paymentMethods);
      list.removeAt(index);
      provider.save(provider.profile.copyWith(paymentMethods: list));
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    BusinessProfileProvider provider, {
    PaymentMethodModel? existing,
    int? index,
    PaymentMethodType? prefillType,
  }) async {
    final result = await showModalBottomSheet<PaymentMethodModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MethodEditorSheet(
        existing: existing,
        prefillType: prefillType ?? existing?.type ?? PaymentMethodType.custom,
      ),
    );
    if (result != null && context.mounted) {
      final list = List<PaymentMethodModel>.from(
          provider.profile.paymentMethods);
      if (index != null) {
        list[index] = result;
      } else {
        list.add(result);
      }
      await provider.save(provider.profile.copyWith(paymentMethods: list));
    }
  }
}

// ── Grille d'ajout ─────────────────────────────────────────────────────────────
class _AddGrid extends StatelessWidget {
  final List<PaymentMethodModel> existing;
  final void Function(PaymentMethodType) onTap;

  const _AddGrid({required this.existing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const allTypes = PaymentMethodType.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: allTypes.length,
      itemBuilder: (_, i) {
        final type = allTypes[i];
        final alreadyAdded = existing.any((m) =>
            m.type == type && type != PaymentMethodType.custom);
        return GestureDetector(
          onTap: alreadyAdded ? null : () => onTap(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: alreadyAdded
                  ? Colors.grey.shade100
                  : type.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: alreadyAdded
                    ? Colors.grey.shade200
                    : type.color.withOpacity(0.25),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (alreadyAdded)
                  Icon(Icons.check_circle_outline,
                      color: Colors.grey[400], size: 22)
                else if (type.assetPath != null)
                  Image.asset(type.assetPath!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(type.icon, color: type.color, size: 22))
                else
                  Icon(type.icon, color: type.color, size: 22),
                const SizedBox(height: 6),
                Text(
                  type.defaultLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: alreadyAdded ? Colors.grey[400] : type.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tuile méthode configurée ───────────────────────────────────────────────────
class _MethodTile extends StatelessWidget {
  final PaymentMethodModel method;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MethodTile({
    required this.method,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  static Widget _buildMethodLogo(PaymentMethodModel method) {
    final color = method.type.color;
    if (method.type == PaymentMethodType.custom &&
        method.logoPath != null &&
        File(method.logoPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(method.logoPath!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(method.type.icon, color: color, size: 20),
          ),
        ),
      );
    }
    final assetPath = method.type.assetPath;
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          assetPath,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(method.type.icon, color: color, size: 20),
          ),
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(method.type.icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = method.fields['phone'];
    final subtitle = phone != null && phone.isNotEmpty
        ? phone
        : method.fields.values.where((v) => v.isNotEmpty).firstOrNull ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: _buildMethodLogo(method),
        title: Text(
          method.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: method.isEnabled,
              onChanged: onToggle,
              activeColor: _teal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: Colors.grey[500],
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red[300],
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Éditeur / ajout ────────────────────────────────────────────────────────────
class _MethodEditorSheet extends StatefulWidget {
  final PaymentMethodModel? existing;
  final PaymentMethodType prefillType;

  const _MethodEditorSheet({this.existing, required this.prefillType});

  @override
  State<_MethodEditorSheet> createState() => _MethodEditorSheetState();
}

class _MethodEditorSheetState extends State<_MethodEditorSheet> {
  late PaymentMethodType _type;
  late TextEditingController _labelCtrl;
  late Map<String, TextEditingController> _fieldCtrls;
  String? _logoPath;

  // Pour les moyens personnalisés : champs libres
  List<Map<String, dynamic>> _customFields = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = widget.prefillType;
    _labelCtrl = TextEditingController(
        text: existing?.label ?? _type.defaultLabel);
    _logoPath = existing?.logoPath;

    _fieldCtrls = {};
    for (final def in _type.fieldDefs) {
      _fieldCtrls[def.key] = TextEditingController(
          text: existing?.fields[def.key] ?? '');
    }

    if (_type == PaymentMethodType.custom && existing != null) {
      _customFields = existing.fields.entries
          .map((e) => {'key': e.key, 'value': e.value})
          .toList();
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/pm_custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(dest);
    if (mounted) setState(() => _logoPath = dest);
  }

  void _submit() {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;

    Map<String, String> fields;
    if (_type == PaymentMethodType.custom) {
      fields = {
        for (final f in _customFields)
          if ((f['key'] as String).isNotEmpty)
            f['key'] as String: f['value'] as String,
      };
    } else {
      fields = {
        for (final e in _fieldCtrls.entries) e.key: e.value.text.trim(),
      };
    }

    final result = PaymentMethodModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      type: _type,
      label: label,
      fields: fields,
      logoPath: _logoPath,
      isEnabled: widget.existing?.isEnabled ?? true,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final color = _type.color;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_type.icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing
                        ? 'Modifier ${widget.existing!.label}'
                        : 'Ajouter ${_type.defaultLabel}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nom affiché
            _inputField(
              controller: _labelCtrl,
              label: 'Nom affiché',
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 12),

            // Champs prédéfinis
            for (final def in _type.fieldDefs) ...[
              _inputField(
                controller: _fieldCtrls[def.key]!,
                label: def.label,
                hint: def.hint,
                icon: _type.icon,
                keyboardType: def.keyboardType,
              ),
              const SizedBox(height: 12),
            ],

            // Champs personnalisés (type custom uniquement)
            if (_type == PaymentMethodType.custom) ...[
              _buildCustomFields(),
              const SizedBox(height: 12),
              // Logo personnalisé
              _buildLogoSection(),
              const SizedBox(height: 12),
            ],

            // Bouton valider
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isEditing ? 'Enregistrer' : 'Ajouter',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _teal, size: 18),
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
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
    );
  }

  Widget _buildCustomFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Informations à afficher',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() =>
                  _customFields.add({'key': '', 'value': ''})),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: _blue,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _customFields.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => _customFields[i]['key'] = v,
                  controller: TextEditingController(
                      text: _customFields[i]['key'] as String),
                  decoration: InputDecoration(
                    hintText: 'Libellé',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    hintStyle:
                        TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (v) => _customFields[i]['value'] = v,
                  controller: TextEditingController(
                      text: _customFields[i]['value'] as String),
                  decoration: InputDecoration(
                    hintText: 'Valeur',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    hintStyle:
                        TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: Colors.red[300]),
                onPressed: () =>
                    setState(() => _customFields.removeAt(i)),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildLogoSection() {
    final hasLogo =
        _logoPath != null && File(_logoPath!).existsSync();
    return Row(
      children: [
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              image: hasLogo
                  ? DecorationImage(
                      image: FileImage(File(_logoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasLogo
                ? null
                : Icon(Icons.add_a_photo_outlined,
                    color: Colors.grey[400], size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: _pickLogo,
              style: TextButton.styleFrom(
                foregroundColor: _blue,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(hasLogo ? 'Changer le logo' : 'Ajouter un logo',
                  style: const TextStyle(fontSize: 13)),
            ),
            if (hasLogo)
              TextButton(
                onPressed: () =>
                    setState(() => _logoPath = null),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Supprimer',
                    style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.8,
      ),
    );
  }
}
