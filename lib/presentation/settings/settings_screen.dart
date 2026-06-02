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

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // ── Mon entreprise ───────────────────────────────────────────────────
          const _SectionHeader('Mon entreprise'),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Profil entreprise'),
            subtitle: const Text('Logo, coordonnées, infos bancaires'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/business'),
          ),

          // ── Apparence ───────────────────────────────────────────────────────
          const _SectionHeader('Apparence'),
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDark
                  ? Icons.dark_mode
                  : Icons.light_mode_outlined,
            ),
            title: const Text('Mode sombre'),
            value: themeProvider.isDark,
            onChanged: (v) =>
                themeProvider.setMode(v ? ThemeMode.dark : ThemeMode.light),
          ),

          // ── Compte ──────────────────────────────────────────────────────────
          if (!isGuest) ...[
            const _SectionHeader('Compte'),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(email),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Réinitialiser le mot de passe'),
              subtitle:
                  const Text('Un lien de réinitialisation vous sera envoyé'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _resetPassword(context, email, authRepo),
            ),
          ],

          // ── Mode invité ─────────────────────────────────────────────────────
          if (isGuest) ...[
            const _SectionHeader('Mode invité'),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Créer un compte'),
              subtitle: const Text(
                  'Sauvegardez vos données de manière permanente'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/register'),
            ),
          ],

          // ── Session ─────────────────────────────────────────────────────────
          const _SectionHeader('Session'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Déconnexion',
                style: TextStyle(color: Colors.orange)),
            onTap: () => _confirmLogout(context, authRepo),
          ),

          // ── Zone de danger ──────────────────────────────────────────────────
          const _SectionHeader('Zone de danger'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: Colors.red),
            title: const Text('Supprimer le compte',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text(
                'Action irréversible, toutes vos données seront perdues'),
            onTap: () =>
                _confirmDeleteAccount(context, isGuest, email, authRepo),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AuthRepository authRepo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content:
            const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Annuler')),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: Colors.orange),
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
            title: const Text('Confirmer la suppression'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Entrez votre mot de passe pour supprimer définitivement votre compte.'),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
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
