import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/client_model.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';
import '../invoices/invoices_screen.dart' show StatusChip, statusColor;

class ClientDetailScreen extends StatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  ClientModel? _client;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    final client =
        await context.read<ClientProvider>().getClient(widget.clientId);
    if (mounted) {
      setState(() {
        _client = client;
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce client ?'),
        content: const Text('Cette action est irréversible.'),
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

    if (confirmed == true && mounted) {
      await context.read<ClientProvider>().deleteClient(widget.clientId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_client == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Client introuvable')),
      );
    }

    final client = _client!;
    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () =>
                context.push('/clients/${client.id}/edit', extra: client),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Supprimer',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          _ClientInfoCard(client: client),
          const SizedBox(height: AppSizes.paddingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Factures',
                style: TextStyle(
                  fontSize: AppSizes.fontLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push(
                  '/invoices/add',
                  extra: {'clientId': client.id, 'clientName': client.name},
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvelle'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          _ClientInvoiceList(clientId: client.id),
        ],
      ),
    );
  }
}

class _ClientInvoiceList extends StatelessWidget {
  final String clientId;
  const _ClientInvoiceList({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InvoiceModel>>(
      stream:
          context.read<InvoiceProvider>().watchInvoicesByClient(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final invoices = snapshot.data ?? [];
        if (invoices.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.grey),
                SizedBox(width: AppSizes.paddingSmall),
                Text(
                  'Aucune facture pour ce client',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return Column(
          children: invoices
              .map((invoice) => _InvoiceSummaryTile(invoice: invoice))
              .toList(),
        );
      },
    );
  }
}

class _InvoiceSummaryTile extends StatelessWidget {
  final InvoiceModel invoice;
  const _InvoiceSummaryTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(invoice.status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          radius: 20,
          child: Icon(Icons.receipt_long_outlined, color: color, size: 18),
        ),
        title: Text(
          invoice.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppSizes.fontMedium),
        ),
        subtitle: Row(
          children: [
            StatusChip(status: invoice.status),
            const SizedBox(width: 8),
            Text(
              DateFormatter.format(invoice.dueDate),
              style: const TextStyle(fontSize: AppSizes.fontSmall),
            ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.format(invoice.totalAmount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontMedium,
          ),
        ),
        onTap: () => context.push('/invoices/${invoice.id}'),
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  final ClientModel client;
  const _ClientInfoCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    client.name.isNotEmpty
                        ? client.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: AppSizes.fontXL,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMedium),
                Expanded(
                  child: Text(
                    client.name,
                    style: const TextStyle(
                      fontSize: AppSizes.fontXL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _InfoRow(icon: Icons.phone, value: client.phone),
            if (client.email.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              _InfoRow(icon: Icons.email_outlined, value: client.email),
            ],
            if (client.note.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingSmall),
              _InfoRow(icon: Icons.note_outlined, value: client.note),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: AppSizes.paddingSmall),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: AppSizes.fontMedium),
          ),
        ),
      ],
    );
  }
}
