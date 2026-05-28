import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/repositories/auth_repository.dart';

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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepo.logout();
              if (context.mounted) context.go('/login');
            },
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
