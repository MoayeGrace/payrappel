import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/subscription_provider.dart';

class UpgradeScreen extends StatefulWidget {
  final String? featureHint; // ex: 'pdf', 'excel', 'whatsapp'
  const UpgradeScreen({super.key, this.featureHint});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _isAnnual = false;

  static const double _monthlyPrice = 3500;
  static const double _monthlyOriginal = 6000;
  static const double _annualPrice = 30000;
  static const double _annualOriginal = 45000;

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passer au Pro'),
        centerTitle: true,
      ),
      body: sub.isPro ? _buildAlreadyPro(context, sub) : _buildPricing(context),
    );
  }

  Widget _buildAlreadyPro(BuildContext context, SubscriptionProvider sub) {
    final expiry = sub.user?.proExpiry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.statusPaid.withOpacity(0.15),
              child: const Icon(Icons.workspace_premium, color: AppColors.statusPaid, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vous êtes Pro !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (expiry != null) ...[
              const SizedBox(height: 8),
              Text(
                'Valide jusqu\'au ${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.check),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricing(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHero(),
          if (widget.featureHint != null) _buildFeatureHint(),
          _buildFeatureList(),
          _buildPlanToggle(),
          _buildPlanCard(context),
          _buildCta(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.75),
          ],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 56),
          const SizedBox(height: 12),
          const Text(
            'PayRappel Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Déverrouillez toutes les fonctionnalités',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHint() {
    final hints = {
      'pdf': 'Export PDF disponible avec l\'offre Pro',
      'excel': 'Export Excel disponible avec l\'offre Pro',
      'whatsapp': 'Rappels WhatsApp automatiques disponibles avec l\'offre Pro',
      'history': 'Historique complet disponible avec l\'offre Pro',
      'clients': 'Clients illimités disponibles avec l\'offre Pro',
    };
    final hint = hints[widget.featureHint] ?? 'Fonctionnalité disponible avec l\'offre Pro';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      _FeatureRow('Clients', '30 max', 'Illimités'),
      _FeatureRow('Historique', '3 mois', 'Illimité'),
      _FeatureRow('Envoi WhatsApp', 'Manuel', 'Automatique'),
      _FeatureRow('Export PDF (factures)', null, 'Inclus'),
      _FeatureRow('Export PDF (reçus)', null, 'Inclus'),
      _FeatureRow('Export Excel', null, 'Inclus'),
      _FeatureRow('Rapports comptables', null, 'Inclus'),
      _FeatureRow('Notifications push', 'Inclus', 'Inclus'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparatif des offres',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Fonctionnalité', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      SizedBox(width: 80, child: Text('Gratuit', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                      SizedBox(width: 80, child: Text('Pro', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                    ],
                  ),
                ),
                ...features.asMap().entries.map((e) {
                  final isLast = e.key == features.length - 1;
                  final f = e.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.12))),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(f.label, style: const TextStyle(fontSize: 13)),
                        ),
                        SizedBox(
                          width: 80,
                          child: f.freeValue != null
                              ? Text(f.freeValue!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                              : const Icon(Icons.close, color: Colors.red, size: 16),
                        ),
                        SizedBox(
                          width: 80,
                          child: f.proValue != null
                              ? Text(f.proValue!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.statusPaid, fontWeight: FontWeight.w600))
                              : const Icon(Icons.check, color: AppColors.statusPaid, size: 16),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisir votre offre',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isAnnual = false),
                  child: _PlanToggleChip(label: 'Mensuel', selected: !_isAnnual),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isAnnual = true),
                  child: _PlanToggleChip(
                    label: 'Annuel',
                    selected: _isAnnual,
                    badge: '-33%',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context) {
    final price = _isAnnual ? _annualPrice : _monthlyPrice;
    final original = _isAnnual ? _annualOriginal : _monthlyOriginal;
    final period = _isAnnual ? 'an' : 'mois';
    final monthlyEquivalent = _isAnnual ? (_annualPrice / 12) : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _isAnnual ? 'Abonnement annuel' : 'Abonnement mensuel',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(price),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/$period',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Prix normal : ${CurrencyFormatter.format(original)}/$period',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.white.withOpacity(0.7),
                ),
              ),
              if (monthlyEquivalent != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '≈ ${CurrencyFormatter.format(monthlyEquivalent)}/mois',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text(
                'Choisir un moyen de paiement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showPaymentMethodSheet(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Paiement sécurisé · Résiliation à tout moment',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodSheet(BuildContext context) {
    final methods = [
      _PaymentMethod('Wave', Icons.waves, Colors.blue),
      _PaymentMethod('Orange Money', Icons.mobile_friendly, Colors.deepOrange),
      _PaymentMethod('MTN Mobile Money', Icons.smartphone, Colors.amber[700]!),
      _PaymentMethod('Moov Money', Icons.account_balance_wallet, Colors.indigo),
      _PaymentMethod('Djamo (Visa/Mastercard)', Icons.credit_card, Colors.teal),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Moyen de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _isAnnual
                  ? '30 000 FCFA/an'
                  : '3 500 FCFA/mois',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...methods.map((m) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: CircleAvatar(
                backgroundColor: m.color.withOpacity(0.12),
                child: Icon(m.icon, color: m.color, size: 22),
              ),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _showComingSoon(context, m.name);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paiement en cours de déploiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Méthode sélectionnée : $method'),
            const SizedBox(height: 12),
            const Text(
              'Le module de paiement Jeko est en cours d\'activation. '
              'Vous serez notifié dès qu\'il sera disponible.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow {
  final String label;
  final String? freeValue;
  final String? proValue;
  const _FeatureRow(this.label, this.freeValue, this.proValue);
}

class _PlanToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final String? badge;
  const _PlanToggleChip({required this.label, required this.selected, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.25) : AppColors.statusPaid.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.statusPaid,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final String name;
  final IconData icon;
  final Color color;
  const _PaymentMethod(this.name, this.icon, this.color);
}
