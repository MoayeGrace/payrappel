import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/reminder_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/reminder_provider.dart';
import '../invoices/invoice_detail_screen.dart' show showAddReminderSheet;

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: Text(
            'Rappels',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF00BFA5),
            indicatorWeight: 3,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'À venir'),
              Tab(text: 'Passés'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF7C4DFF),
          foregroundColor: Colors.white,
          onPressed: () => _showInvoicePicker(context),
          tooltip: 'Nouveau rappel',
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<List<ReminderModel>>(
          stream: context.read<ReminderProvider>().watchReminders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            final all = snapshot.data ?? [];
            final now = DateTime.now();
            final upcoming =
                all.where((r) => r.scheduledAt.isAfter(now)).toList();
            final past =
                all.where((r) => !r.scheduledAt.isAfter(now)).toList();

            return TabBarView(
              children: [
                _ReminderList(
                  reminders: upcoming,
                  emptyLabel: 'Aucun rappel à venir',
                  emptyHint: 'Appuyez sur + pour programmer un rappel.',
                  isPast: false,
                ),
                _ReminderList(
                  reminders: past,
                  emptyLabel: 'Aucun rappel passé',
                  emptyHint: '',
                  isPast: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showInvoicePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: Color(0xFF7C4DFF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Choisir une facture',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Sélectionnez la facture pour créer un rappel',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<InvoiceModel>>(
                stream: sheetCtx.read<InvoiceProvider>().watchInvoices(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final unpaid = (snap.data ?? [])
                      .where((i) => !i.isFullyPaid)
                      .toList();

                  if (unpaid.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune facture en cours',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Créez d\'abord une facture depuis l\'onglet Factures.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: unpaid.length,
                    itemBuilder: (_, i) {
                      final inv = unpaid[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C4DFF)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                                Icons.receipt_long_outlined,
                                color: Color(0xFF7C4DFF),
                                size: 18),
                          ),
                          title: Text(inv.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(inv.clientName),
                          trailing: Text(
                            CurrencyFormatter.format(inv.remainingAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53935),
                              fontSize: 13,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            showAddReminderSheet(context, inv);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  final List<ReminderModel> reminders;
  final String emptyLabel;
  final String emptyHint;
  final bool isPast;

  const _ReminderList({
    required this.reminders,
    required this.emptyLabel,
    required this.emptyHint,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (emptyHint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (_, i) =>
          _ReminderTile(reminder: reminders[i], isPast: isPast),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ReminderModel reminder;
  final bool isPast;

  const _ReminderTile({required this.reminder, required this.isPast});

  String _typeLabel(ReminderType type) {
    switch (type) {
      case ReminderType.beforeDue:
        return 'Avant échéance';
      case ReminderType.onDue:
        return 'Jour J';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce rappel ?'),
        content: const Text('La notification programmée sera annulée.'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Annuler'),
          ),
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
    final color = isPast ? Colors.grey : const Color(0xFF7C4DFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/invoices/${reminder.invoiceId}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPast
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.invoiceTitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
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
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(
                          DateFormatter.format(reminder.scheduledAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(reminder.remainingAmount),
                      style: TextStyle(
                        fontSize: 13,
                        color: isPast
                            ? Colors.grey
                            : const Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
