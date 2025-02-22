import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../screens/math_canvasscreen/widgets/painters/drawing_painter.dart';

class CanvasUtils {
  static Future<Uint8List?> getCanvasBytes(
    BuildContext context,
    List<DrawingPoint?> points,
  ) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = context.size ?? const Size(300, 300);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          canvas.drawLine(
            points[i]!.point,
            points[i + 1]!.point,
            Paint()
              ..color = points[i]!.color
              ..strokeWidth = points[i]!.strokeWidth
              ..strokeCap = StrokeCap.round,
          );
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error converting canvas to image: $e');
      return null;
    }
  }
}
