import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/currency_formatter.dart';
import '../data/models/business_profile_model.dart';
import '../data/repositories/business_profile_repository.dart';

class BusinessProfileProvider extends ChangeNotifier {
  final _repo = BusinessProfileRepository();
  BusinessProfileModel _profile = const BusinessProfileModel();
  StreamSubscription? _sub;

  BusinessProfileModel get profile => _profile;

  BusinessProfileProvider() {
    _sub = _repo.watchProfile().listen((p) {
      _profile = p;
      CurrencyFormatter.setCurrency(p.currency);
      notifyListeners();
    });
  }

  Future<void> save(BusinessProfileModel profile) async {
    await _repo.saveProfile(profile);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
