import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_model.dart';

class ReminderRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('reminders');

  // Tous les rappels, en temps réel
  Stream<List<ReminderModel>> watchReminders() {
    return _collection
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Rappels non encore envoyés
  Stream<List<ReminderModel>> watchPendingReminders() {
    return _collection
        .where('isSent', isEqualTo: false)
        .orderBy('scheduledAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Créer un rappel
  Future<ReminderModel> addReminder({
    required String invoiceId,
    required String clientId,
    required String clientName,
    required String invoiceTitle,
    required double remainingAmount,
    required ReminderType type,
    required DateTime scheduledAt,
    ReminderChannel channel = ReminderChannel.push,
  }) async {
    final id = _uuid.v4();
    final reminder = ReminderModel(
      id: id,
      userId: _uid,
      invoiceId: invoiceId,
      clientId: clientId,
      clientName: clientName,
      invoiceTitle: invoiceTitle,
      remainingAmount: remainingAmount,
      type: type,
      channel: channel,
      scheduledAt: scheduledAt,
    );
    await _collection.doc(id).set(reminder.toMap());
    return reminder;
  }

  // Marquer un rappel comme envoyé
  Future<void> markAsSent(String reminderId) async {
    await _collection.doc(reminderId).update({
      'isSent': true,
      'sentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Supprimer un rappel
  Future<void> deleteReminder(String reminderId) async {
    await _collection.doc(reminderId).delete();
  }
}
