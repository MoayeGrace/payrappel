import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/reminder_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/business_profile_provider.dart';
import '../../services/pdf_service.dart';
import 'invoices_screen.dart' show statusColor, statusLabel;

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InvoiceModel?>(
      stream: context.read<InvoiceProvider>().watchInvoice(invoiceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final invoice = snapshot.data;
        if (invoice == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Facture introuvable')));
        }
        return _InvoiceDetailView(invoice: invoice);
      },
    );
  }
}

Future<void> _showAddPaymentSheet(BuildContext context, InvoiceModel invoice) async {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var selectedDate = DateTime.now();
  final formKey = GlobalKey<FormState>();
  bool submitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enregistrer un paiement',
                style: TextStyle(fontSize: AppSizes.fontLarge, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Restant : ${CurrencyFormatter.format(invoice.remainingAmount)}',
                style: const TextStyle(fontSize: AppSizes.fontSmall, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Montant invalide';
                  if (parsed > invoice.remainingAmount + 0.01) return 'Dépasse le montant restant';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optionnel)'),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetCtx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (picked != null) setSheetState(() => selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date du paiement',
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  child: Text(DateFormatter.format(selectedDate)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setSheetState(() => submitting = true);
                          final amount = double.parse(
                            amountCtrl.text.replaceAll(',', '.'),
                          );
                          await context.read<PaymentProvider>().addPayment(
                                invoiceId: invoice.id,
                                invoiceTitle: invoice.title,
                                clientId: invoice.clientId,
                                amount: amount,
                                note: noteCtrl.text.trim(),
                                paidAt: selectedDate,
                              );
                          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmer'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

DateTime _computeReminderDate(
  DateTime dueDate,
  ReminderType type,
  int days,
  int hour,
  int minute,
) {
  final base = switch (type) {
    ReminderType.beforeDue => dueDate.subtract(Duration(days: days)),
    ReminderType.onDue => dueDate,
    ReminderType.afterDue => dueDate.add(Duration(days: days)),
    ReminderType.custom => dueDate,
  };
  return DateTime(base.year, base.month, base.day, hour, minute);
}

Future<void> showAddReminderSheet(BuildContext context, InvoiceModel invoice) async {
  var type = ReminderType.beforeDue;
  var days = 3;
  var hour = 9;
  var minute = 0;
  DateTime? customDate;
  bool submitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) {
        DateTime? scheduledAt;
        if (type == ReminderType.custom) {
          if (customDate != null) {
            scheduledAt = DateTime(
                customDate!.year, customDate!.month, customDate!.day, hour, minute);
          }
        } else {
          scheduledAt =
              _computeReminderDate(invoice.dueDate, type, days, hour, minute);
        }
        final isPast =
            scheduledAt != null && scheduledAt.isBefore(DateTime.now());

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Créer un rappel',
                style:
                    TextStyle(fontSize: AppSizes.fontLarge, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${invoice.title} · ${CurrencyFormatter.format(invoice.remainingAmount)} restants',
                style: const TextStyle(
                    fontSize: AppSizes.fontSmall, color: AppColors.textSecondary),
              ),
              Text(
                'Échéance : ${DateFormatter.format(invoice.dueDate)}',
                style: const TextStyle(
                    fontSize: AppSizes.fontSmall, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('Quand envoyer ce rappel ?',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TypeChip(
                    label: 'Avant',
                    selected: type == ReminderType.beforeDue,
                    onTap: () => setSheetState(() => type = ReminderType.beforeDue),
                  ),
                  _TypeChip(
                    label: 'Le jour J',
                    selected: type == ReminderType.onDue,
                    onTap: () => setSheetState(() => type = ReminderType.onDue),
                  ),
                  _TypeChip(
                    label: 'Après',
                    selected: type == ReminderType.afterDue,
                    onTap: () => setSheetState(() => type = ReminderType.afterDue),
                  ),
                  _TypeChip(
                    label: 'Date libre',
                    selected: type == ReminderType.custom,
                    onTap: () =>
                        setSheetState(() => type = ReminderType.custom),
                  ),
                ],
              ),
              if (type == ReminderType.custom) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetCtx,
                      initialDate: customDate ??
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (picked != null) {
                      setSheetState(() => customDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Choisir une date',
                      suffixIcon:
                          Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(
                      customDate != null
                          ? DateFormatter.format(customDate!)
                          : 'Appuyez pour choisir…',
                      style: TextStyle(
                        color: customDate == null ? Colors.grey : null,
                      ),
                    ),
                  ),
                ),
              ] else if (type != ReminderType.onDue) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      type == ReminderType.beforeDue
                          ? 'Jours avant : '
                          : 'Jours après : ',
                      style: const TextStyle(fontSize: AppSizes.fontSmall),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: days.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true),
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setSheetState(() => days = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'Le rappel sera envoyé le ${DateFormatter.format(invoice.dueDate)}',
                  style: const TextStyle(
                      fontSize: AppSizes.fontSmall,
                      color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: sheetCtx,
                    initialTime: TimeOfDay(hour: hour, minute: minute),
                  );
                  if (picked != null) {
                    setSheetState(() {
                      hour = picked.hour;
                      minute = picked.minute;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Heure de notification',
                    suffixIcon: Icon(Icons.access_time, size: 18),
                  ),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (type == ReminderType.custom && customDate == null)
                      ? Colors.grey[100]
                      : isPast
                          ? Colors.red[50]
                          : Colors.deepPurple.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      (type == ReminderType.custom && customDate == null)
                          ? Icons.info_outline
                          : isPast
                              ? Icons.warning_amber_outlined
                              : Icons.event_outlined,
                      size: 16,
                      color: (type == ReminderType.custom && customDate == null)
                          ? Colors.grey
                          : isPast
                              ? Colors.red
                              : Colors.deepPurple,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (type == ReminderType.custom && customDate == null)
                            ? 'Choisissez une date dans le calendrier'
                            : isPast
                                ? type == ReminderType.onDue
                                    ? 'La date d\'échéance est déjà passée — utilisez "Date libre" pour choisir une autre date'
                                    : 'Cette date est déjà passée'
                                : 'Rappel prévu le ${DateFormatter.format(scheduledAt!)} à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: AppSizes.fontSmall,
                          color: (type == ReminderType.custom && customDate == null)
                              ? Colors.grey
                              : isPast
                                  ? Colors.red
                                  : Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (submitting ||
                          isPast ||
                          scheduledAt == null)
                      ? null
                      : () async {
                          setSheetState(() => submitting = true);
                          await context.read<ReminderProvider>().addReminder(
                                invoiceId: invoice.id,
                                clientId: invoice.clientId,
                                clientName: invoice.clientName,
                                invoiceTitle: invoice.title,
                                remainingAmount: invoice.remainingAmount,
                                type: type,
                                scheduledAt: scheduledAt!,
                              );
                          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Créer le rappel'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.deepPurple.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSmall,
            color: selected ? Colors.white : Colors.deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InvoiceDetailView extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceDetailView({required this.invoice});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette facture ?'),
        content: const Text('Cette action est irréversible.'),
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
      final invoiceProvider = context.read<InvoiceProvider>();
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Facture supprimée')),
      );
      await invoiceProvider.deleteInvoice(invoice.id);
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final clientProvider = context.read<ClientProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final client = await clientProvider.getClient(invoice.clientId);
    final phone = client?.phone ?? '';
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone manquant pour ce client')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final message =
        'Bonjour ${invoice.clientName}, nous vous rappelons qu\'il vous reste '
        '${CurrencyFormatter.format(invoice.remainingAmount)} FCFA à régler pour '
        '"${invoice.title}". Merci.';
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final clientProvider = context.read<ClientProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final profile = context.read<BusinessProfileProvider>().profile;
    messenger.showSnackBar(const SnackBar(content: Text('Génération du PDF…')));
    try {
      final client = await clientProvider.getClient(invoice.clientId);
      final payments = await paymentProvider.watchPaymentsByInvoice(invoice.id).first;
      final bytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        payments: payments,
        profile: profile,
        clientPhone: client?.phone,
        clientEmail: client?.email,
      );
      await PdfService.sharePdf(
          bytes, filename: 'facture_${invoice.title.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur PDF : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(invoice.status);
    final ratio = invoice.totalAmount > 0
        ? (invoice.paidAmount / invoice.totalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture'),
        actions: [
          if (!invoice.isFullyPaid)
            IconButton(
              icon: const Icon(Icons.notification_add_outlined),
              tooltip: 'Créer un rappel',
              onPressed: () => showAddReminderSheet(context, invoice),
            ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Color(0xFF25D366)),
            tooltip: 'Envoyer via WhatsApp',
            onPressed: () => _openWhatsApp(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'edit') {
                context.push('/invoices/${invoice.id}/edit', extra: invoice);
              } else if (v == 'pdf') {
                _exportPdf(context);
              } else if (v == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
              const PopupMenuItem(value: 'pdf', child: ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined),
                title: Text('Exporter en PDF'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
              const PopupMenuItem(value: 'delete', child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
            ],
          ),
        ],
      ),
      floatingActionButton: invoice.isFullyPaid
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddPaymentSheet(context, invoice),
              icon: const Icon(Icons.add),
              label: const Text('Paiement'),
            ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.title,
                          style: const TextStyle(
                            fontSize: AppSizes.fontXL,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel(invoice.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: AppSizes.fontSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  _InfoRow(icon: Icons.person_outlined, text: invoice.clientName),
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: 'Échéance : ${DateFormatter.format(invoice.dueDate)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Montants',
                    style: TextStyle(fontSize: AppSizes.fontLarge, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  _AmountRow(label: 'Total', amount: invoice.totalAmount, bold: true),
                  const Divider(height: 24),
                  _AmountRow(label: 'Payé', amount: invoice.paidAmount, color: AppColors.statusPaid),
                  const SizedBox(height: AppSizes.paddingSmall),
                  _AmountRow(
                    label: 'Restant',
                    amount: invoice.remainingAmount,
                    color: invoice.remainingAmount > 0 ? AppColors.statusLate : AppColors.statusPaid,
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)} % payé',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _SendToClientCard(invoice: invoice, onExportPdf: () => _exportPdf(context)),
          const SizedBox(height: AppSizes.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paiements',
                style: TextStyle(fontSize: AppSizes.fontLarge, fontWeight: FontWeight.bold),
              ),
              if (!invoice.isFullyPaid)
                TextButton.icon(
                  onPressed: () => _showAddPaymentSheet(context, invoice),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          _PaymentList(invoiceId: invoice.id),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SendToClientCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onExportPdf;

  const _SendToClientCard({required this.invoice, required this.onExportPdf});

  Future<void> _whatsApp(BuildContext context) async {
    final clientProvider = context.read<ClientProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final client = await clientProvider.getClient(invoice.clientId);
    final phone = client?.phone ?? '';
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone manquant pour ce client')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final message =
        'Bonjour ${invoice.clientName}, nous vous rappelons qu\'il vous reste '
        '${CurrencyFormatter.format(invoice.remainingAmount)} FCFA à régler pour '
        '"${invoice.title}". Merci.';
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envoyer au client',
              style: TextStyle(fontSize: AppSizes.fontMedium, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _whatsApp(context),
                    icon: const Icon(Icons.send_outlined, size: 18, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportPdf,
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  final String invoiceId;
  const _PaymentList({required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentModel>>(
      stream: context.read<PaymentProvider>().watchPaymentsByInvoice(invoiceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: const Row(
              children: [
                Icon(Icons.payments_outlined, color: Colors.grey),
                SizedBox(width: AppSizes.paddingSmall),
                Text('Aucun paiement enregistré', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return Column(
          children: payments.map((p) => _PaymentTile(payment: p)).toList(),
        );
      },
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce paiement ?'),
        content: const Text('Le montant payé sera recalculé automatiquement.'),
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
      await context.read<PaymentProvider>().deletePayment(payment.id, payment.invoiceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.statusPaid.withOpacity(0.12),
          child: const Icon(Icons.check, color: AppColors.statusPaid, size: 18),
        ),
        title: Text(
          CurrencyFormatter.format(payment.amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.fontMedium),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormatter.format(payment.paidAt),
              style: const TextStyle(fontSize: AppSizes.fontSmall),
            ),
            if (payment.note.isNotEmpty)
              Text(
                payment.note,
                style: const TextStyle(
                  fontSize: AppSizes.fontSmall,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary))),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  final bool bold;

  const _AmountRow({required this.label, required this.amount, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontMedium,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: bold ? AppSizes.fontLarge : AppSizes.fontMedium,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
