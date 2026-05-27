import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
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
      await context.read<InvoiceProvider>().deleteInvoice(invoice.id);
      if (context.mounted) context.pop();
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
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () => context.push('/invoices/${invoice.id}/edit', extra: invoice),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Supprimer',
            onPressed: () => _confirmDelete(context),
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
