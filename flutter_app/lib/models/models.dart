// lib/models/models.dart

class Beneficiary {
  final String firestoreId;
  final int id, numero;
  final String nomArabe, nomFrancais;
  final String? telephone, adresse;
  final bool actif;
  final DateTime createdAt;

  Beneficiary({
    required this.firestoreId,
    required this.id,
    required this.numero,
    required this.nomArabe,
    required this.nomFrancais,
    this.telephone,
    this.adresse,
    required this.actif,
    required this.createdAt,
  });

  factory Beneficiary.fromFirestore(Map<String, dynamic> d, String docId) =>
      Beneficiary(
        firestoreId: docId,
        id: (d['sqlite_id'] as num?)?.toInt() ?? docId.hashCode,
        numero: (d['numero'] as num).toInt(),
        nomArabe: d['nom_arabe'] ?? '',
        nomFrancais: d['nom_francais'] ?? '',
        telephone: d['telephone'],
        adresse: d['adresse'],
        actif: d['actif'] ?? true,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class Reading {
  final String firestoreId;
  final String beneficiaryFirestoreId;
  final double ancienIndex, nouvelIndex, consommation, montant;
  final DateTime dateReleve;
  final String mois;
  final bool synced;
  final String? localId;
  final String? photoUrl;   // URL Firebase Storage
  Beneficiary? beneficiary;

  Reading({
    required this.firestoreId,
    required this.beneficiaryFirestoreId,
    required this.ancienIndex,
    required this.nouvelIndex,
    required this.consommation,
    required this.montant,
    required this.dateReleve,
    required this.mois,
    required this.synced,
    this.localId,
    this.photoUrl,
    this.beneficiary,
  });

  factory Reading.fromFirestore(Map<String, dynamic> d, String docId) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
    }
    return Reading(
      firestoreId: docId,
      beneficiaryFirestoreId: d['beneficiary_id'] ?? '',
      ancienIndex: (d['ancien_index'] as num).toDouble(),
      nouvelIndex: (d['nouvel_index'] as num).toDouble(),
      consommation: (d['consommation'] as num).toDouble(),
      montant: (d['montant'] as num).toDouble(),
      dateReleve: parseDate(d['date_releve']),
      mois: d['mois'] ?? '',
      synced: d['synced'] ?? true,
      localId: d['local_id'],
      photoUrl: d['photo_url'],
    );
  }
}

class Payment {
  final String firestoreId;
  final String beneficiaryFirestoreId;
  final String? readingFirestoreId;
  final double montant;
  /// statut: 'unpaid' | 'paid' | 'late'
  final String statut, mois;
  final DateTime? datePaiement, dateEcheance;
  Beneficiary? beneficiary;

  Payment({
    required this.firestoreId,
    required this.beneficiaryFirestoreId,
    this.readingFirestoreId,
    required this.montant,
    required this.statut,
    required this.mois,
    this.datePaiement,
    this.dateEcheance,
    this.beneficiary,
  });

  bool get isLate =>
      statut == 'unpaid' &&
      dateEcheance != null &&
      dateEcheance!.isBefore(DateTime.now());

  factory Payment.fromFirestore(Map<String, dynamic> d, String docId) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }
    return Payment(
      firestoreId: docId,
      beneficiaryFirestoreId: d['beneficiary_id'] ?? '',
      readingFirestoreId: d['reading_id'],
      montant: (d['montant'] as num).toDouble(),
      statut: d['statut'] ?? 'unpaid',
      mois: d['mois'] ?? '',
      datePaiement: parseDate(d['date_paiement']),
      dateEcheance: parseDate(d['date_echeance']),
    );
  }
}

class Anomaly {
  final String firestoreId;
  final String beneficiaryFirestoreId;
  final String? readingFirestoreId;
  final String typeAnomalie, mois;
  final double consommation, seuilDepasse;
  final String? description;
  final bool resolue;
  final DateTime dateDetection;
  Beneficiary? beneficiary;

  Anomaly({
    required this.firestoreId,
    required this.beneficiaryFirestoreId,
    this.readingFirestoreId,
    required this.typeAnomalie,
    required this.consommation,
    required this.seuilDepasse,
    this.description,
    required this.resolue,
    required this.dateDetection,
    required this.mois,
    this.beneficiary,
  });

  factory Anomaly.fromFirestore(Map<String, dynamic> d, String docId) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
    }
    return Anomaly(
      firestoreId: docId,
      beneficiaryFirestoreId: d['beneficiary_id'] ?? '',
      readingFirestoreId: d['reading_id'],
      typeAnomalie: d['type_anomalie'] ?? '',
      consommation: (d['consommation'] as num).toDouble(),
      seuilDepasse: (d['seuil_depasse'] as num).toDouble(),
      description: d['description'],
      resolue: d['resolue'] ?? false,
      dateDetection: parseDate(d['date_detection']),
      mois: d['mois'] ?? '',
    );
  }
}

class Tarification {
  final int seuil;
  final double prixTranche1, prixTranche2;
  final DateTime updatedAt;

  Tarification({
    required this.seuil,
    required this.prixTranche1,
    required this.prixTranche2,
    required this.updatedAt,
  });

  factory Tarification.fromFirestore(Map<String, dynamic> d) => Tarification(
        seuil: (d['seuil'] as num).toInt(),
        prixTranche1: (d['prix_tranche1'] as num).toDouble(),
        prixTranche2: (d['prix_tranche2'] as num).toDouble(),
        updatedAt: d['updated_at'] != null
            ? DateTime.tryParse(d['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  double calculateAmount(double consumption) {
    if (consumption <= seuil) {
      return double.parse((consumption * prixTranche1).toStringAsFixed(2));
    }
    return double.parse(
        ((seuil * prixTranche1) + ((consumption - seuil) * prixTranche2))
            .toStringAsFixed(2));
  }
}

class DashboardStats {
  final double totalConsommation, totalRevenus, montantImpaye, tauxRecouvrement;
  final int nbAnomalies, nbBeneficiaires, nbReleves;
  final List<Map<String, dynamic>> monthlyConsumption, monthlyRevenue;
  final Map<String, dynamic> paymentDistribution;

  DashboardStats({
    required this.totalConsommation,
    required this.totalRevenus,
    required this.montantImpaye,
    required this.tauxRecouvrement,
    required this.nbAnomalies,
    required this.nbBeneficiaires,
    required this.nbReleves,
    required this.monthlyConsumption,
    required this.monthlyRevenue,
    required this.paymentDistribution,
  });
}
