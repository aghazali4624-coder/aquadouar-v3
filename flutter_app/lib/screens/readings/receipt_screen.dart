// lib/screens/readings/receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_settings.dart';
import '../../l10n/app_l10n.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReceiptScreen extends StatelessWidget {
  final Reading     reading;
  final Beneficiary beneficiary;
  const ReceiptScreen({super.key, required this.reading, required this.beneficiary});

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<AppSettings>().l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.avisRecu), backgroundColor: AppColors.darkBlue,
        actions: [IconButton(icon: const Icon(Icons.print, color: Colors.white), onPressed: () => _print(context))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Receipt card
          Container(
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))]),
            child: Column(children: [
              Container(
                decoration: const BoxDecoration(gradient: AppColors.blueGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.water_drop, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text('AquaDouar', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(l10n.avisConsommation, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  _Row(l10n.beneficiaire, beneficiary.nomFrancais),
                  _Row(l10n.numAbonne,    '${beneficiary.numero}'),
                  _Row(l10n.mois,         formatMonth(reading.mois)),
                  _Row(l10n.dateReleveLabel, formatDate(reading.dateReleve)),
                  const Divider(height: 24),
                  _Row(l10n.ancienIndex,  '${reading.ancienIndex.toStringAsFixed(1)} m³'),
                  _Row(l10n.nouvelIndex,  '${reading.nouvelIndex.toStringAsFixed(1)} m³'),
                  _Row(l10n.consommation, '${reading.consommation.toStringAsFixed(1)} m³', highlight: true),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(l10n.montantDu, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(formatAmount(reading.montant),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.success)),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: () => _print(context),
              icon: const Icon(Icons.print_outlined),
              label: Text(l10n.imprimer),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(width: 12),
            if (beneficiary.telephone != null)
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _sendWhatsApp(context, l10n),
                icon: const Icon(Icons.send_outlined),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
          ]),
        ]),
      ),
    );
  }

  Future<void> _print(BuildContext context) async {
    final l10n = context.read<AppSettings>().l10n;
    final isAr = l10n.isAr;

    final regular = await PdfGoogleFonts.cairoRegular();
    final bold    = await PdfGoogleFonts.cairoBold();
    final theme   = pw.ThemeData.withFont(base: regular, bold: bold);
    final doc = pw.Document(theme: theme);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => _buildPdf(isAr, l10n),
    ));

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _buildPdf(bool isAr, AppL10n l10n) {
    final navyBlue  = PdfColor.fromHex('#0D1B4E');
    final royalBlue = PdfColor.fromHex('#2563EB');
    final lightBg   = PdfColor.fromHex('#EFF6FF');
    final grey600   = PdfColor.fromHex('#64748B');
    final grey200   = PdfColor.fromHex('#E2E8F0');
    final green     = PdfColor.fromHex('#10B981');

    final textDir  = isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final crossEnd = isAr ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    const white60  = PdfColor(1, 1, 1, 0.6);
    const white38  = PdfColor(1, 1, 1, 0.38);

    pw.TextStyle bold(double size, {PdfColor? color}) =>
        pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold, color: color);
    pw.TextStyle reg(double size, {PdfColor? color}) =>
        pw.TextStyle(fontSize: size, color: color);

    // ── Helper: label-value row ──
    pw.Widget infoRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: isAr ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.spaceBetween,
        children: isAr ? [
          pw.Text(value, style: bold(11),                       textDirection: textDir),
          pw.SizedBox(width: 12),
          pw.Text(label, style: reg(11, color: grey600),        textDirection: textDir),
        ] : [
          pw.Text(label, style: reg(11, color: grey600)),
          pw.Text(value, style: bold(11)),
        ],
      ),
    );

    // ── Helper: section title ──
    pw.Widget sectionTitle(String title) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(color: royalBlue, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Text(title, style: bold(10, color: PdfColors.white), textDirection: textDir),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [

          // ══ HEADER ════════════════════════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(
              color: navyBlue,
              borderRadius: pw.BorderRadius.circular(14),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: isAr ? [
                // AR: date on left, title on right
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(formatDate(reading.dateReleve), style: reg(10, color: white60)),
                  pw.SizedBox(height: 4),
                  pw.Text('رقم: ${reading.firestoreId.length >= 8 ? reading.firestoreId.substring(0, 8) : reading.firestoreId}',
                      style: reg(9, color: white38), textDirection: textDir),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('AquaDouar', style: bold(24, color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(l10n.avisConsommation, style: reg(11, color: white60), textDirection: textDir),
                ]),
              ] : [
                // FR: title on left, date on right
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('AquaDouar', style: bold(24, color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(l10n.avisConsommation, style: reg(11, color: white60)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(formatDate(reading.dateReleve), style: reg(10, color: white60)),
                  pw.SizedBox(height: 4),
                  pw.Text('Réf: ${reading.firestoreId.length >= 8 ? reading.firestoreId.substring(0, 8) : reading.firestoreId}',
                      style: reg(9, color: white38)),
                ]),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // ══ BENEFICIARY SECTION ═══════════════════════════════════════════════
          sectionTitle(l10n.sectionBenef),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: grey200),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: pw.Column(crossAxisAlignment: crossEnd, children: [
              infoRow(l10n.beneficiaire, beneficiary.nomFrancais),
              if (beneficiary.nomArabe.isNotEmpty)
                infoRow(isAr ? 'الاسم' : 'Nom arabe', beneficiary.nomArabe),
              infoRow(l10n.numAbonne, '${beneficiary.numero}'),
              infoRow(l10n.mois, formatMonth(reading.mois)),
              infoRow(l10n.dateReleveLabel, formatDate(reading.dateReleve)),
            ]),
          ),

          pw.SizedBox(height: 16),

          // ══ METER READINGS SECTION ════════════════════════════════════════════
          sectionTitle(l10n.sectionReleve),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: grey200),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: pw.Column(crossAxisAlignment: crossEnd, children: [
              infoRow(l10n.ancienIndex, '${reading.ancienIndex.toStringAsFixed(1)} m³'),
              pw.Divider(color: grey200, height: 16),
              infoRow(l10n.nouvelIndex, '${reading.nouvelIndex.toStringAsFixed(1)} m³'),
              pw.Divider(color: grey200, height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#DBEAFE'), borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Row(
                  mainAxisAlignment: isAr ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.spaceBetween,
                  children: isAr ? [
                    pw.Text('${reading.consommation.toStringAsFixed(1)} m³', style: bold(13, color: royalBlue), textDirection: textDir),
                    pw.SizedBox(width: 12),
                    pw.Text(l10n.consommation, style: bold(12, color: royalBlue), textDirection: textDir),
                  ] : [
                    pw.Text(l10n.consommation, style: bold(12, color: royalBlue)),
                    pw.Text('${reading.consommation.toStringAsFixed(1)} m³', style: bold(13, color: royalBlue)),
                  ],
                ),
              ),
            ]),
          ),

          pw.SizedBox(height: 20),

          // ══ AMOUNT DUE ════════════════════════════════════════════════════════
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F0FDF4'),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: green, width: 2),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: isAr ? [
                pw.Text('${reading.montant.toStringAsFixed(2)} DH',
                    style: bold(30, color: green), textDirection: textDir),
                pw.Text(l10n.montantDu, style: bold(14, color: navyBlue), textDirection: textDir),
              ] : [
                pw.Text(l10n.montantDu, style: bold(14, color: navyBlue)),
                pw.Text('${reading.montant.toStringAsFixed(2)} DH',
                    style: bold(30, color: green)),
              ],
            ),
          ),

          pw.Spacer(),

          // ══ FOOTER ════════════════════════════════════════════════════════════
          pw.Divider(color: grey200),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: isAr ? [
              pw.Text(formatDate(reading.dateReleve), style: reg(9, color: grey600)),
              pw.Text(l10n.signature, style: reg(9, color: grey600), textDirection: textDir),
            ] : [
              pw.Text(l10n.signature, style: reg(9, color: grey600)),
              pw.Text(formatDate(reading.dateReleve), style: reg(9, color: grey600)),
            ],
          ),
        ],
      ),
    );
  }

  void _sendWhatsApp(BuildContext context, AppL10n l10n) async {
    final phone = beneficiary.telephone!.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = l10n.isAr
        ? Uri.encodeComponent(
            'مرحباً ${beneficiary.nomArabe.isNotEmpty ? beneficiary.nomArabe : beneficiary.nomFrancais}،\n'
            'إشعار استهلاك ${reading.mois}:\n'
            '• الاستهلاك: ${reading.consommation.toStringAsFixed(1)} م³\n'
            '• المبلغ المستحق: ${reading.montant.toStringAsFixed(2)} درهم\n'
            'شكراً – AquaDouar')
        : Uri.encodeComponent(
            'Bonjour ${beneficiary.nomFrancais},\nAvis de consommation ${reading.mois}:\n'
            '• Consommation: ${reading.consommation.toStringAsFixed(1)} m³\n'
            '• Montant dû: ${reading.montant.toStringAsFixed(2)} DH\nMerci – AquaDouar');
    final url = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    else if (context.mounted) showError(context, l10n.isAr ? 'واتساب غير متاح' : 'WhatsApp non disponible');
  }
}

class _Row extends StatelessWidget {
  final String label, value; final bool highlight;
  const _Row(this.label, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
      Text(value, style: TextStyle(fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          fontSize: highlight ? 15 : 13, color: highlight ? AppColors.primaryBlue : AppColors.textDark)),
    ]),
  );
}
