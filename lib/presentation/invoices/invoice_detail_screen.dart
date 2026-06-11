import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/reminder_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/business_profile_provider.dart';
import '../../services/pdf_service.dart';
import 'invoices_screen.dart' show statusLabel;

// ── Point d'entrée ─────────────────────────────────────────────────────────────
class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InvoiceModel?>(
      stream: context.read<InvoiceProvider>().watchInvoice(invoiceId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8))),
          );
        }
        final invoice = snapshot.data;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Facture')),
            body: const Center(child: Text('Facture introuvable')),
          );
        }
        return _InvoiceDetailView(invoice: invoice);
      },
    );
  }
}

// ── Vue principale ─────────────────────────────────────────────────────────────
class _InvoiceDetailView extends StatefulWidget {
  final InvoiceModel invoice;
  const _InvoiceDetailView({required this.invoice});

  @override
  State<_InvoiceDetailView> createState() => _InvoiceDetailViewState();
}

class _InvoiceDetailViewState extends State<_InvoiceDetailView> {
  bool _exportingPdf = false;

  InvoiceModel get invoice => widget.invoice;

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    final messenger = ScaffoldMessenger.of(context);
    final clientProvider = context.read<ClientProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final profile = context.read<BusinessProfileProvider>().profile;
    try {
      final client = await clientProvider.getClient(invoice.clientId);
      final payments =
          await paymentProvider.watchPaymentsByInvoice(invoice.id).first;
      final bytes = await PdfService.generateInvoicePdf(
        invoice: invoice,
        payments: payments,
        profile: profile,
        clientPhone: client?.phone,
        clientEmail: client?.email,
      );
      await PdfService.sharePdf(
        bytes,
        filename: 'facture_${invoice.title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Erreur PDF : $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final client =
        await context.read<ClientProvider>().getClient(invoice.clientId);
    final phone = client?.phone ?? '';
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro de téléphone introuvable')),
        );
      }
      return;
    }
    final msg =
        'Bonjour ${invoice.clientName},\n\nVoici un rappel pour la facture "${invoice.title}".\n\nMontant restant : ${CurrencyFormatter.format(invoice.remainingAmount)}\nÉchéance : ${DateFormatter.format(invoice.dueDate)}\n\nMerci.';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer cette facture ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<InvoiceProvider>().deleteInvoice(invoice.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = invoice.totalAmount > 0
        ? (invoice.paidAmount / invoice.totalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Facture', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () =>
                context.push('/invoices/${invoice.id}/edit', extra: invoice),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      floatingActionButton: invoice.isFullyPaid
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Paiement', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => _showAddPaymentSheet(context, invoice),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Hero card ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF00BFA5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel(invoice.status),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      invoice.clientName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Échéance : ${DateFormatter.format(invoice.dueDate)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  CurrencyFormatter.format(invoice.totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Résumé financier ───────────────────────────────────────────────
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résumé financier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _FinancialRow(
                  label: 'Total facturé',
                  amount: invoice.totalAmount,
                  color: const Color(0xFF1A73E8),
                ),
                const Divider(height: 20),
                _FinancialRow(
                  label: 'Montant payé',
                  amount: invoice.paidAmount,
                  color: const Color(0xFF43A047),
                ),
                const SizedBox(height: 8),
                _FinancialRow(
                  label: 'Restant dû',
                  amount: invoice.remainingAmount,
                  color: invoice.remainingAmount > 0
                      ? const Color(0xFFF57C00)
                      : const Color(0xFF43A047),
                  bold: true,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      ratio >= 1.0
                          ? const Color(0xFF43A047)
                          : const Color(0xFF1A73E8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}% payé',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Champs personnalisés ───────────────────────────────────────────
          if (invoice.customFields.isNotEmpty) ...[
            _WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_outlined,
                          size: 16, color: Color(0xFF1E88E5)),
                      SizedBox(width: 8),
                      Text(
                        'Informations complémentaires',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...invoice.customFields.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                f['label'] ?? '',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                f['value'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Actions client ─────────────────────────────────────────────────
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Envoyer au client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: _openWhatsApp,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _exportingPdf
                          ? Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A73E8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1A73E8),
                                  ),
                                ),
                              ),
                            )
                          : _ActionButton(
                              icon: Icons.picture_as_pdf_outlined,
                              label: 'Exporter PDF',
                              color: const Color(0xFF1A73E8),
                              onTap: _exportPdf,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showAddReminderSheet(context, invoice),
                    icon: const Icon(Icons.notifications_outlined, size: 18),
                    label: const Text('Programmer un rappel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C4DFF),
                      side: const BorderSide(color: Color(0xFF7C4DFF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Liste des paiements ────────────────────────────────────────────
          _PaymentListSection(invoiceId: invoice.id),
        ],
      ),
    );
  }
}

// ── Section paiements ──────────────────────────────────────────────────────────
class _PaymentListSection extends StatelessWidget {
  final String invoiceId;
  const _PaymentListSection({required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentModel>>(
      stream: context.read<PaymentProvider>().watchPaymentsByInvoice(invoiceId),
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Paiements',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (payments.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${payments.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF43A047),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (payments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Text(
                      'Aucun paiement enregistré',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: payments
                    .map((p) => _PaymentTile(payment: p))
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF43A047), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.format(payment.paidAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (payment.note.isNotEmpty)
                  Text(
                    payment.note,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(payment.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF43A047),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets réutilisables ──────────────────────────────────────────────────────
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FinancialRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;

  const _FinancialRow({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 16 : 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet ajout paiement ───────────────────────────────────────────────────────
void _showAddPaymentSheet(BuildContext context, InvoiceModel invoice) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AddPaymentSheet(invoice: invoice),
  );
}

class _AddPaymentSheet extends StatefulWidget {
  final InvoiceModel invoice;
  const _AddPaymentSheet({required this.invoice});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<PaymentProvider>().addPayment(
            invoiceId: widget.invoice.id,
            invoiceTitle: widget.invoice.title,
            clientId: widget.invoice.clientId,
            amount: amount,
            note: _noteCtrl.text.trim(),
            paidAt: _date,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Color(0xFF00BFA5)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Enregistrer un paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Restant : ${CurrencyFormatter.format(widget.invoice.remainingAmount)}',
            style: const TextStyle(color: Color(0xFFF57C00), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Montant (FCFA)',
              prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF00BFA5)),
              filled: true,
              fillColor: const Color(0xFFF6FBFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Note (optionnel)',
              prefixIcon: const Icon(Icons.note_outlined, color: Color(0xFF00BFA5)),
              filled: true,
              fillColor: const Color(0xFFF6FBFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                locale: const Locale('fr', 'FR'),
              );
              if (picked != null) setState(() => _date = picked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FBFA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF00BFA5), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    DateFormatter.format(_date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF00BFA5)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Enregistrer',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet rappel (exportée pour reminders_screen) ──────────────────────────────
void showAddReminderSheet(BuildContext context, InvoiceModel invoice) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _AddReminderSheet(invoice: invoice),
  );
}

class _AddReminderSheet extends StatefulWidget {
  final InvoiceModel invoice;
  const _AddReminderSheet({required this.invoice});

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  ReminderType _type = ReminderType.onDue;
  DateTime? _customDate;
  bool _saving = false;

  DateTime get _scheduledAt {
    switch (_type) {
      case ReminderType.beforeDue:
        return widget.invoice.dueDate.subtract(const Duration(days: 3));
      case ReminderType.onDue:
        return widget.invoice.dueDate;
      case ReminderType.afterDue:
        return widget.invoice.dueDate.add(const Duration(days: 3));
      case ReminderType.custom:
        return _customDate ?? widget.invoice.dueDate;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ReminderProvider>().addReminder(
            invoiceId: widget.invoice.id,
            clientId: widget.invoice.clientId,
            clientName: widget.invoice.clientName,
            invoiceTitle: widget.invoice.title,
            remainingAmount: widget.invoice.remainingAmount,
            type: _type,
            scheduledAt: _scheduledAt,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rappel programmé ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF7C4DFF)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Programmer un rappel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.invoice.clientName,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          ..._ReminderOption.values.map((opt) => _ReminderOptionTile(
                option: opt,
                selected: _type == opt.type,
                onTap: () => setState(() => _type = opt.type),
                dueDate: widget.invoice.dueDate,
              )),
          if (_type == ReminderType.custom) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _customDate ?? widget.invoice.dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('fr', 'FR'),
                );
                if (picked != null) setState(() => _customDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF7C4DFF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF7C4DFF), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _customDate != null
                          ? DateFormatter.format(_customDate!)
                          : 'Choisir une date',
                      style: const TextStyle(
                          color: Color(0xFF7C4DFF),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF1A73E8)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Programmer',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ReminderOption { threeBefore, onDue, threeAfter, custom }

extension _ReminderOptionExt on _ReminderOption {
  ReminderType get type {
    switch (this) {
      case _ReminderOption.threeBefore:
        return ReminderType.beforeDue;
      case _ReminderOption.onDue:
        return ReminderType.onDue;
      case _ReminderOption.threeAfter:
        return ReminderType.afterDue;
      case _ReminderOption.custom:
        return ReminderType.custom;
    }
  }

  String label(DateTime dueDate) {
    switch (this) {
      case _ReminderOption.threeBefore:
        return '3 jours avant l\'échéance (${DateFormatter.format(dueDate.subtract(const Duration(days: 3)))})';
      case _ReminderOption.onDue:
        return 'Le jour de l\'échéance (${DateFormatter.format(dueDate)})';
      case _ReminderOption.threeAfter:
        return '3 jours après l\'échéance (${DateFormatter.format(dueDate.add(const Duration(days: 3)))})';
      case _ReminderOption.custom:
        return 'Date personnalisée';
    }
  }

  IconData get icon {
    switch (this) {
      case _ReminderOption.threeBefore:
        return Icons.schedule_outlined;
      case _ReminderOption.onDue:
        return Icons.today_outlined;
      case _ReminderOption.threeAfter:
        return Icons.event_outlined;
      case _ReminderOption.custom:
        return Icons.calendar_month_outlined;
    }
  }
}

class _ReminderOptionTile extends StatelessWidget {
  final _ReminderOption option;
  final bool selected;
  final VoidCallback onTap;
  final DateTime dueDate;

  const _ReminderOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF7C4DFF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(option.icon, color: selected ? color : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label(dueDate),
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? color : Colors.grey[700],
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
