import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice_template_model.dart';

class InvoiceTemplateRepository {
  static const _col = 'invoice_templates';

  CollectionReference<Map<String, dynamic>>? get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_col);
  }

  Stream<List<InvoiceTemplateModel>> watchTemplates() {
    final ref = _ref;
    if (ref == null) return const Stream.empty();
    return ref.snapshots().map(
          (snap) => snap.docs
              .map((d) => InvoiceTemplateModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> saveTemplate(InvoiceTemplateModel template) async {
    final ref = _ref;
    if (ref == null) return;
    await ref.doc(template.id).set(template.toMap());
  }

  Future<void> deleteTemplate(String id) async {
    await _ref?.doc(id).delete();
  }
}
