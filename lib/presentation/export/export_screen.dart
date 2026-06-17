import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/business_profile_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
import '../../services/excel_service.dart';
import '../../services/report_pdf_service.dart';

enum _ExportFormat { excel, pdf }

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
  _ExportFormat _format = _ExportFormat.excel;

  bool get _anySelected =>
      _inclInvoices || _inclPayments || _inclClients || _inclStats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          'Exporter',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
                  child: const Icon(Icons.upload_file_outlined,
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
                        'Partagez ou enregistrez en Excel ou PDF',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Choix du format
          const _SectionLabel('Format'),
          _WhiteCard(
            child: Row(
              children: [
                Expanded(
                  child: _FormatTile(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    subtitle: '.xlsx',
                    color: const Color(0xFF1E7E34),
                    selected: _format == _ExportFormat.excel,
                    onTap: () =>
                        setState(() => _format = _ExportFormat.excel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FormatTile(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    subtitle: 'Rapport PDF',
                    color: const Color(0xFFD32F2F),
                    selected: _format == _ExportFormat.pdf,
                    onTap: () => setState(() => _format = _ExportFormat.pdf),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Période
          const _SectionLabel('Période'),
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

          // Données à inclure
          const _SectionLabel('Données à inclure'),
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

          if (_loading)
            _LoadingButton(
              color: _format == _ExportFormat.pdf
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF1A73E8),
            )
          else ...[
            _GradientButton(
              label: _format == _ExportFormat.excel
                  ? 'Partager / Enregistrer (Excel)'
                  : 'Partager / Enregistrer (PDF)',
              icon: Icons.share_outlined,
              colors: _format == _ExportFormat.excel
                  ? const [Color(0xFF1E7E34), Color(0xFF00BFA5)]
                  : const [Color(0xFFD32F2F), Color(0xFFF57C00)],
              enabled: _anySelected,
              onPressed: () => _generate(context),
            ),
          ],

          const SizedBox(height: 10),
          Center(
            child: Text(
              'Le menu de partage vous permettra de choisir où enregistrer le fichier',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withOpacity(0.45),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context) async {
    setState(() => _loading = true);
    final invoiceProvider = context.read<InvoiceProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final clientProvider = context.read<ClientProvider>();
    final profile = context.read<BusinessProfileProvider>().profile;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final invoices = await invoiceProvider.watchInvoices().first;
      final payments = await paymentProvider.watchAllPayments().first;
      final clients = await clientProvider.watchClients().first;

      final dateTag =
          '${_from.year}${_from.month.toString().padLeft(2, '0')}_${_to.year}${_to.month.toString().padLeft(2, '0')}';
      final dir = await getTemporaryDirectory();

      if (_format == _ExportFormat.excel) {
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
        final file = File('${dir.path}/payrappel_$dateTag.xlsx');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Export PayRappel');
      } else {
        final bytes = await ReportPdfService.generate(
          invoices: invoices,
          payments: payments,
          clients: clients,
          profile: profile,
          from: _from,
          to: _to,
          inclInvoices: _inclInvoices,
          inclPayments: _inclPayments,
          inclStats: _inclStats,
        );
        final file =
            File('${dir.path}/payrappel_rapport_$dateTag.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Rapport PDF PayRappel',
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────
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

class _FormatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FormatTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected ? color : Colors.grey[700],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey[500])),
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
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeColor: blue,
        onChanged: (v) => onChanged(v ?? false),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool enabled;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(colors: colors)
              : const LinearGradient(
                  colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

class _LoadingButton extends StatelessWidget {
  final Color color;
  const _LoadingButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                'Génération en cours...',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
