import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:lookup_user/src/theme.dart';

/// Editor de foto de perfil: permite mover y hacer zoom (acercar o alejar)
/// dentro de un marco circular, y exporta el recorte como PNG.
class PhotoCropper extends StatefulWidget {
  const PhotoCropper({super.key, required this.imageBytes, this.size = 260});

  final Uint8List imageBytes;
  final double size;

  @override
  State<PhotoCropper> createState() => PhotoCropperState();
}

class PhotoCropperState extends State<PhotoCropper> {
  final GlobalKey _captureKey = GlobalKey();
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Renderiza el area del recorte a bytes PNG.
  Future<Uint8List?> exportPng() async {
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: RepaintBoundary(
              key: _captureKey,
              child: Container(
                color: c.surfaceAlt,
                child: InteractiveViewer(
                  transformationController: _controller,
                  // minScale < 1 permite el "zoom reverso" (alejar la imagen).
                  minScale: 0.3,
                  maxScale: 6,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                    width: widget.size,
                    height: widget.size,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '-',
              onPressed: () => _zoomBy(0.8),
              icon: Icon(Icons.zoom_out, color: c.inkMuted),
            ),
            IconButton(
              tooltip: '+',
              onPressed: () => _zoomBy(1.25),
              icon: Icon(Icons.zoom_in, color: c.inkMuted),
            ),
            IconButton(
              tooltip: 'Reset',
              onPressed: () => _controller.value = Matrix4.identity(),
              icon: Icon(Icons.center_focus_strong_outlined, color: c.inkMuted),
            ),
          ],
        ),
      ],
    );
  }

  void _zoomBy(double factor) {
    final center = widget.size / 2;
    final matrix = _controller.value.clone()
      ..translateByDouble(center, center, 0, 1)
      ..scaleByDouble(factor, factor, factor, 1)
      ..translateByDouble(-center, -center, 0, 1);
    _controller.value = matrix;
  }
}
