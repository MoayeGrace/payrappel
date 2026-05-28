import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/invoice_provider.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Factures'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nouvelle facture',
              onPressed: () => context.push('/invoices/add'),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Toutes'),
              Tab(text: 'En cours'),
              Tab(text: 'En retard'),
              Tab(text: 'Payées'),
            ],
          ),
        ),
        body: StreamBuilder<List<InvoiceModel>>(
          stream: context.read<InvoiceProvider>().watchInvoices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            final all = snapshot.data ?? [];
            return TabBarView(
              children: [
                _InvoiceList(invoices: all),
                _InvoiceList(
                  invoices: all
                      .where((i) =>
                          i.status == InvoiceStatus.draft ||
                          i.status == InvoiceStatus.partial)
                      .toList(),
                  emptyLabel: 'Aucune facture en cours',
                ),
                _InvoiceList(
                  invoices: all
                      .where((i) => i.status == InvoiceStatus.late)
                      .toList(),
                  emptyLabel: 'Aucune facture en retard',
                ),
                _InvoiceList(
                  invoices: all
                      .where((i) => i.status == InvoiceStatus.paid)
                      .toList(),
                  emptyLabel: 'Aucune facture payée',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<InvoiceModel> invoices;
  final String emptyLabel;

  const _InvoiceList({
    required this.invoices,
    this.emptyLabel = 'Aucune facture pour l\'instant',
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(emptyLabel, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: invoices.length,
      itemBuilder: (_, i) => _InvoiceTile(invoice: invoices[i]),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(invoice.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.push('/invoices/${invoice.id}'),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ICON
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                statusIcon(invoice.status),
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // LEFT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // TITLE
                  Text(
                    invoice.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontMedium,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // CLIENT
                  Text(
                    invoice.clientName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // STATUS
                  StatusChip(status: invoice.status),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // RIGHT CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                // PRICE
                Text(
                  CurrencyFormatter.format(invoice.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppSizes.fontMedium,
                  ),
                ),

                const SizedBox(height: 4),

                // DATE
                Text(
                  'Délais : ${DateFormatter.format(invoice.dueDate)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontSmall,
                    color: AppColors.textSecondary,
                  ),
                ),

                if (invoice.paidAmount > 0) ...[
                  const SizedBox(height: 6),

                  Text(
                    'Reste : ${CurrencyFormatter.format(invoice.remainingAmount)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final InvoiceStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          fontSize: AppSizes.fontSmall,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color statusColor(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.paid:
      return AppColors.statusPaid;
    case InvoiceStatus.partial:
      return AppColors.statusPartial;
    case InvoiceStatus.late:
      return AppColors.statusLate;
    case InvoiceStatus.draft:
      return AppColors.statusDraft;
  }
}

IconData statusIcon(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.paid:
      return Icons.check_circle_outline;
    case InvoiceStatus.partial:
      return Icons.pending_outlined;
    case InvoiceStatus.late:
      return Icons.warning_amber_outlined;
    case InvoiceStatus.draft:
      return Icons.receipt_long_outlined;
  }
}

String statusLabel(InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.paid:
      return 'Payée';
    case InvoiceStatus.partial:
      return 'Partielle';
    case InvoiceStatus.late:
      return 'En retard';
    case InvoiceStatus.draft:
      return 'En cours';
  }
}
