import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/screens/home_screen.dart';

/// Riga della foto visibile sul fondo della copertina, da 0 (cima) a 1.
double bottomRow(Size box) {
  final scale = box.width / 3920 > box.height / 1000
      ? box.width / 3920
      : box.height / 1000;
  final shown = 1000 * scale;
  final free = shown - box.height;
  final top = (heroPhotoAlignmentY(box) + 1) / 2 * free;
  return (top + box.height) / shown;
}

void main() {
  test('accorciando la copertina si taglia il cielo, non il fondo', () {
    for (final width in [1920.0, 2560.0]) {
      expect(bottomRow(Size(width, 375)), closeTo(0.867, 0.001));
      expect(bottomRow(Size(width, 340)), closeTo(0.867, 0.001));
    }
  });

  test('se la foto entra tutta in altezza resta centrata', () {
    expect(heroPhotoAlignmentY(const Size(1280, 340)), 0);
    expect(heroPhotoAlignmentY(const Size(360, 520)), 0);
  });

  test('su schermi molto larghi non si va oltre il fondo della foto', () {
    expect(heroPhotoAlignmentY(const Size(5000, 200)), lessThanOrEqualTo(1));
  });
}
