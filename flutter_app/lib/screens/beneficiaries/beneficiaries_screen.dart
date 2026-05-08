// lib/screens/beneficiaries/beneficiaries_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_settings.dart';
import '../../models/models.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BeneficiariesScreen extends StatefulWidget {
  const BeneficiariesScreen({super.key});
  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  List<Beneficiary> _all = [], _filtered = [];
  bool _loading = true;
  String _search = '';
  bool _activeOnly = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await DbService.getBeneficiaries(actif: _activeOnly ? true : null);
      setState(() { _all = data; _applyFilter(); _loading = false; });
    } catch (e) { setState(() => _loading = false); if (mounted) showError(context, '$e'); }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _search.isEmpty ? _all
          : _all.where((b) =>
          b.nomFrancais.toLowerCase().contains(_search.toLowerCase()) ||
          b.nomArabe.contains(_search) ||
          b.numero.toString().contains(_search)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<AppSettings>().l10n.benfTitle),
        backgroundColor: AppColors.darkBlue,
        actions: [
          IconButton(icon: Icon(_activeOnly ? Icons.visibility : Icons.visibility_off, color: Colors.white),
              onPressed: () { setState(() => _activeOnly = !_activeOnly); _load(); }),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.darkBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            onChanged: (v) { _search = v; _applyFilter(); },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher...', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: AppColors.background,
          child: Text('${_filtered.length} bénéficiaire${_filtered.length != 1 ? 's' : ''}',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
              : _filtered.isEmpty
              ? const EmptyState(message: 'Aucun bénéficiaire trouvé', icon: Icons.people_outline)
              : ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: _filtered.length,
            itemBuilder: (ctx, i) => _BeneficiaryTile(beneficiary: _filtered[i], onRefresh: _load),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showForm(BuildContext context, Beneficiary? b) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _BeneficiaryForm(beneficiary: b, onSaved: _load));
  }
}

class _BeneficiaryTile extends StatelessWidget {
  final Beneficiary beneficiary; final VoidCallback onRefresh;
  const _BeneficiaryTile({required this.beneficiary, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      onTap: () => _showDetail(context),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('${beneficiary.numero}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(beneficiary.nomFrancais, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(beneficiary.nomArabe, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ])),
        if (!beneficiary.actif)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('Archivé', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        const Icon(Icons.chevron_right, color: AppColors.textGrey),
      ]),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _BeneficiaryDetail(beneficiary: beneficiary, onRefresh: onRefresh));
  }
}

class _BeneficiaryDetail extends StatelessWidget {
  final Beneficiary beneficiary; final VoidCallback onRefresh;
  const _BeneficiaryDetail({required this.beneficiary, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(width: 64, height: 64,
          decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(20)),
          child: Center(child: Text('${beneficiary.numero}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
        ),
        const SizedBox(height: 12),
        Text(beneficiary.nomFrancais, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        Text(beneficiary.nomArabe, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
        const SizedBox(height: 20),
        if (beneficiary.telephone != null) _InfoRow(icon: Icons.phone, label: 'Tél', value: beneficiary.telephone!),
        if (beneficiary.adresse != null) _InfoRow(icon: Icons.location_on, label: 'Adresse', value: beneficiary.adresse!),
        _InfoRow(icon: beneficiary.actif ? Icons.check_circle : Icons.cancel, label: 'Statut',
            value: beneficiary.actif ? 'Actif' : 'Archivé',
            color: beneficiary.actif ? AppColors.success : AppColors.danger),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () { Navigator.pop(context); _editBenef(context); },
            icon: const Icon(Icons.edit_outlined), label: const Text('Modifier'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
          if (beneficiary.telephone != null) ...[
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _whatsapp(context),
              icon: const Icon(Icons.message_outlined), label: const Text('WhatsApp'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ],
        ]),
        if (beneficiary.actif) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _archive(context),
            icon: const Icon(Icons.archive_outlined), label: const Text('Archiver'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }

  void _editBenef(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _BeneficiaryForm(beneficiary: beneficiary, onSaved: onRefresh));
  }

  void _whatsapp(BuildContext context) async {
    final url = Uri.parse('https://wa.me/${beneficiary.telephone!.replaceAll(RegExp(r'[^0-9]'), '')}');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    else if (context.mounted) showError(context, 'WhatsApp non disponible');
  }

  void _archive(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Archiver'),
      content: Text('Archiver ${beneficiary.nomFrancais} ?'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), child: const Text('Archiver')),
      ],
    ));
    if (confirm == true) {
      try {
        await DbService.archiveBeneficiary(beneficiary.firestoreId);
        if (context.mounted) { Navigator.pop(context); onRefresh(); showSuccess(context, 'Archivé'); }
      } catch (e) { if (context.mounted) showError(context, '$e'); }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value; final Color? color;
  const _InfoRow({required this.icon, required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primaryBlue), const SizedBox(width: 12),
      Text('$label: ', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
      Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color))),
    ]),
  );
}

class _BeneficiaryForm extends StatefulWidget {
  final Beneficiary? beneficiary; final VoidCallback onSaved;
  const _BeneficiaryForm({this.beneficiary, required this.onSaved});
  @override
  State<_BeneficiaryForm> createState() => _BeneficiaryFormState();
}

class _BeneficiaryFormState extends State<_BeneficiaryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomFr, _nomAr, _tel, _adr, _num;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.beneficiary;
    _nomFr = TextEditingController(text: b?.nomFrancais ?? '');
    _nomAr = TextEditingController(text: b?.nomArabe ?? '');
    _tel   = TextEditingController(text: b?.telephone ?? '');
    _adr   = TextEditingController(text: b?.adresse ?? '');
    _num   = TextEditingController(text: b != null ? '${b.numero}' : '');
  }

  @override
  void dispose() { _nomFr.dispose(); _nomAr.dispose(); _tel.dispose(); _adr.dispose(); _num.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'numero': int.parse(_num.text), 'nom_francais': _nomFr.text.trim(),
        'nom_arabe': _nomAr.text.trim(),
        'telephone': _tel.text.trim().isEmpty ? null : _tel.text.trim(),
        'adresse': _adr.text.trim().isEmpty ? null : _adr.text.trim(),
      };
      if (widget.beneficiary == null) await DbService.createBeneficiary(data);
      else await DbService.updateBeneficiary(widget.beneficiary!.firestoreId, data);
      if (mounted) { Navigator.pop(context); widget.onSaved(); showSuccess(context, 'Enregistré'); }
    } catch (e) { if (mounted) showError(context, '$e'); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.beneficiary != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(isEdit ? 'Modifier bénéficiaire' : 'Nouveau bénéficiaire',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextFormField(controller: _num, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'N°', prefixIcon: Icon(Icons.tag)),
              validator: (v) => v!.isEmpty ? 'Requis' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _nomFr,
              decoration: const InputDecoration(labelText: 'Nom (Français)', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'Requis' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _nomAr, textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'Requis' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _tel, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 12),
          TextFormField(controller: _adr,
              decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'Enregistrer' : 'Ajouter'),
          )),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}
