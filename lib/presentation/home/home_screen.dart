import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
    final user = FirebaseAuth.instance.currentUser;

    String firstName = 'vous';
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        firstName = user.displayName!.split(' ').first;
      } else if (user.email != null && user.email!.isNotEmpty) {
        final name = user.email!.split('@').first;
        firstName = name[0].toUpperCase() + name.substring(1);
      }
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _HomeAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _WelcomeBanner(name: firstName),
                  if (isGuest) ...[
                    const SizedBox(height: 12),
                    const _GuestBanner(),
                  ],
                  const SizedBox(height: 24),
                  const _StatsSection(),
                  const SizedBox(height: 24),
                  const _MenuSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _showNewModal(context),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  static void _showNewModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Créer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _ModalTile(
              icon: Icons.people_outlined,
              label: 'Nouveau client',
              color: const Color(0xFF1A73E8),
              onTap: () {
                Navigator.pop(modalCtx);
                context.push('/clients/add');
              },
            ),
            const SizedBox(height: 4),
            _ModalTile(
              icon: Icons.receipt_long_outlined,
              label: 'Nouvelle facture',
              color: const Color(0xFF43A047),
              onTap: () {
                Navigator.pop(modalCtx);
                context.push('/invoices/add');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modal tile ─────────────────────────────────────────────────────────────────
class _ModalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModalTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ── Custom AppBar ──────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Pay',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                TextSpan(
                  text: 'Rappel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFA5),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF757575)),
            onPressed: () => context.push('/settings'),
            tooltip: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

// ── Welcome Banner ─────────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Icône portefeuille
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
          // Texte
          Positioned(
            left: 20,
            top: 24,
            right: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Voici la situation de votre activité aujourd'hui.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guest Banner ───────────────────────────────────────────────────────────────
class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Mode invité — créez un compte pour sauvegarder vos données.",
              style: TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/register'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Créer', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Stats Section ──────────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  const _StatsSection();

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

            final lateAmount = invoices
                .where((i) => i.status == InvoiceStatus.late)
                .fold(0.0, (sum, i) => sum + i.remainingAmount);

            final monthPayments = payments
                .where((p) =>
                    p.paidAt.year == now.year &&
                    p.paidAt.month == now.month)
                .fold(0.0, (sum, p) => sum + p.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vue d'ensemble",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'À encaisser',
                        value: CurrencyFormatter.format(totalToCollect),
                        subtitle: 'Total dû par les clients',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'En retard',
                        value: CurrencyFormatter.format(lateAmount),
                        subtitle: 'Créances échues',
                        icon: Icons.access_time_outlined,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Paiements reçus',
                        value: CurrencyFormatter.format(monthPayments),
                        subtitle: 'Ce mois-ci',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF43A047),
                      ),
                    ),
                  ],
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
  final String subtitle;
  final IconData icon;
  final Color color;
  final double valueFontSize; // 👈 AJOUT

  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.valueFontSize = 40, // 👈 default
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Menu Section ───────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    final items = <_MenuEntry>[
      _MenuEntry(Icons.people_outlined, 'Clients', 'Gérer vos clients',
          const Color(0xFF1A73E8), () => context.push('/clients')),
      _MenuEntry(Icons.receipt_long_outlined, 'Factures',
          'Créer et suivre vos factures',
          const Color(0xFF43A047), () => context.push('/invoices')),
      _MenuEntry(Icons.payments_outlined, 'Paiements',
          'Historique de vos paiements',
          const Color(0xFF00ACC1), () => context.push('/payments')),
      _MenuEntry(Icons.notifications_active_outlined, 'Rappels',
          'Programmer des rappels de paiement',
          const Color(0xFF7C4DFF), () => context.push('/reminders')),
      _MenuEntry(Icons.download_outlined, 'Export',
          'Exporter en Excel ou PDF',
          const Color(0xFF00897B), () => context.push('/export')),
    ];

    return Column(
      children: [
        for (final e in items) ...[
          _MenuTile(entry: e),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuEntry(
      this.icon, this.label, this.subtitle, this.color, this.onTap);
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: entry.onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: entry.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(entry.icon, color: entry.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      entry.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: entry.color.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation ──────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Accueil',
                selected: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.people_outlined,
                label: 'Clients',
                onTap: () => context.push('/clients'),
              ),
            ),
            const Expanded(child: SizedBox()), // espace pour le FAB
            Expanded(
              child: _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Factures',
                onTap: () => context.push('/invoices'),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.bar_chart_outlined,
                label: 'Rapports',
                onTap: () => context.push('/export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF1A73E8) : Colors.grey.shade500;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected && selectedIcon != null ? selectedIcon! : icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
