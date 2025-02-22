import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../model/math_solution_model.dart';
import '../widgets/painters/drawing_painter.dart';
import 'abstract_math_service.dart';

class HandwritingApiService extends AbstractMathService {
  final String baseUrl = 'https://mathhandwrit.ing/api';
  final String apiToken;

  HandwritingApiService({required this.apiToken});

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<Map<String, String>> recognizeExpression(
    BuildContext context,
    List<DrawingPoint?> points,
  ) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      final List<List<Map<String, double>>> paths = [];
      List<Map<String, double>> currentPath = [];

      for (var point in points) {
        if (point == null) {
          if (currentPath.isNotEmpty) {
            paths.add(currentPath);
            currentPath = [];
          }
        } else {
          currentPath.add({
            'x': point.point.dx,
            'y': point.point.dy,
          });
        }
      }

      if (currentPath.isNotEmpty) {
        paths.add(currentPath);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/detect-with-api'),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paths': paths,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to recognize expression: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final latex = data['latex'] ?? '';
      final standardized = _convertLatexToStandardized(latex);

      return {
        'original': latex,
        'standardized': standardized,
        'type': _determineExpressionType(standardized),
      };
    } catch (e) {
      throw Exception('Error in handwriting recognition: $e');
    }
  }

  @override
  Future<MathSolution> solveExpression(String mathExpression) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/solve-expression'),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'expression': mathExpression,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to solve expression: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);
      return MathSolution.fromJson(data);
    } catch (e) {
      throw Exception('Error solving expression: $e');
    }
  }

  String _determineExpressionType(String expression) {
    if (expression.contains('+')) return 'Addition';
    if (expression.contains('-')) return 'Subtraction';
    if (expression.contains('*')) return 'Multiplication';
    if (expression.contains('/')) return 'Division';
    if (expression.contains('^')) return 'Exponentiation';
    if (expression.contains('sqrt')) return 'Square Root';
    return 'Expression';
  }

  String _convertLatexToStandardized(String latex) {
    return latex
        .replaceAll(r'\frac{', '(')
        .replaceAll('}{', ')/(')
        .replaceAll('}', ')')
        .replaceAll(r'\cdot', '*')
        .replaceAll(r'\times', '*')
        .replaceAll(r'\div', '/')
        .replaceAll(r'\sqrt{', 'sqrt(')
        .replaceAll(r'\left(', '(')
        .replaceAll(r'\right)', ')');
  }
}
