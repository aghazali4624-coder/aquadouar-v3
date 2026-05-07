// lib/screens/readings/receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ReceiptScreen extends StatelessWidget {
  final Reading     reading;
  final Beneficiary beneficiary;
  const ReceiptScreen({super.key, required this.reading, required this.beneficiary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avis / Reçu'), backgroundColor: AppColors.darkBlue,
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
                child: Column(children: const [
                  Icon(Icons.water_drop, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text('AquaDouar', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('Avis de consommation d\'eau', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  _Row('Bénéficiaire', beneficiary.nomFrancais),
                  _Row('N° Abonné', '${beneficiary.numero}'),
                  _Row('Mois', formatMonth(reading.mois)),
                  _Row('Date relevé', formatDate(reading.dateReleve)),
                  const Divider(height: 24),
                  _Row('Ancien index', '${reading.ancienIndex.toStringAsFixed(1)} m³'),
                  _Row('Nouvel index', '${reading.nouvelIndex.toStringAsFixed(1)} m³'),
                  _Row('Consommation', '${reading.consommation.toStringAsFixed(1)} m³', highlight: true),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('MONTANT DÛ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
              label: const Text('Imprimer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(width: 12),
            if (beneficiary.telephone != null)
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _sendWhatsApp(context),
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
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold    = await PdfGoogleFonts.cairoBold();
    final theme   = pw.ThemeData.withFont(base: regular, bold: bold);
    final doc = pw.Document(theme: theme);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(child: pw.Text('AquaDouar - Avis de consommation',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 16), pw.Divider(),
        _pdfRow('Beneficiaire', beneficiary.nomFrancais),
        _pdfRow('N° Abonne', '${beneficiary.numero}'),
        _pdfRow('Mois', reading.mois),
        _pdfRow('Date', formatDate(reading.dateReleve)),
        pw.Divider(),
        _pdfRow('Ancien index', '${reading.ancienIndex} m³'),
        _pdfRow('Nouvel index', '${reading.nouvelIndex} m³'),
        _pdfRow('Consommation', '${reading.consommation} m³'),
        pw.Divider(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('MONTANT DU:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('${reading.montant.toStringAsFixed(2)} DH',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(label, style: pw.TextStyle(color: PdfColors.grey600)),
      pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ]),
  );

  void _sendWhatsApp(BuildContext context) async {
    final phone = beneficiary.telephone!.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
        'Bonjour ${beneficiary.nomFrancais},\nAvis de consommation ${reading.mois}:\n'
        '• Consommation: ${reading.consommation.toStringAsFixed(1)} m³\n'
        '• Montant dû: ${reading.montant.toStringAsFixed(2)} DH\nMerci – AquaDouar');
    final url = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    else if (context.mounted) showError(context, 'WhatsApp non disponible');
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
