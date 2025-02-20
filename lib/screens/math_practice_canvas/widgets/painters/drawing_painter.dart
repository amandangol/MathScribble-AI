import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;

  DrawingPoint({
    required this.point,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final Color color;
  final double strokeWidth;

  DrawingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
