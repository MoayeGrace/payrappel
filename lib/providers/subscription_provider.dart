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

  UserModel? get user => _user;

  // Tout est gratuit — pas de limite, pas de Pro
  bool get isPro => true;

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

  @override
  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
