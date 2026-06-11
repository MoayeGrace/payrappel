import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_authRepo.isAnonymous) {
        await _authRepo.linkGuestToEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authRepo.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      // Envoyer la vérification email (sauf pour les comptes liés invité)
      try {
        await _authRepo.sendEmailVerification();
      } catch (_) {}

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: Color(0xFF1A73E8)),
                ),
                const SizedBox(width: 12),
                const Text('Email envoyé',
                    style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Text(
              'Un lien de vérification a été envoyé à\n${_emailController.text.trim()}\n\nVérifiez votre boîte mail et cliquez sur le lien.',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  ctx.pop();
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continuer',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _errorMessage(String error) {
    if (error.contains('email-already-in-use')) return 'Cet email est déjà utilisé.';
    if (error.contains('invalid-email')) return 'Email invalide.';
    if (error.contains('weak-password')) return 'Mot de passe trop faible.';
    if (error.contains('credential-already-in-use')) return 'Ce compte existe déjà.';
    return 'Erreur lors de la création du compte.';
  }

  @override
  Widget build(BuildContext context) {
  final isGuest = _authRepo.isAnonymous;

  return Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF4F9FF),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A73E8),
                      Color(0xFF34A853),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331A73E8),
                      blurRadius: 25,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      isGuest
                          ? "Sauvegarder mes données"
                          : "Créer un compte",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isGuest
                          ? "Créez un compte pour conserver toutes vos données"
                          : "Rejoignez PayRappel gratuitement",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // FORM CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "Adresse email",
                          prefixIcon:
                              const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty
                                ? 'Email requis'
                                : null,
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Mot de passe",
                          prefixIcon:
                              const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword =
                                  !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6
                                ? 'Minimum 6 caractères'
                                : null,
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "Confirmer le mot de passe",
                          prefixIcon:
                              const Icon(Icons.verified_user_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) =>
                            v != _passwordController.text
                                ? 'Les mots de passe ne correspondent pas'
                                : null,
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1A73E8),
                                Color(0xFF34A853),
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x331A73E8),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.transparent,
                              shadowColor:
                                  Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    isGuest
                                        ? "Sauvegarder et créer mon compte"
                                        : "Créer mon compte",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    "Déjà un compte ? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      "Se connecter",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
