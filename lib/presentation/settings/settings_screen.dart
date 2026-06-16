import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository();
    final isGuest = authRepo.isAnonymous;
    final email = authRepo.currentUser?.email ?? '';
    final themeProvider = context.watch<ThemeProvider>();

    final user = FirebaseAuth.instance.currentUser;
    String displayName = '';
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      displayName = user.displayName!;
    } else if (email.isNotEmpty) {
      displayName = email.split('@').first;
      displayName =
          displayName[0].toUpperCase() + displayName.substring(1);
    }
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        children: [
          // ── Bandeau profil ───────────────────────────────────────────────
          Container(
            color: const Color(0xFF1A73E8),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : 'Invité',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isGuest ? 'Mode invité' : email,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Mon entreprise ───────────────────────────────────────────────
          const _SectionHeader('Mon entreprise'),
          _SettingsTile(
            icon: Icons.business_outlined,
            iconColor: const Color(0xFF1A73E8),
            title: 'Profil entreprise',
            subtitle: 'Logo, coordonnées, infos bancaires',
            onTap: () => context.push('/settings/business'),
          ),
          _SettingsTile(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF00BFA5),
            title: 'Moyens de paiement',
            subtitle: 'Mobile money, carte, en ligne, personnalisé',
            onTap: () => context.push('/settings/payment-methods'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF7B1FA2),
            title: 'Templates de factures',
            subtitle: '15 modèles prédéfinis, personnalisables',
            onTap: () => context.push('/templates'),
          ),

          const SizedBox(height: 8),

          // ── Apparence ────────────────────────────────────────────────────
          const _SectionHeader('Apparence'),
          _SettingsCard(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.isDark
                      ? Colors.indigo.withOpacity(0.12)
                      : Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  themeProvider.isDark
                      ? Icons.dark_mode
                      : Icons.light_mode_outlined,
                  color: themeProvider.isDark ? Colors.indigo : Colors.amber,
                  size: 20,
                ),
              ),
              title: const Text(
                'Mode sombre',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                themeProvider.isDark ? 'Activé' : 'Désactivé',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              value: themeProvider.isDark,
              activeColor: const Color(0xFF1A73E8),
              onChanged: (v) =>
                  themeProvider.setMode(v ? ThemeMode.dark : ThemeMode.light),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            ),
          ),

          const SizedBox(height: 8),

          // ── Compte ───────────────────────────────────────────────────────
          if (!isGuest) ...[
            const _SectionHeader('Compte'),
            _SettingsTile(
              icon: Icons.lock_reset_outlined,
              iconColor: const Color(0xFF00BFA5),
              title: 'Réinitialiser le mot de passe',
              subtitle: 'Un email de réinitialisation sera envoyé',
              onTap: () => _resetPassword(context, email, authRepo),
            ),
          ],

          // ── Mode invité ──────────────────────────────────────────────────
          if (isGuest) ...[
            const _SectionHeader('Mode invité'),
            _SettingsTile(
              icon: Icons.person_add_outlined,
              iconColor: const Color(0xFF00BFA5),
              title: 'Créer un compte',
              subtitle: 'Sauvegardez vos données de façon permanente',
              onTap: () => context.push('/register'),
            ),
          ],

          const SizedBox(height: 8),

          // ── Session ──────────────────────────────────────────────────────
          const _SectionHeader('Session'),
          _SettingsTile(
            icon: Icons.logout,
            iconColor: Colors.orange,
            title: 'Déconnexion',
            onTap: () => _confirmLogout(context, authRepo),
            showChevron: false,
          ),

          const SizedBox(height: 8),

          // ── Zone de danger ───────────────────────────────────────────────
          const _SectionHeader('Zone de danger'),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            iconColor: Colors.red,
            title: 'Supprimer le compte',
            titleColor: Colors.red,
            subtitle: 'Action irréversible, toutes vos données seront perdues',
            onTap: () =>
                _confirmDeleteAccount(context, isGuest, email, authRepo),
            showChevron: false,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AuthRepository authRepo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            onPressed: () => ctx.pop(true),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await authRepo.logout();
      if (context.mounted) context.go('/login');
    }
  }

  Future<void> _resetPassword(
      BuildContext context, String email, AuthRepository authRepo) async {
    try {
      await authRepo.resetPassword(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email envoyé à $email')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    bool isGuest,
    String email,
    AuthRepository authRepo,
  ) async {
    if (isGuest) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Supprimer le compte ?'),
          content: const Text(
              'Toutes vos données seront définitivement supprimées.'),
          actions: [
            TextButton(
                onPressed: () => ctx.pop(false),
                child: const Text('Annuler')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => ctx.pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        try {
          await authRepo.deleteAccount();
          if (context.mounted) context.go('/login');
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur : $e')),
            );
          }
        }
      }
    } else {
      final passwordCtrl = TextEditingController();
      String? fieldError;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Confirmer la suppression'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Entrez votre mot de passe pour supprimer votre compte.'),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    errorText: fieldError,
                  ),
                  onChanged: (_) => setState(() => fieldError = null),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => ctx.pop(false),
                  child: const Text('Annuler')),
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  if (passwordCtrl.text.isEmpty) {
                    setState(() => fieldError = 'Requis');
                    return;
                  }
                  ctx.pop(true);
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ),
      );

      if (ok == true && context.mounted) {
        try {
          await authRepo.deleteAccount(
              email: email, password: passwordCtrl.text);
          if (context.mounted) context.go('/login');
        } on FirebaseAuthException catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      e.message ?? 'Erreur lors de la suppression')),
            );
          }
        }
      }
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title.toUpperCase(),
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

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]))
            : null,
        trailing: showChevron
            ? Icon(Icons.chevron_right,
                color: iconColor.withOpacity(0.5))
            : null,
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
