import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/reminder_model.dart';
import '../../providers/reminder_provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rappels'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'À venir'),
              Tab(text: 'Passés'),
            ],
          ),
        ),
        body: StreamBuilder<List<ReminderModel>>(
          stream: context.read<ReminderProvider>().watchReminders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            final all = snapshot.data ?? [];
            final now = DateTime.now();
            final upcoming = all.where((r) => r.scheduledAt.isAfter(now)).toList();
            final past = all.where((r) => !r.scheduledAt.isAfter(now)).toList();

            return TabBarView(
              children: [
                _ReminderList(
                  reminders: upcoming,
                  emptyLabel: 'Aucun rappel à venir',
                  emptyHint: 'Ouvrez une facture et appuyez sur 🔔 pour créer un rappel.',
                ),
                _ReminderList(
                  reminders: past,
                  emptyLabel: 'Aucun rappel passé',
                  emptyHint: '',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  final List<ReminderModel> reminders;
  final String emptyLabel;
  final String emptyHint;

  const _ReminderList({
    required this.reminders,
    required this.emptyLabel,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(emptyLabel, style: TextStyle(color: Colors.grey[600])),
            if (emptyHint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppSizes.fontSmall, color: Colors.grey[500]),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: reminders.length,
      itemBuilder: (_, i) => _ReminderTile(reminder: reminders[i]),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ReminderModel reminder;
  const _ReminderTile({required this.reminder});

  String _typeLabel(ReminderType type) {
    switch (type) {
      case ReminderType.beforeDue:
        return 'Avant échéance';
      case ReminderType.onDue:
        return 'Le jour J';
      case ReminderType.afterDue:
        return 'Après échéance';
      case ReminderType.custom:
        return 'Date libre';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce rappel ?'),
        content: const Text('La notification programmée sera annulée.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ReminderProvider>().deleteReminder(reminder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPast = reminder.scheduledAt.isBefore(DateTime.now());
    final color = isPast ? Colors.grey : Colors.deepPurple;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            isPast ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          reminder.clientName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.invoiceTitle,
              style: const TextStyle(fontSize: AppSizes.fontSmall),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typeLabel(reminder.type),
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.format(reminder.scheduledAt),
                  style: const TextStyle(
                    fontSize: AppSizes.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(reminder.remainingAmount),
              style: TextStyle(
                fontSize: AppSizes.fontSmall,
                color: isPast ? Colors.grey : AppColors.statusLate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _confirmDelete(context),
        ),
        onTap: () => context.push('/invoices/${reminder.invoiceId}'),
      ),
    );
  }
}
