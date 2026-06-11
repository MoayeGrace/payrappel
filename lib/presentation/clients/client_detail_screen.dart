import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    setState(() => _loading = true);
    final client =
        await context.read<ClientProvider>().getClient(widget.clientId);

    if (mounted) {
      setState(() {
        _client = client;
        _loading = false;
      });
    }
  }

  void _refresh() {
    setState(() => _refreshKey++);
    _loadClient();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
        ),
      );
    }

    if (_client == null) {
      return const Scaffold(
        body: Center(child: Text('Client introuvable')),
      );
    }

    final client = _client!;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),

      // 🔵 AppBar premium
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/clients/${client.id}/edit', extra: client),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _confirmDelete,
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          _ClientInfoCard(client: client),

          const SizedBox(height: 20),

          // Header section factures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Factures',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF00C6A2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton.icon(
                  onPressed: () => context.push(
                    '/invoices/add',
                    extra: {
                      'clientId': client.id,
                      'clientName': client.name
                    },
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    'Nouvelle',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _ClientInvoiceList(
            key: ValueKey(_refreshKey),
            clientId: client.id,
          ),
        ],
      ),
    );
  }
}

class _ClientInvoiceList extends StatelessWidget {
  final String clientId;
  const _ClientInvoiceList({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InvoiceModel>>(
      stream: context.read<InvoiceProvider>().watchInvoicesByClient(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.error_outline,
            text: "Erreur de chargement des factures",
            color: Colors.red,
          );
        }

        final invoices = snapshot.data ?? [];

        if (invoices.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long_outlined,
            text: "Aucune facture pour ce client",
            color: Colors.grey,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.receipt_long_outlined, color: color, size: 18),
        ),
        title: Text(
          invoice.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            StatusChip(status: invoice.status),
            const SizedBox(width: 8),
            Text(DateFormatter.format(invoice.dueDate)),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.format(invoice.totalAmount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF00C6A2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  client.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(client.phone, style: const TextStyle(color: Colors.white70)),
          if (client.email.isNotEmpty)
            Text(client.email, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}