import 'package:flutter/foundation.dart';
import '../core/services/notification_service.dart';
import '../data/models/reminder_model.dart';
import '../data/repositories/reminder_repository.dart';

class ReminderProvider extends ChangeNotifier {
  final _repo = ReminderRepository();

  Stream<List<ReminderModel>> watchReminders() => _repo.watchReminders();

  Future<void> addReminder({
    required String invoiceId,
    required String clientId,
    required String clientName,
    required String invoiceTitle,
    required double remainingAmount,
    required ReminderType type,
    required DateTime scheduledAt,
  }) async {
    final reminder = await _repo.addReminder(
      invoiceId: invoiceId,
      clientId: clientId,
      clientName: clientName,
      invoiceTitle: invoiceTitle,
      remainingAmount: remainingAmount,
      type: type,
      scheduledAt: scheduledAt,
    );
    await NotificationService.scheduleReminder(reminder);
  }

  Future<void> deleteReminder(String reminderId) async {
    await NotificationService.cancelReminder(reminderId);
    await _repo.deleteReminder(reminderId);
  }
}
