import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../poster_pdf.dart';
import '../state.dart';
import '../widgets.dart';

/// La locandina resta chiara (si stampa) anche con il tema scuro dell'app.
const _paperInk = Color(0xFF1E2A33);

/// Anteprima locandina con QR code (BR-004, BR-005).
class PosterScreen extends StatelessWidget {
  const PosterScreen({super.key, required this.tour});
  final Tour tour;

  PosterData _data(BuildContext context, String link) {
    final t = l10n(context);
    final guide = appState.guideById(tour.guideId);
    return PosterData(
      kicker: 'GUIDATOUR · ${cityLabel(context, tour.city).toUpperCase()}',
      title: tour.title,
      when:
          '${fmtDate(tour.start)} · ${tour.duration} · ${languageLabel(context, tour.language)}',
      meetingPoint: t.detailMeetingPoint(tour.meetingPoint),
      price: fmtPrice(tour.price),
      byline: t.posterByGuide(guide?.name ?? '',
          guide == null ? '' : rolesLabel(context, guide.roles)),
      scanHint: t.posterScanHint,
      link: link,
      imageAsset: categoryImage(tour.category),
      notice: guide?.onlyAccompagnatore == true ? t.accompagnatoreNotice : null,
    );
  }

  Future<void> _pdf(BuildContext context, String link,
      {required bool print}) async {
    final t = l10n(context);
    final data = _data(context, link);
    final name = 'locandina-${tour.id}.pdf';
    try {
      final bytes = await buildPosterPdf(data);
      if (print) {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: name);
      }
    } catch (_) {
      if (context.mounted) snack(context, t.posterPdfError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final guide = appState.guideById(tour.guideId);
    final link = '${tour.url}&src=qr';
    return Scaffold(
      body: PageBody(
        maxWidth: 560,
        title: t.qrAndPoster,
        icon: Icons.qr_code_2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEAE2D3)),
              ),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: _paperInk),
                child: Column(
                  children: [
                    Text(
                        'GUIDATOUR · ${cityLabel(context, tour.city).toUpperCase()}',
                        style: const TextStyle(
                            letterSpacing: 2,
                            fontSize: 12,
                            color: kPrimary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Text(tour.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: _paperInk)),
                    const SizedBox(height: 10),
                    Text(
                        '${fmtDate(tour.start)} · ${tour.duration} · ${languageLabel(context, tour.language)}',
                        textAlign: TextAlign.center),
                    Text(t.detailMeetingPoint(tour.meetingPoint),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    QrImageView(data: link, size: 200),
                    const SizedBox(height: 10),
                    Text(fmtPrice(tour.price),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kPrimary)),
                    const SizedBox(height: 6),
                    Text(
                        t.posterByGuide(
                            guide?.name ?? '',
                            guide == null
                                ? ''
                                : rolesLabel(context, guide.roles)),
                        style: const TextStyle(color: kMuted)),
                    const SizedBox(height: 6),
                    Text(t.posterScanHint,
                        style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => _pdf(context, link, print: false),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(t.posterDownloadPdf),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pdf(context, link, print: true),
                  icon: const Icon(Icons.print_outlined),
                  label: Text(t.posterPrint),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(link, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) snack(context, t.linkCopied);
              },
              icon: const Icon(Icons.copy),
              label: Text(t.copyLink),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                try {
                  await appState.recordScan(tour);
                  if (context.mounted) {
                    snack(context, t.scanSimulated(tour.scans));
                  }
                } catch (e) {
                  if (context.mounted) snack(context, '$e');
                }
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(t.simulateScan),
            ),
          ],
        ),
      ),
    );
  }
}
