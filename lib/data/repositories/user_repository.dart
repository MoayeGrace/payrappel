import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(_uid);

  Stream<UserModel?> watchUser() => _doc.snapshots().map(
        (snap) => snap.exists ? UserModel.fromMap(snap.data()!, snap.id) : null,
      );

  Future<UserModel> getOrCreateUser() async {
    final snap = await _doc.get();
    if (snap.exists) return UserModel.fromMap(snap.data()!, snap.id);
    final user = UserModel(id: _uid);
    await _doc.set(user.toMap());
    return user;
  }

  Future<void> updateProStatus({
    required bool isPro,
    DateTime? proExpiry,
    String? planType,
  }) async {
    await _doc.set({
      'isPro': isPro,
      if (proExpiry != null) 'proExpiry': proExpiry.millisecondsSinceEpoch,
      if (planType != null) 'planType': planType,
    }, SetOptions(merge: true));
  }
}
