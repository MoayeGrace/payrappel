import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  Future<UserModel?> getUser() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> saveUser(UserModel user) async {
    await _userDoc.set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateActivity({
    required String activityName,
    required String activityType,
    required String displayName,
  }) async {
    await _userDoc.update({
      'activityName': activityName,
      'activityType': activityType,
      'displayName': displayName,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Crée le profil lors de la première connexion
  Future<void> createIfNotExists() async {
    final doc = await _userDoc.get();
    if (doc.exists) return;

    final user = _auth.currentUser!;
    final newUser = UserModel(
      id: _uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      activityName: '',
      activityType: '',
      createdAt: DateTime.now(),
    );
    await _userDoc.set(newUser.toMap());
  }
}
