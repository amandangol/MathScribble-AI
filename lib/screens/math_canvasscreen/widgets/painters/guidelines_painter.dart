import 'package:flutter/material.dart';

class GuidelinesPainter extends CustomPainter {
  final String gridType;
  final bool isDarkMode;

  GuidelinesPainter({
    this.gridType = 'none',
    this.isDarkMode = false,
    required Color primaryColor,
    required Color secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gridType == 'none') return;

    final Paint paint = Paint()
      ..color = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!
      ..strokeWidth = 0.5;

    if (gridType == 'square') {
      _drawSquareGrid(canvas, size, paint);
    } else if (gridType == 'coordinate') {
      _drawCoordinateGrid(canvas, size, paint);
    } else if (gridType == 'isometric') {
      _drawIsometricGrid(canvas, size, paint);
    }
  }

  void _drawSquareGrid(Canvas canvas, Size size, Paint paint) {
    // Draw vertical lines
    for (double i = 0; i <= size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  void _drawCoordinateGrid(Canvas canvas, Size size, Paint paint) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Draw axis with thicker lines
    final Paint axisPaint = Paint()
      ..color = isDarkMode ? Colors.grey[500]! : Colors.grey[700]!
      ..strokeWidth = 1.5;

    // X-axis
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      axisPaint,
    );

    // Y-axis
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      axisPaint,
    );

    // Draw grid lines
    for (double i = centerX % 20; i <= size.width; i += 20) {
      if (i != centerX) {
        // Skip center as it's already drawn
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      }
    }

    for (double i = centerY % 20; i <= size.height; i += 20) {
      if (i != centerY) {
        // Skip center as it's already drawn
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    }
  }

  void _drawIsometricGrid(Canvas canvas, Size size, Paint paint) {
    const double spacing = 30.0;

    // Draw three sets of parallel lines
    for (double i = -2 * size.height; i <= 2 * size.width; i += spacing) {
      // First set (horizontal)
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );

      // Second set (30° from horizontal)
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height / 0.577, size.height), // tan(30°) = 0.577
        paint,
      );

      // Third set (150° from horizontal or -30° from horizontal)
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height / 0.577, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GuidelinesPainter oldDelegate) {
    return oldDelegate.gridType != gridType ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
