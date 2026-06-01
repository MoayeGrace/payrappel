import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _repo = UserRepository();
  UserModel? _user;
  StreamSubscription? _userSub;
  StreamSubscription? _authSub;

  static const int maxFreeClients = 30;
  static const int freeHistoryMonths = 3;

  UserModel? get user => _user;
  bool get isPro => _user?.isProActive ?? false;

  SubscriptionProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      _userSub?.cancel();
      if (firebaseUser == null) {
        _user = null;
        notifyListeners();
        return;
      }
      _userSub = _repo.watchUser().listen((u) {
        if (u == null) {
          _repo.getOrCreateUser().then((created) {
            _user = created;
            notifyListeners();
          });
        } else {
          _user = u;
          notifyListeners();
        }
      });
    });
  }

  bool canAddClient(int currentCount) => isPro || currentCount < maxFreeClients;

  // Filtre la date limite pour l'historique gratuit
  DateTime? get freeHistoryCutoff {
    if (isPro) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month - freeHistoryMonths, now.day);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
