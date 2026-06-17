import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_method_model.dart';
import '../../data/models/payment_model.dart';
import '../../providers/business_profile_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';

void _showPaymentDetail(BuildContext context, PaymentModel payment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PaymentDetailSheet(payment: payment),
  );
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          'Paiements',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Paiement',
            style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _showAddPaymentSheet(context),
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: context.read<PaymentProvider>().watchAllPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
            );
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined,
                        size: 48, color: Color(0xFF43A047)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aucun paiement enregistré',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour enregistrer\nun paiement directement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final monthTotal = payments
              .where((p) =>
                  p.paidAt.year == now.year &&
                  p.paidAt.month == now.month)
              .fold(0.0, (sum, p) => sum + p.amount);
          final allTotal =
              payments.fold(0.0, (sum, p) => sum + p.amount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Ce mois',
                        value: CurrencyFormatter.format(monthTotal),
                        icon: Icons.calendar_month_outlined,
                        colors: const [Color(0xFF00897B), Color(0xFF00BFA5)],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Total cumulé',
                        value: CurrencyFormatter.format(allTotal),
                        icon: Icons.account_balance_wallet_outlined,
                        colors: const [Color(0xFF1565C0), Color(0xFF1A73E8)],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: payments.length,
                  itemBuilder: (_, i) =>
                      _PaymentTile(payment: payments[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _showAddPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _AddPaymentSheet(),
    );
  }
}

// ── Feuille ajout paiement ─────────────────────────────────────────────────────
class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet();

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  InvoiceModel? _selectedInvoice;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _methodNameCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  PaymentMethodModel? _selectedMethod;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _refCtrl.dispose();
    _methodNameCtrl.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF43A047)),
      filled: true,
      fillColor: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : const Color(0xFFF6FBFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une facture')),
      );
      return;
    }
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<PaymentProvider>().addPayment(
            invoiceId: _selectedInvoice!.id,
            invoiceTitle: _selectedInvoice!.title,
            clientId: _selectedInvoice!.clientId,
            amount: amount,
            note: _noteCtrl.text.trim(),
            paidAt: _date,
            paymentMethodId: _selectedMethod?.id ?? '',
            paymentMethodLabel:
                _selectedMethod?.label ?? _methodNameCtrl.text.trim(),
            paymentReference: _refCtrl.text.trim(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xFFF6FBFA);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Color(0xFF43A047)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Enregistrer un paiement',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sélection facture via StreamBuilder — toutes les factures
          StreamBuilder<List<InvoiceModel>>(
            stream: context.read<InvoiceProvider>().watchInvoices(),
            builder: (context, snapshot) {
              final invoices = snapshot.data ?? [];

              if (invoices.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aucune facture trouvée.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final selectedId =
                  invoices.any((i) => i.id == _selectedInvoice?.id)
                      ? _selectedInvoice?.id
                      : null;

              return DropdownButtonFormField<String>(
                value: selectedId,
                isExpanded: true,
                decoration: _field('Facture', Icons.receipt_long_outlined),
                hint: const Text('Sélectionner une facture'),
                items: invoices.map((inv) {
                  final isPaid = inv.isFullyPaid;
                  return DropdownMenuItem<String>(
                    value: inv.id,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: inv.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isPaid ? Colors.grey[500] : null,
                            ),
                          ),
                          TextSpan(
                            text: isPaid
                                ? '  •  Soldée'
                                : '  •  ${inv.clientName}  –  ${CurrencyFormatter.format(inv.remainingAmount)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: isPaid
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null || !mounted) return;
                  final inv = invoices.firstWhere((i) => i.id == id);
                  setState(() {
                    _selectedInvoice = inv;
                    if (_amountCtrl.text.isEmpty &&
                        inv.remainingAmount > 0) {
                      _amountCtrl.text =
                          inv.remainingAmount.toStringAsFixed(0);
                    }
                  });
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Montant
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _field('Montant (FCFA)', Icons.payments_outlined),
          ),
          const SizedBox(height: 12),

          // Note
          TextField(
            controller: _noteCtrl,
            decoration: _field('Note (optionnel)', Icons.note_outlined),
          ),
          const SizedBox(height: 12),

          // Moyen de paiement
          _PaymentMethodDropdown(
            selected: _selectedMethod,
            onChanged: (m) => setState(() => _selectedMethod = m),
            fallbackNameCtrl: _methodNameCtrl,
          ),
          const SizedBox(height: 12),

          // Référence
          TextField(
            controller: _refCtrl,
            decoration: _field(
                'Référence / ID transaction (optionnel)',
                Icons.tag_outlined),
          ),
          const SizedBox(height: 12),

          // Date
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
                color: containerColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF43A047), size: 18),
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

          // Bouton enregistrer
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF00BFA5)],
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

// ── Dropdown moyen de paiement ─────────────────────────────────────────────────
class _PaymentMethodDropdown extends StatelessWidget {
  final PaymentMethodModel? selected;
  final ValueChanged<PaymentMethodModel?> onChanged;
  final TextEditingController? fallbackNameCtrl;

  const _PaymentMethodDropdown({
    required this.selected,
    required this.onChanged,
    this.fallbackNameCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final methods = context
        .watch<BusinessProfileProvider>()
        .profile
        .enabledPaymentMethods;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xFFF6FBFA);

    const decoration = InputDecoration(
      labelText: 'Moyen de paiement (optionnel)',
      prefixIcon: Icon(Icons.account_balance_wallet_outlined,
          color: Color(0xFF43A047)),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide.none,
      ),
    );

    if (methods.isEmpty) {
      return TextField(
        controller: fallbackNameCtrl,
        decoration: decoration.copyWith(
          fillColor: fillColor,
          hintText: 'Ex: Orange Money, Virement…',
        ),
      );
    }

    final selectedId =
        methods.any((m) => m.id == selected?.id) ? selected?.id : null;

    return DropdownButtonFormField<String>(
      value: selectedId,
      isExpanded: true,
      decoration: decoration.copyWith(fillColor: fillColor),
      hint: const Text('Sélectionner (optionnel)'),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('— Aucun —', style: TextStyle(color: Colors.grey)),
        ),
        ...methods.map((m) => DropdownMenuItem<String>(
              value: m.id,
              child: Text(m.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14)),
            )),
      ],
      onChanged: (id) {
        if (id == null || id.isEmpty) {
          onChanged(null);
        } else {
          onChanged(methods.firstWhere((m) => m.id == id));
        }
      },
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
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
        onTap: () => _showPaymentDetail(context, payment),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF43A047), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.invoiceTitle.isNotEmpty
                          ? payment.invoiceTitle
                          : 'Facture',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.format(payment.paidAt),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (payment.note.isNotEmpty)
                      Text(
                        payment.note,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(payment.amount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF43A047)),
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Color(0xFF43A047)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Détail d'un paiement ───────────────────────────────────────────────────────

class _PaymentDetailSheet extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentDetailSheet({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF43A047), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.format(payment.amount),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF43A047)),
                      ),
                      Text(
                        DateFormatter.format(payment.paidAt),
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            const SizedBox(height: 12),

            // Infos
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              label: 'Facture',
              value: payment.invoiceTitle.isNotEmpty
                  ? payment.invoiceTitle
                  : 'Sans titre',
            ),
            if (payment.paymentMethodLabel.isNotEmpty)
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Moyen de paiement',
                value: payment.paymentMethodLabel,
              ),
            if (payment.paymentReference.isNotEmpty)
              _InfoRow(
                icon: Icons.tag_outlined,
                label: 'Référence',
                value: payment.paymentReference,
              ),
            if (payment.note.isNotEmpty)
              _InfoRow(
                icon: Icons.note_outlined,
                label: 'Note',
                value: payment.note,
              ),

            const SizedBox(height: 20),

            // Bouton voir la facture
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/invoices/${payment.invoiceId}');
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Voir la facture complète'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A73E8),
                  side: const BorderSide(color: Color(0xFF1A73E8)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
