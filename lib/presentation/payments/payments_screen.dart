import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements')),
      body: StreamBuilder<List<PaymentModel>>(
        stream: context.read<PaymentProvider>().watchAllPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final payments = snapshot.data ?? [];
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
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            itemCount: payments.length,
            itemBuilder: (context, i) => _PaymentTile(payment: payments[i]),
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
