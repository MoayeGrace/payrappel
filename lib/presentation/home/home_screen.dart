import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository();
    final isGuest = authRepo.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayRappel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          if (isGuest)
            Container(
              margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: AppSizes.paddingSmall),
                  const Expanded(
                    child: Text(
                      'Mode invité — vos données ne seront pas sauvegardées si vous désinstallez l\'app.',
                      style: TextStyle(fontSize: AppSizes.fontSmall),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Créer un compte'),
                  ),
                ],
              ),
            ),
          const _DashboardSection(),
          const SizedBox(height: AppSizes.paddingLarge),
          const Divider(),
          const SizedBox(height: AppSizes.paddingMedium),
          _MenuCard(
            icon: Icons.people,
            label: 'Clients',
            description: 'Gérer vos clients',
            color: AppColors.primary,
            onTap: () => context.push('/clients'),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _MenuCard(
            icon: Icons.receipt_long,
            label: 'Factures',
            description: 'Créer et suivre vos factures',
            color: AppColors.accent,
            onTap: () => context.push('/invoices'),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _MenuCard(
            icon: Icons.payments,
            label: 'Paiements',
            description: 'Historique de vos paiements',
            color: AppColors.statusPaid,
            onTap: () => context.push('/payments'),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _MenuCard(
            icon: Icons.notifications_active_outlined,
            label: 'Rappels',
            description: 'Programmer des rappels de paiement',
            color: Colors.deepPurple,
            onTap: () => context.push('/reminders'),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _MenuCard(
            icon: Icons.download_outlined,
            label: 'Export',
            description: 'Exporter en Excel ou PDF',
            color: Colors.teal,
            onTap: () => context.push('/export'),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InvoiceModel>>(
      stream: context.read<InvoiceProvider>().watchInvoices(),
      builder: (context, invoiceSnap) {
        return StreamBuilder<List<PaymentModel>>(
          stream: context.read<PaymentProvider>().watchAllPayments(),
          builder: (context, paymentSnap) {
            final invoices = invoiceSnap.data ?? [];
            final payments = paymentSnap.data ?? [];
            final now = DateTime.now();

            final totalToCollect = invoices
                .where((i) => !i.isFullyPaid)
                .fold(0.0, (sum, i) => sum + i.remainingAmount);

            final lateInvoices = invoices
                .where((i) => i.status == InvoiceStatus.late)
                .toList();
            final lateAmount = lateInvoices.fold(
                0.0, (sum, i) => sum + i.remainingAmount);

            final monthPayments = payments
                .where((p) =>
                    p.paidAt.year == now.year &&
                    p.paidAt.month == now.month)
                .fold(0.0, (sum, p) => sum + p.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    fontSize: AppSizes.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'À encaisser',
                        value: CurrencyFormatter.format(totalToCollect),
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'En retard',
                        value: CurrencyFormatter.format(lateAmount),
                        subtitle: lateInvoices.isEmpty
                            ? null
                            : '${lateInvoices.length} facture${lateInvoices.length > 1 ? 's' : ''}',
                        icon: Icons.warning_amber_outlined,
                        color: AppColors.statusLate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _StatCard(
                  label: 'Paiements reçus ce mois',
                  value: CurrencyFormatter.format(monthPayments),
                  icon: Icons.payments_outlined,
                  color: AppColors.statusPaid,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.fontMedium,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      child: ListTile(
        enabled: enabled,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(enabled ? 0.15 : 0.07),
          child: Icon(icon, color: enabled ? color : Colors.grey),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Text(description),
        trailing: enabled ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
