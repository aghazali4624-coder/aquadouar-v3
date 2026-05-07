// lib/screens/anomalies/anomalies_screen.dart
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AnomaliesScreen extends StatefulWidget {
  const AnomaliesScreen({super.key});
  @override
  State<AnomaliesScreen> createState() => _AnomaliesScreenState();
}

class _AnomaliesScreenState extends State<AnomaliesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Anomaly> _active = [], _resolved = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await DbService.getAnomaliesSplit();
      setState(() { _active = result.active; _resolved = result.resolved; _loading = false; });
    } catch (e) { setState(() => _loading = false); if (mounted) showError(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anomalies'), backgroundColor: AppColors.darkBlue,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load)],
        bottom: TabBar(controller: _tabs, indicatorColor: AppColors.danger,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: [Tab(text: 'Actives (${_active.length})'), Tab(text: 'Résolues (${_resolved.length})')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : TabBarView(controller: _tabs, children: [
        _AnomalyList(anomalies: _active, onRefresh: _load),
        _AnomalyList(anomalies: _resolved, resolved: true, onRefresh: _load),
      ]),
    );
  }
}

class _AnomalyList extends StatelessWidget {
  final List<Anomaly> anomalies; final bool resolved; final VoidCallback onRefresh;
  const _AnomalyList({required this.anomalies, this.resolved = false, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (anomalies.isEmpty) return EmptyState(
      message: resolved ? 'Aucune anomalie résolue' : 'Aucune anomalie active ✅',
      icon: Icons.warning_amber_outlined,
    );
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: anomalies.length,
      itemBuilder: (ctx, i) => _AnomalyCard(anomaly: anomalies[i], onRefresh: onRefresh),
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  final Anomaly anomaly; final VoidCallback onRefresh;
  const _AnomalyCard({required this.anomaly, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isHigh = anomaly.typeAnomalie == 'high_consumption';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: (anomaly.resolue ? AppColors.success : AppColors.danger).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (anomaly.resolue ? AppColors.success : AppColors.danger).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(anomaly.resolue ? Icons.check_circle : Icons.warning_amber_rounded,
                color: anomaly.resolue ? AppColors.success : AppColors.danger, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(anomaly.beneficiary?.nomFrancais ?? 'Bénéficiaire', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text(formatMonth(anomaly.mois), style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: (anomaly.resolue ? AppColors.success : AppColors.danger).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(anomaly.resolue ? '✓ Résolue' : isHigh ? '🔴 Élevée' : '🟠 Anormale',
                style: TextStyle(color: anomaly.resolue ? AppColors.success : AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Text(anomaly.description ?? '⚠️ Consommation anormale',
              style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${anomaly.consommation.toStringAsFixed(1)} m³ (seuil: ${anomaly.seuilDepasse.toStringAsFixed(1)} m³)',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          if (!anomaly.resolue)
            GestureDetector(
              onTap: () async {
                await DbService.resolveAnomaly(anomaly.firestoreId, true);
                onRefresh();
              },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(8)),
                child: const Text('Résoudre', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
        ]),
      ]),
    );
  }
}
