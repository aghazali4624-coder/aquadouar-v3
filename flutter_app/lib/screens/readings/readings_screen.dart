// lib/screens/readings/readings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'receipt_screen.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});
  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Reading>     _readings    = [];
  bool              _loading     = true;
  String            _selectedMois = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await DbService.getReadings(mois: _selectedMois);
      setState(() { _readings = data; _loading = false; });
    } catch (e) { setState(() => _loading = false); if (mounted) showError(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relevés'),
        backgroundColor: AppColors.darkBlue,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Nouveau relevé'), Tab(text: 'Historique')],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _NewReadingTab(onSaved: _load),
        _HistoryTab(readings: _readings, loading: _loading, selectedMois: _selectedMois,
            onMoisChanged: (m) { setState(() => _selectedMois = m); _load(); }),
      ]),
    );
  }
}

// ── New Reading Tab ───────────────────────────────────────────────────────────
class _NewReadingTab extends StatefulWidget {
  final VoidCallback onSaved;
  const _NewReadingTab({required this.onSaved});
  @override
  State<_NewReadingTab> createState() => _NewReadingTabState();
}

class _NewReadingTabState extends State<_NewReadingTab> {
  final _formKey        = GlobalKey<FormState>();
  final _nouvelIndexCtrl = TextEditingController();
  List<Beneficiary> _beneficiaries = [];
  Beneficiary?      _selected;
  Reading?          _lastReading;
  Reading?          _existingThisMonth;   // monthly constraint check
  bool              _loading    = false;
  bool              _loadingBenef = true;
  File?             _photo;
  String _selectedMois = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() { super.initState(); _loadBeneficiaries(); }
  @override
  void dispose() { _nouvelIndexCtrl.dispose(); super.dispose(); }

  Future<void> _loadBeneficiaries() async {
    try {
      final data = await DbService.getBeneficiaries(actif: true);
      setState(() { _beneficiaries = data; _loadingBenef = false; });
    } catch (_) { setState(() => _loadingBenef = false); }
  }

  Future<void> _onBeneficiarySelected(Beneficiary? b) async {
    setState(() { _selected = b; _lastReading = null; _existingThisMonth = null; _nouvelIndexCtrl.clear(); _photo = null; });
    if (b == null) return;
    final results = await Future.wait([
      DbService.getLastReading(b.firestoreId),
      DbService.getReadingForMonth(b.firestoreId, _selectedMois),
    ]);
    final last     = results[0];
    final existing = results[1];
    setState(() { _lastReading = last; _existingThisMonth = existing; });
    if (existing != null) {
      _nouvelIndexCtrl.text = existing.nouvelIndex.toStringAsFixed(1);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70);
    if (file != null) setState(() => _photo = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selected == null) return;
    setState(() => _loading = true);
    final ancienIndex = _lastReading?.nouvelIndex ?? 0.0;
    final nouvelIndex = double.tryParse(_nouvelIndexCtrl.text) ?? 0;
    try {
      Reading reading;
      if (_existingThisMonth != null) {
        // MODIFY existing reading
        reading = await DbService.updateReading(
          _existingThisMonth!.firestoreId,
          nouvelIndex: nouvelIndex, photo: _photo,
        );
      } else {
        // CREATE new reading
        reading = await DbService.createReading(
          beneficiaryId: _selected!.firestoreId,
          ancienIndex: ancienIndex, nouvelIndex: nouvelIndex,
          mois: _selectedMois, photo: _photo,
        );
      }
      if (mounted) _showPostValidationPopup(reading);
      widget.onSaved();
    } catch (e) {
      if (mounted) showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPostValidationPopup(Reading reading) {
    // Find index of current beneficiary for "Next" logic
    final currentIdx = _beneficiaries.indexWhere((b) => b.firestoreId == _selected!.firestoreId);
    final hasNext = currentIdx >= 0 && currentIdx < _beneficiaries.length - 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_circle, color: AppColors.success)),
          const SizedBox(width: 12),
          const Text('Relevé enregistré', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_selected?.nomFrancais ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
          const SizedBox(height: 8),
          _InfoRow(label: 'Consommation', value: '${reading.consommation.toStringAsFixed(1)} m³'),
          _InfoRow(label: 'Montant', value: formatAmount(reading.montant)),
          _InfoRow(label: 'Mois', value: formatMonth(reading.mois)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // Générer un avis
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ReceiptScreen(reading: reading, beneficiary: _selected!)));
            },
            icon: const Icon(Icons.receipt_long_outlined, size: 16),
            label: const Text('Générer un avis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          // Fermer
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _selected = null; _lastReading = null; _existingThisMonth = null; _nouvelIndexCtrl.clear(); _photo = null; });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textGrey,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Fermer'),
          ),
          // Suivant
          if (hasNext)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                final next = _beneficiaries[currentIdx + 1];
                setState(() { _nouvelIndexCtrl.clear(); _photo = null; });
                _onBeneficiarySelected(next);
              },
              icon: const Icon(Icons.skip_next_outlined, size: 16),
              label: const Text('Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancienIndex = _lastReading?.nouvelIndex ?? 0.0;
    final isEditMode  = _existingThisMonth != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Month selector
        GestureDetector(
          onTap: _pickMonth,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.calendar_month, color: Colors.white),
              const SizedBox(width: 12),
              Text('Mois : ${formatMonth(_selectedMois)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              const Icon(Icons.edit, color: Colors.white, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // Monthly constraint banner
        if (isEditMode)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.edit_note, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Relevé existant ce mois', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning)),
                const Text('Vous modifiez le relevé existant.', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ])),
            ]),
          ),

        // Beneficiary selector
        const Text('Bénéficiaire', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Beneficiary>(
          initialValue: _selected,
          hint: Text(_loadingBenef ? 'Chargement...' : 'Choisir un bénéficiaire'),
          items: _beneficiaries.map((b) => DropdownMenuItem(
            value: b,
            child: Text('${b.numero}. ${b.nomFrancais}', style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: _onBeneficiarySelected,
          validator: (v) => v == null ? 'Requis' : null,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),

        if (_selected != null) ...[
          const SizedBox(height: 20),
          // Ancien index
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.skyBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.speed, color: AppColors.primaryBlue, size: 28),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ancien index', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                Text('${ancienIndex.toStringAsFixed(1)} m³',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
                if (_lastReading != null)
                  Text('Relevé du ${formatDate(_lastReading!.dateReleve)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Nouvel index
          TextFormField(
            controller: _nouvelIndexCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isEditMode ? 'Modifier l\'index (m³)' : 'Nouvel index (m³)',
              prefixIcon: const Icon(Icons.speed_outlined), suffixText: 'm³',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              final n = double.tryParse(v);
              if (n == null) return 'Valeur invalide';
              if (n < ancienIndex) return 'Doit être ≥ ancien index ($ancienIndex)';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),

          // Live preview
          if (_nouvelIndexCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ConsumptionPreview(ancienIndex: ancienIndex, nouvelIndexText: _nouvelIndexCtrl.text),
          ],

          const SizedBox(height: 20),

          // Photo section
          const Text('Photo du compteur (optionnel)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Prendre photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galerie'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          if (_photo != null) ...[
            const SizedBox(height: 12),
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_photo!, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(top: 8, right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _photo = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ]),
          ],
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(isEditMode ? Icons.edit_outlined : Icons.save_outlined),
            label: Text(_loading ? 'Enregistrement...' : isEditMode ? 'Modifier le relevé' : 'Enregistrer le relevé'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ])),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    showDialog(context: context, builder: (ctx) {
      final months = List.generate(6, (i) => DateFormat('yyyy-MM').format(DateTime(now.year, now.month - i)));
      return SimpleDialog(
        title: const Text('Sélectionner le mois'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: months.map((m) => SimpleDialogOption(
          onPressed: () { setState(() { _selectedMois = m; _existingThisMonth = null; }); Navigator.pop(ctx);
            if (_selected != null) _onBeneficiarySelected(_selected); },
          child: Text(formatMonth(m), style: const TextStyle(fontSize: 15)),
        )).toList(),
      );
    });
  }
}

// ── Consumption Preview ───────────────────────────────────────────────────────
class _ConsumptionPreview extends StatelessWidget {
  final double ancienIndex;
  final String nouvelIndexText;
  const _ConsumptionPreview({required this.ancienIndex, required this.nouvelIndexText});

  @override
  Widget build(BuildContext context) {
    final nouvel = double.tryParse(nouvelIndexText) ?? 0;
    final conso  = (nouvel - ancienIndex).clamp(0.0, double.infinity);
    final est    = conso <= 50 ? conso * 5.0 : (50 * 5.0) + ((conso - 50) * 7.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _Stat(label: 'Consommation', value: '${conso.toStringAsFixed(1)} m³', color: AppColors.primaryBlue),
        Container(width: 1, height: 40, color: AppColors.border),
        _Stat(label: 'Estimation', value: '~${est.toStringAsFixed(2)} DH', color: AppColors.success),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

// ── History Tab ───────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<Reading> readings;
  final bool loading;
  final String selectedMois;
  final ValueChanged<String> onMoisChanged;
  const _HistoryTab({required this.readings, required this.loading,
    required this.selectedMois, required this.onMoisChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 56,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: 6,
          itemBuilder: (ctx, i) {
            final d = DateTime(DateTime.now().year, DateTime.now().month - i);
            final m = DateFormat('yyyy-MM').format(d);
            final selected = m == selectedMois;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(formatMonth(m)),
                selected: selected,
                onSelected: (_) => onMoisChanged(m),
                selectedColor: AppColors.primaryBlue,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w600),
                checkmarkColor: Colors.white,
              ),
            );
          },
        ),
      ),
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : readings.isEmpty
            ? const EmptyState(message: 'Aucun relevé pour ce mois', icon: Icons.speed_outlined)
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: readings.length,
          itemBuilder: (ctx, i) => _ReadingTile(reading: readings[i]),
        ),
      ),
    ]);
  }
}

class _ReadingTile extends StatelessWidget {
  final Reading reading;
  const _ReadingTile({required this.reading});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.speed, color: AppColors.primaryBlue, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bén. ${reading.beneficiaryFirestoreId.substring(0, 6)}...',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text('${reading.ancienIndex.toStringAsFixed(1)} → ${reading.nouvelIndex.toStringAsFixed(1)} m³',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          Text(formatDate(reading.dateReleve), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${reading.consommation.toStringAsFixed(1)} m³',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryBlue, fontSize: 13)),
          Text(formatAmount(reading.montant),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 13)),
        ]),
        if (reading.photoUrl != null)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.photo_camera, color: AppColors.accentCyan, size: 18),
          ),
      ]),
    );
  }
}
