import 'package:flutter/material.dart';
import '../model/math_solution_model.dart';
import '../widgets/painters/drawing_painter.dart';

abstract class AbstractMathService {
  bool isInitialized = false;

  Future<void> initialize();

  Future<Map<String, String>> recognizeExpression(
    BuildContext context,
    List<DrawingPoint?> points,
  );

  Future<MathSolution> solveExpression(String mathExpression);
}
