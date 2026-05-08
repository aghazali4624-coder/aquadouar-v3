// lib/screens/payments/payments_screen.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../app_settings.dart';
import '../../models/models.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Payment> _unpaid = [], _paid = [], _late = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all    = await DbService.getPayments();
      final now    = DateTime.now();
      final unpaid = all.where((p) => p.statut == 'unpaid' && !(p.dateEcheance?.isBefore(now) ?? false)).toList();
      final paid   = all.where((p) => p.statut == 'paid').toList();
      final late_  = all.where((p) => p.statut == 'late' || (p.statut == 'unpaid' && (p.dateEcheance?.isBefore(now) ?? false))).toList();
      setState(() { _unpaid = unpaid; _paid = paid; _late = late_; _loading = false; });
    } catch (e) { setState(() => _loading = false); if (mounted) showError(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<AppSettings>().l10n.paiementsTitle),
        backgroundColor: AppColors.darkBlue,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: context.read<AppSettings>().l10n.tabImpayes(_unpaid.length)),
            Tab(text: context.read<AppSettings>().l10n.tabPayes(_paid.length)),
            Tab(text: context.read<AppSettings>().l10n.tabRetard(_late.length)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : TabBarView(controller: _tabs, children: [
        _PaymentList(payments: _unpaid, type: 'unpaid', onRefresh: _load),
        _PaymentList(payments: _paid,   type: 'paid',   onRefresh: _load),
        _PaymentList(payments: _late,   type: 'late',   onRefresh: _load),
      ]),
    );
  }
}

// ── Payment List ──────────────────────────────────────────────────────────────
class _PaymentList extends StatelessWidget {
  final List<Payment> payments;
  final String        type;
  final VoidCallback  onRefresh;
  const _PaymentList({required this.payments, required this.type, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<AppSettings>().l10n;
    if (payments.isEmpty) {
      return EmptyState(
        message: type == 'paid' ? l10n.aucunPaiement
            : type == 'unpaid' ? l10n.aucunImpaye
            : l10n.aucunRetard,
        icon: type == 'paid' ? Icons.check_circle_outline : Icons.payments_outlined,
      );
    }
    final total = payments.fold<double>(0, (s, p) => s + p.montant);
    LinearGradient grad = type == 'paid' ? AppColors.greenGradient
        : type == 'unpaid' ? AppColors.orangeGradient : AppColors.redGradient;

    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.nPaiements(payments.length),
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text(formatAmount(total),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          ]),
          Icon(type == 'paid' ? Icons.check_circle : type == 'unpaid' ? Icons.pending : Icons.warning_amber,
              color: Colors.white.withValues(alpha: 0.8), size: 36),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: payments.length,
          itemBuilder: (ctx, i) => _PaymentTile(payment: payments[i], type: type, onRefresh: onRefresh),
        ),
      ),
    ]);
  }
}

// ── Payment Tile with correct buttons per tab ─────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final Payment      payment;
  final String       type;
  final VoidCallback onRefresh;
  const _PaymentTile({required this.payment, required this.type, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(16),
        border: type == 'late' ? Border.all(color: AppColors.danger.withValues(alpha: 0.3)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: (type == 'paid' ? AppColors.success : type == 'unpaid' ? AppColors.warning : AppColors.danger).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              type == 'paid' ? Icons.check_circle : type == 'unpaid' ? Icons.pending : Icons.warning_amber,
              color: type == 'paid' ? AppColors.success : type == 'unpaid' ? AppColors.warning : AppColors.danger, size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(payment.beneficiary?.nomFrancais ?? 'N°${payment.beneficiaryFirestoreId.substring(0, 6)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(formatMonth(payment.mois), style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            if (type == 'late' && payment.dateEcheance != null)
              Text('Échu le ${formatDate(payment.dateEcheance!)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
            if (type == 'paid' && payment.datePaiement != null)
              Text('Payé le ${formatDate(payment.datePaiement!)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.success)),
          ])),
          Text(formatAmount(payment.montant),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 12),

        // ── Buttons per tab ──────────────────────────────────────────────────
        if (type == 'unpaid') ...[
          // IMPAYÉS: [Générer un avis] + [Marquer comme payé]
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _generateNotice(context),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('Générer un avis', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _markPaid(context),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Marquer payé', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
          ]),
        ] else if (type == 'paid') ...[
          // PAYÉS: [Générer reçu]
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateReceipt(context),
              icon: const Icon(Icons.receipt_outlined, size: 16),
              label: const Text('Générer un reçu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ] else ...[
          // RETARD: [Générer avertissement]
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateWarning(context),
              icon: const Icon(Icons.warning_amber_outlined, size: 16),
              label: const Text('Générer un avertissement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Mark as paid ────────────────────────────────────────────────────────────
  Future<void> _markPaid(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text('Marquer ${payment.beneficiary?.nomFrancais ?? ''} comme payé (${formatAmount(payment.montant)}) ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DbService.markAsPaid(payment.firestoreId);
        if (context.mounted) { showSuccess(context, 'Paiement enregistré'); onRefresh(); }
      } catch (e) { if (context.mounted) showError(context, '$e'); }
    }
  }

  // ── Generate Notice (Avis) ──────────────────────────────────────────────────
  Future<void> _generateNotice(BuildContext context) async {
    await _printDocument(context, title: 'AVIS DE PAIEMENT',
        subtitle: 'Veuillez régler votre facture au plus tôt.');
  }

  // ── Generate Receipt (Reçu) ─────────────────────────────────────────────────
  Future<void> _generateReceipt(BuildContext context) async {
    await _printDocument(context, title: 'REÇU DE PAIEMENT',
        subtitle: 'Paiement reçu le ${payment.datePaiement != null ? formatDate(payment.datePaiement!) : "—"}.');
  }

  // ── Generate Warning (Avertissement) ───────────────────────────────────────
  Future<void> _generateWarning(BuildContext context) async {
    await _printDocument(context, title: 'AVERTISSEMENT DE RETARD',
        subtitle: '⚠️ Votre paiement est en retard. Merci de régulariser immédiatement.');
  }

  Future<void> _printDocument(BuildContext context, {required String title, required String subtitle}) async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold    = await PdfGoogleFonts.cairoBold();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text('AquaDouar', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        pw.Divider(), pw.SizedBox(height: 8),
        pw.Text('Bénéficiaire : ${payment.beneficiary?.nomFrancais ?? "-"}'),
        pw.Text('N° Abonné   : ${payment.beneficiary?.numero ?? "-"}'),
        pw.Text('Mois        : ${payment.mois}'),
        pw.Divider(), pw.SizedBox(height: 8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Montant :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('${payment.montant.toStringAsFixed(2)} DH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        ]),
        if (payment.dateEcheance != null) ...[
          pw.SizedBox(height: 8),
          pw.Text('Date d\'echeance : ${formatDate(payment.dateEcheance!)}'),
        ],
        pw.SizedBox(height: 16), pw.Divider(),
        pw.Text(subtitle, style: pw.TextStyle(fontSize: 12)),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}
