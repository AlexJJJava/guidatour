// Decodifica delle foto profilo. Va eseguito anche nel browser, dove prima
// ogni foto risultava "non valida":
//   flutter test test/avatar_decode_test.dart
//   flutter test --platform chrome test/avatar_decode_test.dart
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/screens/avatar_crop_screen.dart';

/// PNG generato al volo con le dimensioni date.
Future<Uint8List> pngOf(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFF2C36B),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legge una foto JPG vera', () async {
    final jpg = (await rootBundle.load('assets/images/cat_visita.jpg'))
        .buffer
        .asUint8List();
    final image = await decodeAvatarSource(jpg);
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
    image.dispose();
  });

  test('una foto piccola resta com\'è', () async {
    final image = await decodeAvatarSource(await pngOf(640, 480));
    expect((image.width, image.height), (640, 480));
    image.dispose();
  });

  test('una foto molto grande si riduce mantenendo le proporzioni', () async {
    final image = await decodeAvatarSource(await pngOf(3000, 1500));
    expect((image.width, image.height), (2048, 1024));
    image.dispose();
  });

  test('un file che non è una foto viene rifiutato', () async {
    final notImage = Uint8List.fromList('ciao, non sono una foto'.codeUnits);
    await expectLater(decodeAvatarSource(notImage), throwsA(anything));
  });

  test('dimensioni di lettura', () {
    expect(avatarDecodeSize(800, 600).width, 800);
    expect(avatarDecodeSize(4000, 3000).width, 2048);
    expect(avatarDecodeSize(4000, 3000).height, isNull);
    expect(avatarDecodeSize(3000, 4000).height, 2048);
  });
}
