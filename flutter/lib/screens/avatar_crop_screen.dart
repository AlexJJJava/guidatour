import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../widgets.dart';

/// Lato della foto salvata: basta per il pallino e pesa poco.
const avatarSize = 400;

/// Lato massimo in memoria durante il ritaglio, per le foto molto grandi.
const _maxDecodedSide = 2048;

/// Trasformazione iniziale: l'immagine riempie il riquadro, centrata.
Matrix4 coverTransform(Size image, double side) {
  final scale = side / math.min(image.width, image.height);
  return Matrix4.diagonal3Values(scale, scale, scale)
    ..setTranslationRaw((side - image.width * scale) / 2,
        (side - image.height * scale) / 2, 0);
}

/// Parte dell'immagine visibile nel riquadro con questa trasformazione.
Rect visibleRect(Matrix4 transform, double side) {
  final scale = transform.getMaxScaleOnAxis();
  final t = transform.getTranslation();
  return Rect.fromLTWH(-t.x / scale, -t.y / scale, side / scale, side / scale);
}

/// Sceglie la parte di foto da tenere; restituisce il PNG ritagliato.
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _transform = TransformationController();
  ui.Image? _image;
  double _side = 0;
  bool _failed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _transform.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(widget.bytes);
      final info = await ui.ImageDescriptor.encoded(buffer);
      final wide = info.width >= info.height;
      final tooBig = math.max(info.width, info.height) > _maxDecodedSide;
      final codec = await info.instantiateCodec(
        targetWidth: tooBig && wide ? _maxDecodedSide : null,
        targetHeight: tooBig && !wide ? _maxDecodedSide : null,
      );
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  double get _minScale =>
      _side / math.min(_image!.width, _image!.height).toDouble();

  /// Zoom dal cursore, attorno al centro del riquadro.
  void _zoomTo(double scale) {
    final current = visibleRect(_transform.value, _side);
    final center = current.center;
    final image = _image!;
    final size = _side / scale;
    final left = (center.dx - size / 2).clamp(0.0, image.width - size);
    final top = (center.dy - size / 2).clamp(0.0, image.height - size);
    _transform.value = Matrix4.diagonal3Values(scale, scale, scale)
      ..setTranslationRaw(-left * scale, -top * scale, 0);
  }

  Future<void> _confirm() async {
    final image = _image!;
    setState(() => _saving = true);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      visibleRect(_transform.value, _side),
      Rect.fromLTWH(0, 0, avatarSize.toDouble(), avatarSize.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final cropped = await recorder.endRecording().toImage(avatarSize, avatarSize);
    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    cropped.dispose();
    if (!mounted) return;
    Navigator.of(context).pop(data!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final image = _image;
    return Scaffold(
      appBar: AppBar(title: Text(t.avatarCropTitle)),
      body: _failed
          ? Center(child: Text(t.avatarInvalid))
          : image == null
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : PageBody(
                  maxWidth: 420,
                  child: LayoutBuilder(builder: (context, c) {
                    final side = math.min(c.maxWidth, 360.0);
                    if (side != _side) {
                      _side = side;
                      _transform.value = coverTransform(
                          Size(image.width.toDouble(), image.height.toDouble()),
                          side);
                    }
                    return Column(
                      children: [
                        Text(t.avatarCropHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kMuted)),
                        const SizedBox(height: 16),
                        SizedBox.square(
                          dimension: side,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                InteractiveViewer(
                                  transformationController: _transform,
                                  constrained: false,
                                  minScale: _minScale,
                                  maxScale: _minScale * 5,
                                  child: RawImage(image: image),
                                ),
                                const IgnorePointer(
                                  child: CustomPaint(painter: _CircleMask()),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: _transform,
                          builder: (context, _) => Row(
                            children: [
                              const Icon(Icons.photo_size_select_small,
                                  color: kMuted),
                              Expanded(
                                child: Slider(
                                  min: _minScale,
                                  max: _minScale * 5,
                                  value: _transform.value
                                      .getMaxScaleOnAxis()
                                      .clamp(_minScale, _minScale * 5),
                                  onChanged: _zoomTo,
                                ),
                              ),
                              const Icon(Icons.photo_size_select_large,
                                  color: kMuted),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _confirm,
                            child: Text(t.avatarUsePhoto),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
    );
  }
}

/// Scurisce gli angoli: nel pallino si vedrà solo il cerchio.
class _CircleMask extends CustomPainter {
  const _CircleMask();

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(area),
        Path()..addOval(area),
      ),
      Paint()..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(_CircleMask oldDelegate) => false;
}
