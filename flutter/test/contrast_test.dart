import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/widgets.dart';

/// Rapporto di contrasto WCAG tra due colori (da 1 a 21).
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Sfondi chiari su cui compaiono testi e icone.
  const backgrounds = {
    'bianco': kSurface,
    'crema': kCream,
    'sabbia': kSand,
    'giallo pagine': kPageYellow,
  };

  test('testi principali e secondari: almeno 4,5:1 su ogni sfondo chiaro', () {
    for (final bg in backgrounds.entries) {
      for (final fg in {
        'kInk': kInk,
        'kMuted': kMuted,
        'kPrimaryText': kPrimaryText,
      }.entries) {
        expect(contrast(fg.value, bg.value), greaterThanOrEqualTo(4.5),
            reason: '${fg.key} su ${bg.key}');
      }
    }
  });

  test('bordi dei campi: almeno 3:1 su bianco e crema', () {
    expect(contrast(kFieldLine, kSurface), greaterThanOrEqualTo(3));
    expect(contrast(kFieldLine, kCream), greaterThanOrEqualTo(3));
  });

  test('testo dei pulsanti oro, errori e conferme: almeno 4,5:1', () {
    expect(contrast(kOnGold, kGold), greaterThanOrEqualTo(4.5));
    expect(contrast(kDanger, kDangerBg), greaterThanOrEqualTo(4.5));
    expect(contrast(kSuccess, kSuccessBg), greaterThanOrEqualTo(4.5));
  });
}
