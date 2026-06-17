import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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
        // 🔵 AppBar premium
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: Text(
            'Factures',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF00C6A2)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => context.push('/invoices/add'),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: const Color(0xFF00C6A2),
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            tabs: const [
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
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }

            final all = snapshot.data ?? [];

            return TabBarView(
              children: [
                _InvoiceList(invoices: all),

                _InvoiceList(
                  invoices: all.where((i) =>
                      i.status == InvoiceStatus.draft ||
                      i.status == InvoiceStatus.partial).toList(),
                  emptyLabel: 'Aucune facture en cours',
                ),

                _InvoiceList(
                  invoices: all.where((i) => i.status == InvoiceStatus.late).toList(),
                  emptyLabel: 'Aucune facture en retard',
                ),

                _InvoiceList(
                  invoices: all.where((i) => i.status == InvoiceStatus.paid).toList(),
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
            Icon(Icons.receipt_long_outlined,
                size: 70, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              emptyLabel,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/invoices/${invoice.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [

              // ICON
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon(invoice.status),
                  color: color,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // LEFT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      invoice.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      invoice.clientName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),

                    StatusChip(status: invoice.status),
                  ],
                ),
              ),

              // RIGHT (money focus 💰)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  Text(
                    CurrencyFormatter.format(invoice.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E88E5),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    DateFormatter.format(invoice.dueDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  if (invoice.paidAmount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reste: ${CurrencyFormatter.format(invoice.remainingAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          fontSize: 12,
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
      return Icons.timelapse;
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