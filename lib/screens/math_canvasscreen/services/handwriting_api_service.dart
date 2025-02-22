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

  String _convertLatexToStandardized(String latex) {
    return latex
        // Basic operations
        .replaceAll(r'\frac{', '(')
        .replaceAll('}{', ')/(')
        .replaceAll('}', ')')
        .replaceAll(r'\cdot', '*')
        .replaceAll(r'\times', '*')
        .replaceAll(r'\div', '/')
        // Parentheses and brackets
        .replaceAll(r'\left(', '(')
        .replaceAll(r'\right)', ')')
        .replaceAll(r'\left[', '[')
        .replaceAll(r'\right]', ']')
        .replaceAll(r'\left\{', '{')
        .replaceAll(r'\right\}', '}')
        // Powers and roots
        .replaceAll(r'\sqrt{', 'sqrt(')
        .replaceAll(r'\^{', '^(')
        // Trigonometric functions
        .replaceAll(r'\sin', 'sin')
        .replaceAll(r'\cos', 'cos')
        .replaceAll(r'\tan', 'tan')
        .replaceAll(r'\csc', 'csc')
        .replaceAll(r'\sec', 'sec')
        .replaceAll(r'\cot', 'cot')
        // Inverse trigonometric functions
        .replaceAll(r'\arcsin', 'arcsin')
        .replaceAll(r'\arccos', 'arccos')
        .replaceAll(r'\arctan', 'arctan')
        // Logarithms
        .replaceAll(r'\log', 'log')
        .replaceAll(r'\ln', 'ln')
        // Other functions
        .replaceAll(r'\exp', 'exp')
        // Greek letters commonly used in math
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\sum', 'Σ')
        // Special symbols
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\approx', '≈');
  }

  String _determineExpressionType(String expression) {
    // Check for complex expressions first
    if (_containsTrigFunction(expression)) return 'Trigonometric';
    if (_containsInverseTrigFunction(expression)) {
      return 'Inverse Trigonometric';
    }
    if (_containsLogarithm(expression)) return 'Logarithmic';

    // Then check for basic operations
    if (expression.contains('∞')) return 'Infinite Expression';
    if (expression.contains('Σ')) return 'Summation';
    if (expression.contains('+')) return 'Addition';
    if (expression.contains('-')) return 'Subtraction';
    if (expression.contains('*')) return 'Multiplication';
    if (expression.contains('/')) return 'Division';
    if (expression.contains('^')) return 'Exponentiation';
    if (expression.contains('sqrt')) return 'Square Root';
    if (expression.contains('=')) return 'Equation';
    if (expression.contains('≤') || expression.contains('≥')) {
      return 'Inequality';
    }

    return 'Expression';
  }

  bool _containsTrigFunction(String expression) {
    final trigFunctions = ['sin', 'cos', 'tan', 'csc', 'sec', 'cot'];
    return trigFunctions.any((func) => expression.contains(func));
  }

  bool _containsInverseTrigFunction(String expression) {
    final inverseTrigFunctions = ['arcsin', 'arccos', 'arctan'];
    return inverseTrigFunctions.any((func) => expression.contains(func));
  }

  bool _containsLogarithm(String expression) {
    return expression.contains('log') || expression.contains('ln');
  }
}
