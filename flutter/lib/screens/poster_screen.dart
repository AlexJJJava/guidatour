import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';

/// Anteprima locandina con QR code (BR-004, BR-005).
class PosterScreen extends StatelessWidget {
  const PosterScreen({super.key, required this.tour});
  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final guide = appState.guideById(tour.guideId);
    final link = '${tour.url}?src=qr';
    return Scaffold(
      appBar: AppBar(title: const Text('QR e locandina')),
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
                border: Border.all(color: const Color(0xFFDCE5E0)),
              ),
              child: Column(
                children: [
                  const Text('GUIDATOUR · ROMA',
                      style: TextStyle(
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
                      '${fmtDate(tour.start)} · ${tour.duration} · ${tour.language}',
                      textAlign: TextAlign.center),
                  Text('Ritrovo: ${tour.meetingPoint}',
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
                  Text('con ${guide?.name} · ${guide?.role.label}',
                      style: const TextStyle(color: kMuted)),
                  const SizedBox(height: 6),
                  const Text(
                      'Inquadra il QR per info e richiesta di prenotazione',
                      style: TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(link, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) snack(context, 'Link copiato');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copia link'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                appState.recordScan(tour);
                snack(context,
                    'Scansione simulata registrata (${tour.scans} totali)');
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Simula una scansione (demo)'),
            ),
            const Text(
                'L’esportazione PDF della locandina sarà aggiunta nel prossimo passo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: kMuted)),
          ],
        ),
      ),
    );
  }
}
