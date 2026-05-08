// lib/l10n/app_l10n.dart
class AppL10n {
  final bool isAr;
  const AppL10n({required this.isAr});

  // ── Navigation ──────────────────────────────────────────────────────────────
  String get accueil     => isAr ? 'الرئيسية' : 'Accueil';
  String get profil      => isAr ? 'الملف'     : 'Profil';
  String get parametresNav => isAr ? 'الإعدادات' : 'Paramètres';

  // ── Home ────────────────────────────────────────────────────────────────────
  String get bonjour        => isAr ? 'مرحباً 👋'                   : 'Bonjour 👋';
  String get relevesTitle   => isAr ? 'القراءات'                     : 'RELEVÉS';
  String get saisirIndex    => isAr ? 'تسجيل قراءات العدادات'        : 'Saisir les index des compteurs';
  String get paiementRetard => isAr ? 'المدفوعات\n& المتأخرات'       : 'Paiement\n& Retard';
  String get beneficiaires  => isAr ? 'المستفيدون'                   : 'Bénéficiaires';
  String get anomalies      => isAr ? 'الشذوذات'                     : 'Anomalies';
  String get dashboardNav   => isAr ? 'لوحة التحكم'                  : 'Dashboard';

  // ── Auth ────────────────────────────────────────────────────────────────────
  String get connexion          => isAr ? 'تسجيل الدخول'             : 'Connexion';
  String get gestionEau         => isAr ? 'إدارة شبكة المياه'        : 'Gestion de l\'eau';
  String get email              => isAr ? 'البريد الإلكتروني'         : 'Email';
  String get motDePasse         => isAr ? 'كلمة المرور'              : 'Mot de passe';
  String get seConnecter        => isAr ? 'تسجيل الدخول'             : 'Se connecter';
  String get chargement         => isAr ? 'جارٍ التحميل...'          : 'Chargement...';

  // ── Logout ──────────────────────────────────────────────────────────────────
  String get deconnexion         => isAr ? 'تسجيل الخروج'            : 'Déconnexion';
  String get confirmDeconnexion  => isAr ? 'هل تريد تسجيل الخروج؟'  : 'Voulez-vous vous déconnecter ?';
  String get annuler             => isAr ? 'إلغاء'                   : 'Annuler';

  // ── Dashboard ───────────────────────────────────────────────────────────────
  String get dashboardTitle       => isAr ? 'لوحة التحكم'            : 'Dashboard';
  String get consommationTotale   => isAr ? 'إجمالي الاستهلاك'       : 'Consommation totale';
  String get toutesPeriodes       => isAr ? 'جميع الفترات'           : 'Toutes périodes';
  String get revenusEncaisses     => isAr ? 'الإيرادات المحصلة'      : 'Revenus encaissés';
  String get paiementsRecus       => isAr ? 'المدفوعات المستلمة'     : 'Paiements reçus';
  String get montantImpaye        => isAr ? 'المبلغ غير المدفوع'     : 'Montant impayé';
  String get enAttente            => isAr ? 'في الانتظار'            : 'En attente';
  String get anomaliesActives     => isAr ? 'الشذوذات النشطة'        : 'Anomalies actives';
  String get nonResolues          => isAr ? 'غير محلولة'             : 'Non résolues';
  String get tauxRecouvrement     => isAr ? 'معدل الاسترداد'         : 'Taux de recouvrement';
  String benefActifs(int n)       => isAr ? '$n مستفيد نشط'          : '$n bénéficiaires actifs';
  String relevesCount(int n)      => isAr ? '$n قراءة'               : '$n relevés';
  String get repartitionPaiements => isAr ? 'توزيع المدفوعات'        : 'Répartition des paiements';
  String get payes                => isAr ? 'مدفوع'                  : 'Payés';
  String get impayes              => isAr ? 'غير مدفوع'              : 'Impayés';
  String get consommationMens     => isAr ? 'الاستهلاك الشهري (م³)'  : 'Consommation mensuelle (m³)';
  String get revenusMensuels      => isAr ? 'الإيرادات الشهرية (درهم)' : 'Revenus mensuels (DH)';
  String get aucuneDonnee         => isAr ? 'لا توجد بيانات'         : 'Aucune donnée';

  // ── Payments ─────────────────────────────────────────────────────────────────
  String get paiementsTitle       => isAr ? 'المدفوعات والمتأخرات'  : 'Paiements & Retards';
  String tabImpayes(int n)        => isAr ? 'غير مدفوع ($n)'        : 'Impayés ($n)';
  String tabPayes(int n)          => isAr ? 'مدفوع ($n)'            : 'Payés ($n)';
  String tabRetard(int n)         => isAr ? 'متأخر ($n)'            : 'Retard ($n)';
  String get aucunPaiement        => isAr ? 'لا توجد مدفوعات'       : 'Aucun paiement effectué';
  String get aucunImpaye          => isAr ? 'لا توجد مستحقات 🎉'    : 'Aucun impayé 🎉';
  String get aucunRetard          => isAr ? 'لا توجد متأخرات 🎉'    : 'Aucun retard 🎉';
  String nPaiements(int n)        => isAr ? '$n مدفوعة'             : '$n paiement${n != 1 ? 's' : ''}';
  String get marquerPaye          => isAr ? 'وضع كمدفوع'            : 'Marquer payé';
  String get detailsPaiement      => isAr ? 'تفاصيل الدفع'          : 'Détails paiement';
  String get exporterPdf          => isAr ? 'تصدير PDF'             : 'Exporter PDF';

  // ── Anomalies ────────────────────────────────────────────────────────────────
  String get anomaliesTitle         => isAr ? 'الشذوذات'            : 'Anomalies';
  String tabActives(int n)          => isAr ? 'نشطة ($n)'           : 'Actives ($n)';
  String tabResolues(int n)         => isAr ? 'محلولة ($n)'         : 'Résolues ($n)';
  String get aucuneAnomalieResolue  => isAr ? 'لا توجد شذوذات محلولة' : 'Aucune anomalie résolue';
  String get aucuneAnomalieActive   => isAr ? 'لا توجد شذوذات نشطة ✅' : 'Aucune anomalie active ✅';
  String get resoudre               => isAr ? 'حل'                  : 'Résoudre';
  String get anomalieResolue        => isAr ? 'تم حل الشذوذ'        : 'Anomalie résolue';

  // ── Beneficiaries ────────────────────────────────────────────────────────────
  String get benfTitle    => isAr ? 'المستفيدون'  : 'Bénéficiaires';
  String get rechercher   => isAr ? 'بحث...'       : 'Rechercher...';
  String get actifs       => isAr ? 'النشطون فقط' : 'Actifs seulement';
  String get tous         => isAr ? 'الكل'         : 'Tous';

  // ── Readings ─────────────────────────────────────────────────────────────────
  String get relevesScreenTitle => isAr ? 'القراءات'           : 'Relevés';
  String get nouveauReleve      => isAr ? 'قراءة جديدة'        : 'Nouveau relevé';
  String get historique         => isAr ? 'السجل'              : 'Historique';

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get parametresTitle  => isAr ? 'الإعدادات'          : 'Paramètres';
  String get tarificationSec  => isAr ? '💰 التسعير'          : '💰 Tarification';
  String get preferencesSec   => isAr ? '⚙️ التفضيلات'         : '⚙️ Préférences';
  String get langueLabel      => isAr ? 'اللغة'               : 'Langue';
  String get themeLabel       => isAr ? 'السمة'               : 'Thème';
  String get imprimanteLabel  => isAr ? 'طابعة بلوتوث'        : 'Imprimante Bluetooth';
  String get aProposSec       => isAr ? 'ℹ️ حول التطبيق'       : 'ℹ️ À propos';

  // ── Receipt / PDF ────────────────────────────────────────────────────────────
  String get avisRecu         => isAr ? 'إشعار / إيصال'                 : 'Avis / Reçu';
  String get avisConsommation => isAr ? 'إشعار استهلاك المياه'           : 'Avis de consommation d\'eau';
  String get beneficiaire     => isAr ? 'المستفيد'                      : 'Bénéficiaire';
  String get numAbonne        => isAr ? 'رقم المشترك'                   : 'N° Abonné';
  String get mois             => isAr ? 'الشهر'                         : 'Mois';
  String get dateReleveLabel  => isAr ? 'تاريخ القراءة'                  : 'Date relevé';
  String get ancienIndex      => isAr ? 'القراءة السابقة'               : 'Ancien index';
  String get nouvelIndex      => isAr ? 'القراءة الجديدة'               : 'Nouvel index';
  String get consommation     => isAr ? 'الاستهلاك'                     : 'Consommation';
  String get montantDu        => isAr ? 'المبلغ المستحق'                : 'MONTANT DÛ';
  String get imprimer         => isAr ? 'طباعة'                         : 'Imprimer';
  String get sectionBenef     => isAr ? 'معلومات المشترك'               : 'INFORMATIONS BÉNÉFICIAIRE';
  String get sectionReleve    => isAr ? 'بيانات العداد'                  : 'RELEVÉ DU COMPTEUR';
  String get signature        => isAr ? 'التوقيع: _______________'       : 'Signature: _______________';
  String get reference        => isAr ? 'المرجع'                        : 'Réf';

  // ── Common ───────────────────────────────────────────────────────────────────
  String get fermer      => isAr ? 'إغلاق'    : 'Fermer';
  String get sauvegarder => isAr ? 'حفظ'      : 'Sauvegarder';
  String get modifier    => isAr ? 'تعديل'    : 'Modifier';
  String get confirmer   => isAr ? 'تأكيد'    : 'Confirmer';
  String get compris     => isAr ? 'فهمت'     : 'Compris';
  String get refresh     => isAr ? 'تحديث'    : 'Actualiser';

  // ── Month names (for charts) ──────────────────────────────────────────────────
  List<String> get monthNames => isAr
      ? ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
      : ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
}
