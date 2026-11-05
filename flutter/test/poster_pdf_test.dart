import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/poster_pdf.dart';

const data = PosterData(
  kicker: 'GUIDATOUR · ROMA',
  title: 'Passeggiata serale tra i vicoli di Trastevere e il Gianicolo',
  when: '24/12/2099 18:00 · 2 ore · Italiano',
  meetingPoint: 'Ritrovo: Piazza di Santa Maria in Trastevere',
  price: '25 €',
  byline: 'con Giulia Romano · Guida turistica',
  scanHint: 'Inquadra il QR per info e richiesta di prenotazione',
  link: 'https://alexjjjava.github.io/guidatour/?tour=t1&src=qr',
  imageAsset: 'assets/images/cat_serale.jpg',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la locandina è un PDF A4 di una pagina con caratteri e foto', () async {
    final bytes = await buildPosterPdf(data);
    final text = latin1.decode(bytes);
    expect(text.startsWith('%PDF'), isTrue);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 1);
    // A4 in punti: 595 × 842.
    expect(text, contains('595.27'));
    expect(text, contains('841.88'));
    // Caratteri incorporati e foto: il file non può essere minuscolo.
    expect(bytes.length, greaterThan(50000));
  });

  test("l'avviso dell'accompagnatore non rompe l'impaginazione", () async {
    final bytes = await buildPosterPdf(const PosterData(
      kicker: 'GUIDATOUR · ROMA',
      title: 'Assistenza gruppi',
      when: '24/12/2099 18:00 · 2 ore · Italiano',
      meetingPoint: 'Ritrovo: Piazza Navona',
      price: '10 €',
      byline: 'con Sara Conti · Accompagnatore turistico',
      scanHint: 'Inquadra il QR',
      link: 'https://alexjjjava.github.io/guidatour/?tour=t2&src=qr',
      imageAsset: 'assets/images/cat_accompagnamento.jpg',
      notice: 'L’accompagnatore turistico non è una guida abilitata.',
    ));
    final text = latin1.decode(bytes);
    expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 1);
  });
}
