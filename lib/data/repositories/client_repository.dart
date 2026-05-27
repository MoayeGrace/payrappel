import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/client_model.dart';

class ClientRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(_uid).collection('clients');

  // Écoute en temps réel la liste des clients
  Stream<List<ClientModel>> watchClients() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Lire un client par son ID
  Future<ClientModel?> getClient(String clientId) async {
    final doc = await _collection.doc(clientId).get();
    if (!doc.exists) return null;
    return ClientModel.fromMap(doc.data()!, doc.id);
  }

  // Ajouter un client
  Future<ClientModel> addClient({
    required String name,
    required String phone,
    String email = '',
    String note = '',
  }) async {
    final id = _uuid.v4();
    final client = ClientModel(
      id: id,
      userId: _uid,
      name: name,
      phone: phone,
      email: email,
      note: note,
      createdAt: DateTime.now(),
    );
    await _collection.doc(id).set(client.toMap());
    return client;
  }

  // Modifier un client
  Future<void> updateClient(ClientModel client) async {
    await _collection.doc(client.id).update(client.toMap());
  }

  // Supprimer un client
  Future<void> deleteClient(String clientId) async {
    await _collection.doc(clientId).delete();
  }

  // Rechercher des clients par nom
  Future<List<ClientModel>> searchClients(String query) async {
    final snap = await _collection.orderBy('name').get();
    final lowerQuery = query.toLowerCase();
    return snap.docs
        .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            c.phone.contains(query))
        .toList();
  }
}
