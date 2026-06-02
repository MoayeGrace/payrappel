import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business_profile_model.dart';

class BusinessProfileRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(_uid);

  Stream<BusinessProfileModel> watchProfile() {
    return _doc.snapshots().map((snap) {
      final data = snap.data()?['profile'] as Map<String, dynamic>?;
      return data != null
          ? BusinessProfileModel.fromMap(data)
          : const BusinessProfileModel();
    });
  }

  Future<void> saveProfile(BusinessProfileModel profile) async {
    await _doc.set({'profile': profile.toMap()}, SetOptions(merge: true));
  }
}
