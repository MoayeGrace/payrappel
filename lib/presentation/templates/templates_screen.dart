import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/invoice_template_model.dart';
import '../../providers/invoice_template_provider.dart';
import 'template_preview_widget.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text('Templates de factures',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Consumer<InvoiceTemplateProvider>(
        builder: (context, prov, _) {
          final builtins = prov.builtInTemplates;
          final custom = prov.userTemplates;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoBanner(),
              const SizedBox(height: 20),
              _SectionLabel('Templates prédéfinis'),
              _TemplateGrid(
                templates: builtins,
                onEdit: (t) => context.push('/templates/edit', extra: t),
              ),
              if (custom.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionLabel('Mes templates'),
                _TemplateGrid(
                  templates: custom,
                  onEdit: (t) => context.push('/templates/edit', extra: t),
                  onDelete: (t) => _confirmDelete(context, prov, t),
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      InvoiceTemplateProvider prov, InvoiceTemplateModel template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce template ?'),
        content: Text('« ${template.name} » sera supprimé définitivement.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => ctx.pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await prov.deleteTemplate(template.id);
    }
  }
}

// ── Info banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.description_outlined, color: Colors.white, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Templates de factures',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                SizedBox(height: 2),
                Text(
                    'Choisissez un style, personnalisez-le. Modifier un template prédéfini crée une copie.',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

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

// ── Template grid ────────────────────────────────────────────────────────────

class _TemplateGrid extends StatelessWidget {
  final List<InvoiceTemplateModel> templates;
  final ValueChanged<InvoiceTemplateModel> onEdit;
  final ValueChanged<InvoiceTemplateModel>? onDelete;

  const _TemplateGrid({
    required this.templates,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final t = templates[index];
        return _TemplateCard(
          template: t,
          onEdit: () => onEdit(t),
          onDelete: onDelete != null ? () => onDelete!(t) : null,
        );
      },
    );
  }
}

// ── Template card ─────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final InvoiceTemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  TemplateMiniPreview(template: template),
                  if (!template.isBuiltIn)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 10),
                        ),
                      ),
                    ),
                  // Edit overlay on tap
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onEdit,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.black.withOpacity(0.15),
                            child: const Text(
                              'Personnaliser',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            template.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
