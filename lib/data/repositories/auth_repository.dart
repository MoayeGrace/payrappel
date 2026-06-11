import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // Connexion classique
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Création de compte
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Mode invité — accès sans compte
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Convertir un invité en vrai compte (conserve toutes ses données)
  Future<UserCredential> linkGuestToEmail({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    return await _auth.currentUser!.linkWithCredential(credential);
  }

  // Envoyer un email de vérification
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Supprimer le compte (avec ré-authentification pour les comptes email)
  Future<void> deleteAccount({String? email, String? password}) async {
    if (email != null && password != null) {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    }
    await _auth.currentUser!.delete();
  }
}
