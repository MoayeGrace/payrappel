import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository();
    final isGuest = authRepo.isAnonymous;
    final user = FirebaseAuth.instance.currentUser;

    String firstName = 'vous';
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        firstName = user.displayName!.split(' ').first;
      } else if (user.email != null && user.email!.isNotEmpty) {
        final name = user.email!.split('@').first;
        firstName = name[0].toUpperCase() + name.substring(1);
      }
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _HomeAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _WelcomeBanner(name: firstName),
                  if (isGuest) ...[
                    const SizedBox(height: 12),
                    const _GuestBanner(),
                  ],
                  const SizedBox(height: 24),
                  const _StatsSection(),
                  const SizedBox(height: 24),
                  const _MenuSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _showNewModal(context),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  static void _showNewModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Créer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _ModalTile(
              icon: Icons.people_outlined,
              label: 'Nouveau client',
              color: const Color(0xFF1A73E8),
              onTap: () {
                Navigator.pop(modalCtx);
                context.push('/clients/add');
              },
            ),
            const SizedBox(height: 4),
            _ModalTile(
              icon: Icons.receipt_long_outlined,
              label: 'Nouvelle facture',
              color: const Color(0xFF43A047),
              onTap: () {
                Navigator.pop(modalCtx);
                context.push('/invoices/add');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modal tile ─────────────────────────────────────────────────────────────────
class _ModalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModalTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ── Custom AppBar ──────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF00BFA5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Pay',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                TextSpan(
                  text: 'Rappel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF00BFA5),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF757575)),
            onPressed: () => context.push('/settings'),
            tooltip: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

// ── Welcome Banner ─────────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Icône portefeuille
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
          // Texte
          Positioned(
            left: 20,
            top: 24,
            right: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Voici la situation de votre activité aujourd'hui.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guest Banner ───────────────────────────────────────────────────────────────
class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Mode invité — créez un compte pour sauvegarder vos données.",
              style: TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/register'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Créer', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Stats Section ──────────────────────────────────────────────────────────────
class _StatsSection extends StatefulWidget {
  const _StatsSection();

  @override
  State<_StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<_StatsSection> {
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InvoiceModel>>(
      stream: context.read<InvoiceProvider>().watchInvoices(),
      builder: (context, invoiceSnap) {
        return StreamBuilder<List<PaymentModel>>(
          stream: context.read<PaymentProvider>().watchAllPayments(),
          builder: (context, paymentSnap) {
            final invoices = invoiceSnap.data ?? [];
            final payments = paymentSnap.data ?? [];
            final now = DateTime.now();

            final totalToCollect = invoices
                .where((i) => !i.isFullyPaid)
                .fold(0.0, (sum, i) => sum + i.remainingAmount);
            final lateAmount = invoices
                .where((i) => i.status == InvoiceStatus.late)
                .fold(0.0, (sum, i) => sum + i.remainingAmount);
            final monthPayments = payments
                .where((p) =>
                    p.paidAt.year == now.year &&
                    p.paidAt.month == now.month)
                .fold(0.0, (sum, p) => sum + p.amount);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Vue d'ensemble",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    _ViewToggle(
                      showChart: _showChart,
                      onToggle: (v) => setState(() => _showChart = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_showChart)
                  _PaymentsChart(payments: payments)
                else
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'À encaisser',
                          value: CurrencyFormatter.format(totalToCollect),
                          subtitle: 'Total dû par les clients',
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'En retard',
                          value: CurrencyFormatter.format(lateAmount),
                          subtitle: 'Créances échues',
                          icon: Icons.access_time_outlined,
                          color: const Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Paiements reçus',
                          value: CurrencyFormatter.format(monthPayments),
                          subtitle: 'Ce mois-ci',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF43A047),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Toggle vue ─────────────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final bool showChart;
  final ValueChanged<bool> onToggle;
  const _ViewToggle({required this.showChart, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            active: !showChart,
            onTap: () => onToggle(false),
          ),
          _ToggleBtn(
            icon: Icons.bar_chart_rounded,
            active: showChart,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 32,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF00BFA5)])
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}

// ── Graphique paiements ────────────────────────────────────────────────────────
enum _ChartPeriod { m3, m6, m12, year, custom }

extension _ChartPeriodExt on _ChartPeriod {
  String get label {
    switch (this) {
      case _ChartPeriod.m3:     return '3 M';
      case _ChartPeriod.m6:     return '6 M';
      case _ChartPeriod.m12:    return '12 M';
      case _ChartPeriod.year:   return 'Année';
      case _ChartPeriod.custom: return 'Perso.';
    }
  }
}

class _PaymentsChart extends StatefulWidget {
  final List<PaymentModel> payments;
  const _PaymentsChart({required this.payments});

  @override
  State<_PaymentsChart> createState() => _PaymentsChartState();
}

class _PaymentsChartState extends State<_PaymentsChart> {
  int? _touchedIndex;
  _ChartPeriod _period = _ChartPeriod.m6;
  DateTimeRange? _customRange;

  static const _monthLabels = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
  ];

  String _fmtShort(DateTime d) =>
      '${d.day} ${_monthLabels[d.month - 1].toLowerCase()}.';

  String _fmtY(double v) {
    if (v >= 1000000) {
      final n = v / 1000000;
      return '${n % 1 == 0 ? n.toInt() : n.toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      final n = v / 1000;
      return '${n % 1 == 0 ? n.toInt() : n.toStringAsFixed(1)}k';
    }
    return v.toInt().toString();
  }

  double _niceInterval(double maxVal) {
    if (maxVal <= 0) return 25;
    final raw = maxVal / 4;
    final mag = pow(10, (log(raw) / log(10)).floorToDouble()).toDouble();
    final norm = raw / mag;
    final factor = norm <= 1.5 ? 1.0 : norm <= 3.0 ? 2.0 : norm <= 7.0 ? 5.0 : 10.0;
    return factor * mag;
  }

  String get _chartTitle {
    final now = DateTime.now();
    switch (_period) {
      case _ChartPeriod.m3:   return '3 derniers mois';
      case _ChartPeriod.m6:   return '6 derniers mois';
      case _ChartPeriod.m12:  return '12 derniers mois';
      case _ChartPeriod.year: return 'Année ${now.year}';
      case _ChartPeriod.custom:
        if (_customRange == null) return 'Période personnalisée';
        return '${_fmtShort(_customRange!.start)} → ${_fmtShort(_customRange!.end)}';
    }
  }

  List<({String label, double amount, DateTime month})> _buildMonthData() {
    final now = DateTime.now();
    List<DateTime> months;

    switch (_period) {
      case _ChartPeriod.year:
        months = List.generate(now.month, (i) => DateTime(now.year, i + 1));
      case _ChartPeriod.custom:
        if (_customRange == null) return [];
        final start = DateTime(_customRange!.start.year, _customRange!.start.month);
        final end   = DateTime(_customRange!.end.year,   _customRange!.end.month);
        months = [];
        var cur = start;
        while (!cur.isAfter(end)) {
          months.add(cur);
          cur = DateTime(cur.year, cur.month + 1);
        }
      default:
        final count = _period == _ChartPeriod.m3 ? 3 : _period == _ChartPeriod.m12 ? 12 : 6;
        months = List.generate(count,
            (i) => DateTime(now.year, now.month - (count - 1) + i));
    }

    return months.map((m) {
      final amount = widget.payments
          .where((p) => p.paidAt.year == m.year && p.paidAt.month == m.month)
          .fold(0.0, (s, p) => s + p.amount);
      return (label: _monthLabels[m.month - 1], amount: amount, month: m);
    }).toList();
  }

  Future<void> _onPeriodTap(_ChartPeriod p) async {
    if (p == _ChartPeriod.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customRange,
        locale: const Locale('fr', 'FR'),
        helpText: 'Sélectionner une période',
        saveText: 'Valider',
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: const Color(0xFF1A73E8),
            ),
          ),
          child: child!,
        ),
      );
      if (range != null && mounted) {
        setState(() {
          _customRange = range;
          _period = _ChartPeriod.custom;
          _touchedIndex = null;
        });
      }
      return;
    }
    setState(() {
      _period = p;
      _touchedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _buildMonthData();
    final maxVal = data.isEmpty
        ? 0.0
        : data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final step = _niceInterval(maxVal < 1 ? 100 : maxVal);
    final effectiveMax = maxVal < 1
        ? 100.0
        : step * ((maxVal / step).ceil() + 1).toDouble();
    final barWidth = data.length <= 3 ? 28.0
        : data.length <= 6  ? 22.0
        : data.length <= 12 ? 14.0
        : 10.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : titre + sélecteur de période
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 16, color: Color(0xFF1A73E8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Paiements reçus — $_chartTitle',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Sélecteur période
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _ChartPeriod.values.map((p) {
                    final active = p == _period;
                    return GestureDetector(
                      onTap: () => _onPeriodTap(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF1A73E8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: p == _ChartPeriod.custom
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.date_range_outlined,
                                      size: 12,
                                      color: active
                                          ? Colors.white
                                          : Colors.grey[500]),
                                  const SizedBox(width: 3),
                                  Text(
                                    p.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : Colors.grey[500],
                                ),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          // Indicateur de plage personnalisée sélectionnée
          if (_period == _ChartPeriod.custom && _customRange != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 22),
                Icon(Icons.calendar_today_outlined,
                    size: 11, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_fmtShort(_customRange!.start)} au ${_fmtShort(_customRange!.end)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _onPeriodTap(_ChartPeriod.custom),
                  child: const Icon(Icons.edit_outlined,
                      size: 12, color: Color(0xFF1A73E8)),
                ),
              ],
            ),
          ],

          if (_period == _ChartPeriod.custom && _customRange == null) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => _onPeriodTap(_ChartPeriod.custom),
                icon: const Icon(Icons.date_range_outlined, size: 16),
                label: const Text('Choisir les dates'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1A73E8)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: effectiveMax,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      if (event.isInterestedForInteractions &&
                          response?.spot != null) {
                        setState(() => _touchedIndex =
                            response!.spot!.touchedBarGroupIndex);
                      } else {
                        setState(() => _touchedIndex = null);
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1565C0),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                        CurrencyFormatter.format(rod.toY),
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: step,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _fmtY(value),
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey[500]),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data[idx].label,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: idx == _touchedIndex
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 0.8,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (i) {
                    final isSelected = i == _touchedIndex;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].amount,
                          width: barWidth,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [
                                    const Color(0xFF00BFA5),
                                    const Color(0xFF00E5CC),
                                  ]
                                : [
                                    const Color(0xFF1A73E8),
                                    const Color(0xFF42A5F5),
                                  ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_touchedIndex != null)
              Center(
                child: Text(
                  '${data[_touchedIndex!].label} : ${CurrencyFormatter.format(data[_touchedIndex!].amount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Menu Section ───────────────────────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    final items = <_MenuEntry>[
      _MenuEntry(Icons.people_outlined, 'Clients', 'Gérer vos clients',
          const Color(0xFF1A73E8), () => context.push('/clients')),
      _MenuEntry(Icons.receipt_long_outlined, 'Factures',
          'Créer et suivre vos factures',
          const Color(0xFF43A047), () => context.push('/invoices')),
      _MenuEntry(Icons.payments_outlined, 'Paiements',
          'Historique de vos paiements',
          const Color(0xFF00ACC1), () => context.push('/payments')),
      _MenuEntry(Icons.notifications_active_outlined, 'Rappels',
          'Programmer des rappels de paiement',
          const Color(0xFF7C4DFF), () => context.push('/reminders')),
      _MenuEntry(Icons.download_outlined, 'Export',
          'Exporter en Excel ou PDF',
          const Color(0xFF00897B), () => context.push('/export')),
    ];

    return Column(
      children: [
        for (final e in items) ...[
          _MenuTile(entry: e),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuEntry(
      this.icon, this.label, this.subtitle, this.color, this.onTap);
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: entry.onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: entry.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(entry.icon, color: entry.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      entry.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: entry.color.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation ──────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Accueil',
                selected: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.people_outlined,
                label: 'Clients',
                onTap: () => context.push('/clients'),
              ),
            ),
            const Expanded(child: SizedBox()), // espace pour le FAB
            Expanded(
              child: _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Factures',
                onTap: () => context.push('/invoices'),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.bar_chart_outlined,
                label: 'Rapports',
                onTap: () => context.push('/export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF1A73E8) : Colors.grey.shade500;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected && selectedIcon != null ? selectedIcon! : icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
