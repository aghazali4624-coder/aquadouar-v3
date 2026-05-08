// lib/services/db_service.dart
// Sorting is done in Dart to avoid composite index requirements.
// Deploy firestore.indexes.json and restore orderBy+limit for better perf once indexes are built.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class DbService {
  static final _db      = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String currentMois() => DateFormat('yyyy-MM').format(DateTime.now());

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }

  // In-memory cache: one collection read serves all enrichment calls for 5 minutes.
  static Map<String, Beneficiary>? _benefCache;
  static DateTime? _benefCacheTime;

  static Future<Map<String, Beneficiary>> _getBeneficiaryMap() async {
    final now = DateTime.now();
    if (_benefCache != null &&
        _benefCacheTime != null &&
        now.difference(_benefCacheTime!) < const Duration(minutes: 5)) {
      return _benefCache!;
    }
    final snap = await _db.collection('beneficiaires').limit(500).get();
    _benefCache = { for (final d in snap.docs) d.id: Beneficiary.fromFirestore(d.data(), d.id) };
    _benefCacheTime = now;
    return _benefCache!;
  }

  static void _invalidateBenefCache() { _benefCache = null; }

  // ── Tarification ──────────────────────────────────────────────────────────

  static Future<Tarification> getTarification() async {
    final doc = await _db.collection('config').doc('tarification').get();
    if (!doc.exists) {
      await _db.collection('config').doc('tarification').set({
        'seuil': 50, 'prix_tranche1': 5.0, 'prix_tranche2': 7.0,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return Tarification(seuil: 50, prixTranche1: 5.0, prixTranche2: 7.0, updatedAt: DateTime.now());
    }
    return Tarification.fromFirestore(doc.data()!);
  }

  static Future<void> updateTarification(int seuil, double p1, double p2) async {
    await _db.collection('config').doc('tarification').set({
      'seuil': seuil, 'prix_tranche1': p1, 'prix_tranche2': p2,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Anomaly detection (local logic) ───────────────────────────────────────

  static Map<String, dynamic>? detectAnomaly(double consumption, double avg) {
    if (consumption > 100) {
      return {
        'type_anomalie': 'high_consumption', 'seuil_depasse': 100.0,
        'description': 'Consommation élevée (${consumption.toStringAsFixed(1)} m³) – Possible fuite d\'eau',
      };
    }
    if (avg > 0 && consumption > 2 * avg) {
      return {
        'type_anomalie': 'double_average',
        'seuil_depasse': double.parse((2 * avg).toStringAsFixed(2)),
        'description': 'Consommation anormale (${consumption.toStringAsFixed(1)} m³) – Plus du double de la moyenne (${avg.toStringAsFixed(1)} m³)',
      };
    }
    return null;
  }

  // ── Beneficiaries ─────────────────────────────────────────────────────────

  static Future<List<Beneficiary>> getBeneficiaries({String? search, bool? actif}) async {
    Query<Map<String, dynamic>> q = _db.collection('beneficiaires');
    if (actif != null) q = q.where('actif', isEqualTo: actif);
    final snap = await q.limit(500).get();
    List<Beneficiary> list = snap.docs.map((d) => Beneficiary.fromFirestore(d.data(), d.id)).toList();
    list.sort((a, b) => a.numero.compareTo(b.numero));
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      list = list.where((b) =>
          b.nomFrancais.toLowerCase().contains(s) ||
          b.nomArabe.contains(s) ||
          b.numero.toString().contains(s)).toList();
    }
    return list;
  }

  static Future<Beneficiary> createBeneficiary(Map<String, dynamic> data) async {
    final ref = _db.collection('beneficiaires').doc();
    final payload = {...data, 'id': ref.id, 'actif': true, 'created_at': FieldValue.serverTimestamp()};
    await ref.set(payload);
    _invalidateBenefCache();
    final doc = await ref.get();
    return Beneficiary.fromFirestore(doc.data()!, doc.id);
  }

  static Future<Beneficiary> updateBeneficiary(String id, Map<String, dynamic> data) async {
    await _db.collection('beneficiaires').doc(id).update(data);
    _invalidateBenefCache();
    final doc = await _db.collection('beneficiaires').doc(id).get();
    return Beneficiary.fromFirestore(doc.data()!, doc.id);
  }

  static Future<void> archiveBeneficiary(String id) async {
    await _db.collection('beneficiaires').doc(id).update({'actif': false});
    _invalidateBenefCache();
  }

  // ── Readings ──────────────────────────────────────────────────────────────

  // Requires composite index: beneficiary_id ASC, mois ASC
  static Future<Reading?> getReadingForMonth(String beneficiaryId, String mois) async {
    final snap = await _db.collection('releves')
        .where('beneficiary_id', isEqualTo: beneficiaryId)
        .where('mois', isEqualTo: mois)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Reading.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
  }

  static Future<Reading?> getLastReading(String beneficiaryId) async {
    final snap = await _db.collection('releves')
        .where('beneficiary_id', isEqualTo: beneficiaryId)
        .get();
    if (snap.docs.isEmpty) return null;
    final sorted = snap.docs.toList()
      ..sort((a, b) {
        final da = _toDate(a.data()['date_releve']);
        final db2 = _toDate(b.data()['date_releve']);
        if (da == null) return 1;
        if (db2 == null) return -1;
        return db2.compareTo(da);
      });
    return Reading.fromFirestore(sorted.first.data(), sorted.first.id);
  }

  static Future<double> getAverageConsumption(String beneficiaryId) async {
    final snap = await _db.collection('releves')
        .where('beneficiary_id', isEqualTo: beneficiaryId)
        .get();
    if (snap.docs.isEmpty) return 0;
    final sorted = snap.docs.toList()
      ..sort((a, b) {
        final da = _toDate(a.data()['date_releve']);
        final db2 = _toDate(b.data()['date_releve']);
        if (da == null) return 1;
        if (db2 == null) return -1;
        return db2.compareTo(da);
      });
    final recent = sorted.take(3).toList();
    final vals = recent.map((d) => (d.data()['consommation'] as num).toDouble()).toList();
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  static Future<List<Reading>> getReadings({String? mois, String? beneficiaryId}) async {
    Query<Map<String, dynamic>> q = _db.collection('releves');
    if (mois != null) q = q.where('mois', isEqualTo: mois);
    if (beneficiaryId != null) q = q.where('beneficiary_id', isEqualTo: beneficiaryId);
    final snap = await q.limit(200).get();
    final list = snap.docs.map((d) => Reading.fromFirestore(d.data(), d.id)).toList();
    list.sort((a, b) => b.dateReleve.compareTo(a.dateReleve));
    return list;
  }

  static Future<String?> uploadMeterPhoto(File photo, String readingId) async {
    try {
      final ref = _storage.ref('meter_photos/$readingId.jpg');
      await ref.putFile(photo);
      return await ref.getDownloadURL();
    } catch (_) { return null; }
  }

  static Future<Reading> createReading({
    required String beneficiaryId,
    required double ancienIndex,
    required double nouvelIndex,
    required String mois,
    File? photo,
    String? localId,
  }) async {
    if (nouvelIndex < ancienIndex) {
      throw Exception('Le nouvel index ne peut pas être inférieur à l\'ancien index');
    }

    final existing = await getReadingForMonth(beneficiaryId, mois);
    if (existing != null) {
      throw Exception('Un relevé existe déjà pour ce bénéficiaire ce mois ($mois). Utilisez "Modifier".');
    }

    final config = await getTarification();
    final consommation = double.parse((nouvelIndex - ancienIndex).toStringAsFixed(2));
    final montant = config.calculateAmount(consommation);
    final avg = await getAverageConsumption(beneficiaryId);
    final anomalyData = detectAnomaly(consommation, avg);
    final now = DateTime.now();
    final uid = localId ?? const Uuid().v4();

    final releveRef = _db.collection('releves').doc();
    String? photoUrl;
    if (photo != null) photoUrl = await uploadMeterPhoto(photo, releveRef.id);

    final releveData = {
      'id': releveRef.id, 'beneficiary_id': beneficiaryId,
      'ancien_index': ancienIndex, 'nouvel_index': nouvelIndex,
      'consommation': consommation, 'montant': montant,
      'date_releve': Timestamp.fromDate(now), 'mois': mois,
      'local_id': uid, 'synced': true,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
    await releveRef.set(releveData);

    if (anomalyData != null) {
      final anomRef = _db.collection('anomalies').doc();
      await anomRef.set({
        'id': anomRef.id, 'beneficiary_id': beneficiaryId,
        'reading_id': releveRef.id, 'consommation': consommation,
        'mois': mois, 'resolue': false,
        'date_detection': Timestamp.fromDate(now), ...anomalyData,
      });
    }

    final payRef = _db.collection('paiements').doc();
    await payRef.set({
      'id': payRef.id, 'beneficiary_id': beneficiaryId,
      'reading_id': releveRef.id, 'montant': montant,
      'statut': 'unpaid', 'mois': mois, 'date_paiement': null,
      'date_echeance': Timestamp.fromDate(now.add(const Duration(days: 30))),
    });

    return Reading.fromFirestore(releveData, releveRef.id);
  }

  static Future<Reading> updateReading(String readingId, {
    required double nouvelIndex,
    File? photo,
  }) async {
    final doc = await _db.collection('releves').doc(readingId).get();
    if (!doc.exists) throw Exception('Relevé introuvable');
    final data = doc.data()!;
    final ancienIndex = (data['ancien_index'] as num).toDouble();

    if (nouvelIndex < ancienIndex) {
      throw Exception('Le nouvel index ne peut pas être inférieur à l\'ancien index');
    }

    final config = await getTarification();
    final consommation = double.parse((nouvelIndex - ancienIndex).toStringAsFixed(2));
    final montant = config.calculateAmount(consommation);

    final updates = <String, dynamic>{
      'nouvel_index': nouvelIndex, 'consommation': consommation, 'montant': montant,
    };

    if (photo != null) {
      final photoUrl = await uploadMeterPhoto(photo, readingId);
      if (photoUrl != null) updates['photo_url'] = photoUrl;
    }

    await _db.collection('releves').doc(readingId).update(updates);

    final paySnap = await _db.collection('paiements')
        .where('reading_id', isEqualTo: readingId).limit(1).get();
    if (paySnap.docs.isNotEmpty) {
      await paySnap.docs.first.reference.update({'montant': montant});
    }

    final updated = await _db.collection('releves').doc(readingId).get();
    return Reading.fromFirestore(updated.data()!, updated.id);
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  static Future<List<Payment>> getPayments({String? statut, String? mois}) async {
    final snap = await _db.collection('paiements')
        .orderBy('date_echeance', descending: true)
        .limit(500).get();

    List<Payment> result = snap.docs.map((d) => Payment.fromFirestore(d.data(), d.id)).toList();
    if (mois != null) result = result.where((p) => p.mois == mois).toList();

    // Fire-and-forget: batch overdue status writes don't block the UI — in-memory isLate is already correct
    final now = DateTime.now();
    final batch = _db.batch();
    bool hasBatch = false;
    for (final p in result) {
      if (p.statut == 'unpaid' && p.dateEcheance != null && p.dateEcheance!.isBefore(now)) {
        batch.update(_db.collection('paiements').doc(p.firestoreId), {'statut': 'late'});
        hasBatch = true;
      }
    }
    if (hasBatch) batch.commit(); // intentionally not awaited

    if (statut != null) {
      result = result.where((p) {
        if (statut == 'late') return p.isLate || p.statut == 'late';
        return p.statut == statut;
      }).toList();
    }

    // Single collection read (cached) replaces N individual doc fetches
    final benefMap = await _getBeneficiaryMap();
    for (final p in result) {
      p.beneficiary = benefMap[p.beneficiaryFirestoreId];
    }

    return result;
  }

  static Future<void> markAsPaid(String firestoreId) async {
    await _db.collection('paiements').doc(firestoreId).update({
      'statut': 'paid',
      'date_paiement': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<Map<String, dynamic>> getPaymentStats({String? mois}) async {
    Query q = _db.collection('paiements');
    if (mois != null) q = q.where('mois', isEqualTo: mois);
    final snap = await q.get();
    double totalPaid = 0, totalUnpaid = 0;
    int nbPaid = 0, nbUnpaid = 0, nbLate = 0;
    final now = DateTime.now();
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final amt = (d['montant'] as num).toDouble();
      final statut = d['statut'] as String? ?? 'unpaid';
      final echeance = _toDate(d['date_echeance']);
      if (statut == 'paid') { totalPaid += amt; nbPaid++; }
      else if (statut == 'late' || (statut == 'unpaid' && echeance != null && echeance.isBefore(now))) {
        nbLate++;
      } else { totalUnpaid += amt; nbUnpaid++; }
    }
    return {
      'total_paid': double.parse(totalPaid.toStringAsFixed(2)),
      'total_unpaid': double.parse(totalUnpaid.toStringAsFixed(2)),
      'nb_paid': nbPaid, 'nb_unpaid': nbUnpaid, 'nb_late': nbLate,
    };
  }

  // ── Anomalies ─────────────────────────────────────────────────────────────

  // One query for both tabs — splits active/resolved in Dart, uses cached beneficiaries.
  static Future<({List<Anomaly> active, List<Anomaly> resolved})> getAnomaliesSplit({String? mois}) async {
    final snap = await _db.collection('anomalies')
        .orderBy('date_detection', descending: true)
        .limit(400).get();
    List<Anomaly> all = snap.docs.map((d) => Anomaly.fromFirestore(d.data(), d.id)).toList();
    if (mois != null) all = all.where((a) => a.mois == mois).toList();

    final benefMap = await _getBeneficiaryMap();
    for (final a in all) {
      a.beneficiary = benefMap[a.beneficiaryFirestoreId];
    }
    return (
      active:   all.where((a) => !a.resolue).toList(),
      resolved: all.where((a) => a.resolue).toList(),
    );
  }

  // Count-only query — no document reads, no beneficiary enrichment
  static Future<int> getActiveAnomalyCount() async {
    final agg = await _db.collection('anomalies')
        .where('resolue', isEqualTo: false)
        .count()
        .get();
    return agg.count ?? 0;
  }

  static Future<void> resolveAnomaly(String id, bool resolue) async {
    await _db.collection('anomalies').doc(id).update({'resolue': resolue});
  }

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static Future<DashboardStats> getDashboard({String? mois}) async {
    Query rq = _db.collection('releves');
    if (mois != null) rq = rq.where('mois', isEqualTo: mois);
    Query pq = _db.collection('paiements');
    if (mois != null) pq = pq.where('mois', isEqualTo: mois);

    // All four queries fire in parallel
    final results = await Future.wait([
      rq.get(),
      pq.get(),
      _db.collection('anomalies').where('resolue', isEqualTo: false).get(),
      _db.collection('beneficiaires').where('actif', isEqualTo: true).get(),
    ]);

    final releves   = results[0];
    final paiements = results[1];
    final anomalies = results[2];
    final benefs    = results[3];

    double totalConso = 0, totalRev = 0, montantImp = 0;
    int paidCount = 0, unpaidCount = 0;
    final Map<String, double> mc = {}, mr = {};

    for (final doc in releves.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final c = (d['consommation'] as num).toDouble();
      final m = d['mois'] as String? ?? '';
      totalConso += c;
      mc[m] = (mc[m] ?? 0) + c;
    }
    for (final doc in paiements.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final amt = (d['montant'] as num).toDouble();
      final m = d['mois'] as String? ?? '';
      if (d['statut'] == 'paid') { totalRev += amt; mr[m] = (mr[m] ?? 0) + amt; paidCount++; }
      else { montantImp += amt; unpaidCount++; }
    }

    final totalBilled = totalRev + montantImp;
    return DashboardStats(
      totalConsommation: double.parse(totalConso.toStringAsFixed(2)),
      totalRevenus: double.parse(totalRev.toStringAsFixed(2)),
      montantImpaye: double.parse(montantImp.toStringAsFixed(2)),
      tauxRecouvrement: totalBilled > 0 ? double.parse((totalRev / totalBilled * 100).toStringAsFixed(1)) : 0,
      nbAnomalies: anomalies.docs.length,
      nbBeneficiaires: benefs.docs.length,
      nbReleves: releves.docs.length,
      monthlyConsumption: mc.entries.map((e) => {'mois': e.key, 'total': double.parse(e.value.toStringAsFixed(2))}).toList()..sort((a, b) => (a['mois'] as String).compareTo(b['mois'] as String)),
      monthlyRevenue: mr.entries.map((e) => {'mois': e.key, 'total': double.parse(e.value.toStringAsFixed(2))}).toList()..sort((a, b) => (a['mois'] as String).compareTo(b['mois'] as String)),
      paymentDistribution: {'paid': paidCount, 'unpaid': unpaidCount},
    );
  }
}
