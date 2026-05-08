// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../app_settings.dart';
import '../../models/models.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await DbService.getDashboard();
      setState(() { _stats = s; _loading = false; });
    } catch (e) { setState(() => _loading = false); if (mounted) showError(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.watch<AppSettings>().l10n.dashboardTitle), backgroundColor: AppColors.darkBlue,
          actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _stats == null ? EmptyState(message: context.read<AppSettings>().l10n.aucuneDonnee, icon: Icons.bar_chart)
          : _Body(stats: _stats!),
    );
  }
}

class _Body extends StatelessWidget {
  final DashboardStats stats;
  const _Body({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<AppSettings>().l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
          children: [
            GradientCard(title: l10n.consommationTotale, value: '${stats.totalConsommation.toStringAsFixed(0)} m³',
                subtitle: l10n.toutesPeriodes, icon: Icons.water_drop_outlined, gradient: AppColors.blueGradient),
            GradientCard(title: l10n.revenusEncaisses, value: formatAmount(stats.totalRevenus),
                subtitle: l10n.paiementsRecus, icon: Icons.payments_outlined, gradient: AppColors.greenGradient),
            GradientCard(title: l10n.montantImpaye, value: formatAmount(stats.montantImpaye),
                subtitle: l10n.enAttente, icon: Icons.pending_outlined, gradient: AppColors.orangeGradient),
            GradientCard(title: l10n.anomaliesActives, value: '${stats.nbAnomalies}',
                subtitle: l10n.nonResolues, icon: Icons.warning_amber_outlined, gradient: AppColors.redGradient),
          ],
        ),
        const SizedBox(height: 16),
        WhiteCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: l10n.tauxRecouvrement),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.tauxRecouvrement / 100,
                backgroundColor: AppColors.border,
                color: stats.tauxRecouvrement > 70 ? AppColors.success : stats.tauxRecouvrement > 40 ? AppColors.warning : AppColors.danger,
                minHeight: 12,
              ),
            )),
            const SizedBox(width: 12),
            Text('${stats.tauxRecouvrement.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l10n.benefActifs(stats.nbBeneficiaires), style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            Text(l10n.relevesCount(stats.nbReleves), style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ]),
        ])),
        const SizedBox(height: 16),
        if (stats.monthlyConsumption.isNotEmpty) _BarChartCard(
          title: l10n.consommationMens, data: stats.monthlyConsumption,
          color: AppColors.primaryBlue, dataKey: 'total', monthNames: l10n.monthNames,
        ),
        const SizedBox(height: 16),
        if (stats.monthlyRevenue.isNotEmpty) _BarChartCard(
          title: l10n.revenusMensuels, data: stats.monthlyRevenue,
          color: AppColors.success, dataKey: 'total', monthNames: l10n.monthNames,
        ),
        const SizedBox(height: 16),
        WhiteCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: l10n.repartitionPaiements),
          const SizedBox(height: 16),
          Row(children: [
            SizedBox(width: 140, height: 140,
              child: PieChart(PieChartData(
                sections: [
                  PieChartSectionData(value: (stats.paymentDistribution['paid'] as num).toDouble(),
                      color: AppColors.success, title: '${stats.paymentDistribution['paid']}', radius: 55,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  PieChartSectionData(value: (stats.paymentDistribution['unpaid'] as num).toDouble(),
                      color: AppColors.warning, title: '${stats.paymentDistribution['unpaid']}', radius: 55,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
                sectionsSpace: 3,
              )),
            ),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Legend(color: AppColors.success, label: l10n.payes, value: stats.paymentDistribution['paid']),
              const SizedBox(height: 12),
              _Legend(color: AppColors.warning, label: l10n.impayes, value: stats.paymentDistribution['unpaid']),
            ]),
          ]),
        ])),
      ]),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title; final List<Map<String, dynamic>> data; final Color color; final String dataKey;
  final List<String> monthNames;
  const _BarChartCard({required this.title, required this.data, required this.color, required this.dataKey, required this.monthNames});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (m, d) => (d[dataKey] as num).toDouble() > m ? (d[dataKey] as num).toDouble() : m);
    return WhiteCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: title), const SizedBox(height: 16),
      SizedBox(height: 160, child: BarChart(BarChartData(
        maxY: maxVal * 1.2,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withValues(alpha: 0.5), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox();
              final parts = (data[idx]['mois'] as String).split('-');
              final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
              return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(m > 0 && m < 13 ? monthNames[m] : '', style: const TextStyle(fontSize: 10, color: AppColors.textGrey)));
            },
          )),
        ),
        barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(toY: (e.value[dataKey] as num).toDouble(), color: color, width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
        ])).toList(),
        barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.darkBlue,
          getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
              rod.toY.toStringAsFixed(1), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        )),
      ))),
    ]));
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label; final dynamic value;
  const _Legend({required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
    const SizedBox(width: 6),
    Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
  ]);
}
