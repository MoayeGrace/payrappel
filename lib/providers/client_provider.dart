import 'package:flutter/foundation.dart';
import '../data/models/client_model.dart';
import '../data/repositories/client_repository.dart';

class ClientProvider extends ChangeNotifier {
  final _repo = ClientRepository();

  String _searchQuery = '';
  String? _error;

  String get searchQuery => _searchQuery;
  String? get error => _error;

  Stream<List<ClientModel>> watchClients() => _repo.watchClients();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addClient({
    required String name,
    required String phone,
    String email = '',
    String note = '',
  }) async {
    await _repo.addClient(name: name, phone: phone, email: email, note: note);
  }

  Future<void> updateClient(ClientModel client) async {
    await _repo.updateClient(client);
  }

  Future<void> deleteClient(String clientId) async {
    await _repo.deleteClient(clientId);
  }

  Future<ClientModel?> getClient(String clientId) {
    return _repo.getClient(clientId);
  }
}
