import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/subscription_provider.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final cutoff = sub.freeHistoryCutoff;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      body: StreamBuilder<List<PaymentModel>>(
        stream: context.read<PaymentProvider>().watchAllPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var payments = snapshot.data ?? [];

          // Limite gratuite : historique 3 mois
          if (cutoff != null) {
            payments = payments.where((p) => p.paidAt.isAfter(cutoff)).toList();
          }

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun paiement enregistré',
                    style: TextStyle(color: Colors.grey, fontSize: AppSizes.fontLarge),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enregistrez des paiements depuis une facture.',
                    style: TextStyle(color: Colors.grey, fontSize: AppSizes.fontSmall),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              if (cutoff != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_outlined, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Historique limité à 3 mois (offre gratuite)',
                          style: TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/upgrade', extra: 'history'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Pro', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  itemCount: payments.length,
                  itemBuilder: (context, i) => _PaymentTile(payment: payments[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

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
          payment.invoiceTitle.isNotEmpty ? payment.invoiceTitle : 'Facture',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppSizes.fontMedium),
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
                style: const TextStyle(fontSize: AppSizes.fontSmall, color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.format(payment.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontMedium,
            color: AppColors.statusPaid,
          ),
        ),
        onTap: () => context.push('/invoices/${payment.invoiceId}'),
      ),
    );
  }
}
