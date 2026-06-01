import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/excel_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month - 2, 1);
  DateTime _to = DateTime.now();

  bool _inclInvoices = true;
  bool _inclPayments = true;
  bool _inclClients = false;
  bool _inclStats = true;

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Excel'),
        actions: [
          if (isPro)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusPaid.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pro',
                style: TextStyle(
                  color: AppColors.statusPaid,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Période'),
          _DateRangeSelector(
            from: _from,
            to: _to,
            onFromChanged: (d) => setState(() => _from = d),
            onToChanged: (d) => setState(() => _to = d),
          ),
          const SizedBox(height: 20),
          const _SectionHeader('Données à inclure'),
          _CheckOption(
            label: 'Factures',
            subtitle: 'Titre, client, montants, statut, date',
            icon: Icons.receipt_long_outlined,
            value: _inclInvoices,
            onChanged: (v) => setState(() => _inclInvoices = v),
          ),
          _CheckOption(
            label: 'Paiements',
            subtitle: 'Date, client, montant, note',
            icon: Icons.payments_outlined,
            value: _inclPayments,
            onChanged: (v) => setState(() => _inclPayments = v),
          ),
          _CheckOption(
            label: 'Clients',
            subtitle: 'Coordonnées et résumé par client',
            icon: Icons.people_outlined,
            value: _inclClients,
            onChanged: (v) => setState(() => _inclClients = v),
          ),
          _CheckOption(
            label: 'Statistiques',
            subtitle: 'Taux de recouvrement, totaux, retards',
            icon: Icons.bar_chart_outlined,
            value: _inclStats,
            onChanged: (v) => setState(() => _inclStats = v),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              icon: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_outlined),
              label: Text(
                _loading ? 'Génération...' : 'Générer et partager',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _loading || (!_inclInvoices && !_inclPayments && !_inclClients && !_inclStats)
                  ? null
                  : () => _generate(context, isPro),
            ),
          ),
          const SizedBox(height: 12),
          if (!isPro)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Passez au Pro pour exporter vos données.',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/upgrade'),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context, bool isPro) async {
    if (!isPro) {
      context.push('/upgrade', extra: 'excel');
      return;
    }

    setState(() => _loading = true);

    // Capturer les providers avant les await
    final invoiceProvider = context.read<InvoiceProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final clientProvider = context.read<ClientProvider>();

    try {
      final invoices = await invoiceProvider.watchInvoices().first;
      final payments = await paymentProvider.watchAllPayments().first;
      final clients = await clientProvider.watchClients().first;

      final options = ExcelExportOptions(
        from: _from,
        to: _to,
        includeInvoices: _inclInvoices,
        includePayments: _inclPayments,
        includeClients: _inclClients,
        includeStats: _inclStats,
      );

      final bytes = ExcelService.generate(
        invoices: invoices,
        payments: payments,
        clients: clients,
        options: options,
      );

      if (bytes == null || !mounted) return;

      final dir = await getTemporaryDirectory();
      final filename =
          'payrappel_export_${_from.year}${_from.month.toString().padLeft(2, '0')}_${_to.year}${_to.month.toString().padLeft(2, '0')}.xlsx';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      // share_plus v10: API Share.shareXFiles
      await Share.shareXFiles([XFile(file.path)], text: 'Export PayRappel');
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final ValueChanged<DateTime> onFromChanged;
  final ValueChanged<DateTime> onToChanged;

  const _DateRangeSelector({
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DatePick(
            label: 'Du',
            date: from,
            onPicked: onFromChanged,
            lastDate: to,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DatePick(
            label: 'Au',
            date: to,
            onPicked: onToChanged,
            firstDate: from,
          ),
        ),
      ],
    );
  }
}

class _DatePick extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const _DatePick({
    required this.label,
    required this.date,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime(2030),
          locale: const Locale('fr', 'FR'),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
        ),
        child: Text(
          DateFormatter.format(date),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}

class _CheckOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        secondary: Icon(icon, color: value ? AppColors.primary : Colors.grey),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeColor: AppColors.primary,
        onChanged: (v) => onChanged(v ?? false),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
