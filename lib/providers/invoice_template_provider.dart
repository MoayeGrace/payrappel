import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/invoice_template_model.dart';
import '../data/repositories/invoice_template_repository.dart';

class InvoiceTemplateProvider extends ChangeNotifier {
  final _repo = InvoiceTemplateRepository();
  List<InvoiceTemplateModel> _userTemplates = [];
  StreamSubscription? _sub;

  List<InvoiceTemplateModel> get builtInTemplates => BuiltInTemplates.all;

  List<InvoiceTemplateModel> get userTemplates => _userTemplates;

  List<InvoiceTemplateModel> get allTemplates => [
        ...BuiltInTemplates.all,
        ..._userTemplates,
      ];

  InvoiceTemplateModel get defaultTemplate => BuiltInTemplates.all.first;

  InvoiceTemplateProvider() {
    _sub = _repo.watchTemplates().listen((list) {
      _userTemplates = list;
      notifyListeners();
    });
  }

  InvoiceTemplateModel? findById(String id) {
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<InvoiceTemplateModel> saveCustomTemplate(
      InvoiceTemplateModel template) async {
    final newId = template.isBuiltIn
        ? 'custom_${const Uuid().v4().substring(0, 8)}'
        : template.id;
    final saved = template.copyWith(
      isBuiltIn: false,
    ).copyWith();
    final toSave = InvoiceTemplateModel(
      id: newId,
      name: saved.name,
      isBuiltIn: false,
      accentColor: saved.accentColor,
      headerBgColor: saved.headerBgColor,
      layout: saved.layout,
      titleLabel: saved.titleLabel,
      showLogo: saved.showLogo,
      showPaymentMethods: saved.showPaymentMethods,
      selectedPaymentMethodIds: saved.selectedPaymentMethodIds,
      topCenter: saved.topCenter,
      topLeft: saved.topLeft,
      topRight: saved.topRight,
      bottomLeft: saved.bottomLeft,
      bottomRight: saved.bottomRight,
      bottomCenter: saved.bottomCenter,
    );
    await _repo.saveTemplate(toSave);
    return toSave;
  }

  Future<void> deleteTemplate(String id) async {
    await _repo.deleteTemplate(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
