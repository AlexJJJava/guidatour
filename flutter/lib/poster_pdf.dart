import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Testi già tradotti della locandina: il PDF non dipende dalla lingua.
class PosterData {
  const PosterData({
    required this.kicker,
    required this.title,
    required this.when,
    required this.meetingPoint,
    required this.price,
    required this.byline,
    required this.scanHint,
    required this.link,
    required this.imageAsset,
    this.notice,
  });
  final String kicker;
  final String title;
  final String when;
  final String meetingPoint;
  final String price;
  final String byline;
  final String scanHint;
  final String link;
  final String imageAsset;

  /// Avviso obbligatorio per i tour degli accompagnatori (BRD §13.4).
  final String? notice;
}

const _ink = PdfColor.fromInt(0xFF1E2A33);
const _gold = PdfColor.fromInt(0xFFB07A1E);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _sand = PdfColor.fromInt(0xFFF7EFE3);

Future<pw.Font> _font(String name) async =>
    pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));

/// Locandina A4 da stampare o condividere (BR-005).
Future<Uint8List> buildPosterPdf(PosterData d) async {
  final regular = await _font('Inter-Regular');
  final bold = await _font('Inter-Bold');
  final serif = await _font('PlayfairDisplay-Bold');
  final photo = pw.MemoryImage(
      (await rootBundle.load(d.imageAsset)).buffer.asUint8List());

  final doc = pw.Document(title: d.title, author: 'GuidaTour');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(d.kicker,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  font: bold, fontSize: 11, letterSpacing: 2, color: _gold)),
          pw.SizedBox(height: 14),
          pw.ClipRRect(
            horizontalRadius: 10,
            verticalRadius: 10,
            child: pw.SizedBox(
              height: 310,
              child: pw.Image(photo, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(d.title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  font: serif, fontSize: 30, lineSpacing: 2, color: _ink)),
          pw.SizedBox(height: 10),
          pw.Text(d.when,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 13, color: _ink)),
          pw.SizedBox(height: 4),
          pw.Text(d.meetingPoint,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 13, color: _ink)),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: _sand,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  color: PdfColors.white,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: d.link,
                    width: 150,
                    height: 150,
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(d.price,
                          style: pw.TextStyle(
                              font: bold, fontSize: 26, color: _gold)),
                      pw.SizedBox(height: 6),
                      pw.Text(d.byline,
                          style: const pw.TextStyle(fontSize: 12, color: _ink)),
                      pw.SizedBox(height: 12),
                      pw.Text(d.scanHint,
                          style: pw.TextStyle(
                              font: bold, fontSize: 13, color: _ink)),
                      if (d.notice != null) ...[
                        pw.SizedBox(height: 10),
                        pw.Text(d.notice!,
                            style:
                                const pw.TextStyle(fontSize: 9, color: _muted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(d.link,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
    ),
  );
  return doc.save();
}
