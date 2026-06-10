import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text(
          'Export Excel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bandeau info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF00BFA5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_chart_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exporter vos données',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Générez un fichier Excel à partager',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionLabel('Période'),
          _WhiteCard(
            child: Row(
              children: [
                Expanded(
                  child: _DatePick(
                    label: 'Du',
                    date: _from,
                    onPicked: (d) => setState(() => _from = d),
                    lastDate: _to,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePick(
                    label: 'Au',
                    date: _to,
                    onPicked: (d) => setState(() => _to = d),
                    firstDate: _from,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionLabel('Données à inclure'),
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
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF00BFA5)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A73E8).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(
                  _loading ? 'Génération...' : 'Générer et partager',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _loading ||
                        (!_inclInvoices &&
                            !_inclPayments &&
                            !_inclClients &&
                            !_inclStats)
                    ? null
                    : () => _generate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context) async {
    setState(() => _loading = true);
    final invoiceProvider = context.read<InvoiceProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final clientProvider = context.read<ClientProvider>();
    final messenger = ScaffoldMessenger.of(context);

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
          'payrappel_${_from.year}${_from.month.toString().padLeft(2, '0')}_${_to.year}${_to.month.toString().padLeft(2, '0')}.xlsx';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Export PayRappel');
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
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

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF1A73E8)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text(
                  DateFormatter.format(date),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
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
    const blue = Color(0xFF1A73E8);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? blue.withOpacity(0.3) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: CheckboxListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? blue.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: value ? blue : Colors.grey, size: 20),
        ),
        title:
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeColor: blue,
        onChanged: (v) => onChanged(v ?? false),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
