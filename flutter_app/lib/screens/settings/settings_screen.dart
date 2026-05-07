// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Tarification? _tarif;
  bool _loadingTarif = true;
  String _language = 'FR';
  String _theme    = 'Clair';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'FR';
      _theme    = prefs.getString('theme') ?? 'Clair';
    });
    try {
      final t = await DbService.getTarification();
      setState(() { _tarif = t; _loadingTarif = false; });
    } catch (_) { setState(() => _loadingTarif = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres'), backgroundColor: AppColors.darkBlue),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _SectionTitle('💰 Tarification'),
        _loadingTarif
            ? const LoadingCard()
            : _tarif == null
            ? const Text('Impossible de charger', style: TextStyle(color: AppColors.danger))
            : _TarifCard(tarif: _tarif!, onSaved: _load),

        const SizedBox(height: 20),
        _SectionTitle('⚙️ Préférences'),
        _SettingTile(icon: Icons.language, title: 'Langue',
            subtitle: _language == 'FR' ? 'Français' : 'العربية',
            onTap: () => _pickOption(context, 'Langue', ['FR', 'AR'],
                (v) async { final p = await SharedPreferences.getInstance(); await p.setString('language', v); setState(() => _language = v); })),
        _SettingTile(icon: Icons.brightness_medium_outlined, title: 'Thème',
            subtitle: _theme,
            onTap: () => _pickOption(context, 'Thème', ['Clair', 'Sombre', 'Système'],
                (v) async { final p = await SharedPreferences.getInstance(); await p.setString('theme', v); setState(() => _theme = v); })),
        _SettingTile(icon: Icons.bluetooth_outlined, title: 'Imprimante Bluetooth',
            subtitle: 'Non configurée', onTap: () => _showInfo(context, 'Imprimante Bluetooth',
                'Connectez une imprimante Bluetooth compatible pour imprimer les reçus directement depuis l\'app.')),

        const SizedBox(height: 20),
        _SectionTitle('ℹ️ À propos'),
        _InfoRow(label: 'Version', value: '3.0.0'),
        _InfoRow(label: 'Application', value: 'AquaDouar'),
        _InfoRow(label: 'Base de données', value: 'Firebase Firestore'),
        _InfoRow(label: 'Architecture', value: 'Flutter + Firebase'),
      ]),
    );
  }

  void _pickOption(BuildContext ctx, String title, List<String> options, Future<void> Function(String) onPick) {
    showDialog(context: ctx, builder: (d) => SimpleDialog(
      title: Text(title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      children: options.map((o) => SimpleDialogOption(
        onPressed: () async { await onPick(o); Navigator.pop(d); },
        child: Text(o, style: const TextStyle(fontSize: 15)),
      )).toList(),
    ));
  }

  void _showInfo(BuildContext ctx, String title, String msg) {
    showDialog(context: ctx, builder: (d) => AlertDialog(
      title: Text(title), content: Text(msg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [ElevatedButton(onPressed: () => Navigator.pop(d), child: const Text('Fermer'))],
    ));
  }
}

class _TarifCard extends StatelessWidget {
  final Tarification tarif; final VoidCallback onSaved;
  const _TarifCard({required this.tarif, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Configuration actuelle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        IconButton(onPressed: () => _edit(context), icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue)),
      ]),
      const Divider(height: 16),
      _TarifRow('Seuil', '${tarif.seuil} m³'),
      _TarifRow('Tranche 1 (≤ seuil)', '${tarif.prixTranche1} DH/m³'),
      _TarifRow('Tranche 2 (> seuil)', '${tarif.prixTranche2} DH/m³'),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.skyBlue.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
        child: Text(
          'Exemple 60 m³ → (${tarif.seuil}×${tarif.prixTranche1}) + (${60 - tarif.seuil}×${tarif.prixTranche2}) = '
          '${tarif.calculateAmount(60).toStringAsFixed(2)} DH',
          style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue),
        ),
      ),
    ]));
  }

  void _edit(BuildContext context) {
    final seuilCtrl = TextEditingController(text: '${tarif.seuil}');
    final p1Ctrl    = TextEditingController(text: '${tarif.prixTranche1}');
    final p2Ctrl    = TextEditingController(text: '${tarif.prixTranche2}');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Modifier la tarification'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: seuilCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Seuil (m³)', suffixText: 'm³')),
        const SizedBox(height: 12),
        TextField(controller: p1Ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Prix tranche 1 (≤ seuil)', suffixText: 'DH/m³')),
        const SizedBox(height: 12),
        TextField(controller: p2Ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Prix tranche 2 (> seuil)', suffixText: 'DH/m³')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            try {
              await DbService.updateTarification(
                int.parse(seuilCtrl.text),
                double.parse(p1Ctrl.text),
                double.parse(p2Ctrl.text),
              );
              if (context.mounted) { Navigator.pop(ctx); onSaved(); showSuccess(context, 'Tarification mise à jour'); }
            } catch (e) { if (context.mounted) showError(context, '$e'); }
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    ));
  }
}

class _TarifRow extends StatelessWidget {
  final String l, v;
  const _TarifRow(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
      Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String t;
  const _SectionTitle(this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
  );
}

class _SettingTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => WhiteCard(
    onTap: onTap,
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primaryBlue, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ])),
      const Icon(Icons.chevron_right, color: AppColors.textGrey),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => WhiteCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}
