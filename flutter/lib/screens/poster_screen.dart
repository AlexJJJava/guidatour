import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Anteprima locandina con QR code (BR-004, BR-005).
class PosterScreen extends StatelessWidget {
  const PosterScreen({super.key, required this.tour});
  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final guide = appState.guideById(tour.guideId);
    final link = '${tour.url}?src=qr';
    return Scaffold(
      appBar: AppBar(title: Text(t.qrAndPoster)),
      body: PageBody(
        maxWidth: 560,
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
                          color: kInk)),
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
                      t.posterByGuide(guide?.name ?? '',
                          guide == null ? '' : roleLabel(context, guide.role)),
                      style: const TextStyle(color: kMuted)),
                  const SizedBox(height: 6),
                  Text(t.posterScanHint,
                      style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
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
            Text(t.posterPdfComingSoon,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
        ),
      ),
    );
  }
}
