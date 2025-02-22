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
    throw UnimplementedError(
      'HandwritingApiService does not implement solveExpression. '
      'Use GeminiApiService for solving expressions.',
    );
  }

  String _convertLatexToStandardized(String latex) {
    // Preprocessing for common edge cases
    latex = latex.replaceAll(' ', ''); // Remove all spaces first

    // Handle matrices
    latex = _handleMatrices(latex);

    // Handle power expressions with curly braces
    latex = _handlePowerExpressions(latex);

    // Handle integral expressions
    latex = _handleIntegralExpressions(latex);

    // Handle limit expressions
    latex = _handleLimits(latex);

    // Handle sequences and series
    latex = _handleSequencesAndSeries(latex);

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
        // Powers, roots, and absolute values
        .replaceAll(r'\sqrt{', 'sqrt(')
        .replaceAll(r'\sqrt[', 'root(')
        .replaceAll(r'\abs{', '|')
        .replaceAll(r'\right|', '|')
        // Trigonometric functions and their variations
        .replaceAll(r'\sin', 'sin')
        .replaceAll(r'\cos', 'cos')
        .replaceAll(r'\tan', 'tan')
        .replaceAll(r'\csc', 'csc')
        .replaceAll(r'\sec', 'sec')
        .replaceAll(r'\cot', 'cot')
        .replaceAll(r'\sinh', 'sinh')
        .replaceAll(r'\cosh', 'cosh')
        .replaceAll(r'\tanh', 'tanh')
        // Inverse trigonometric functions
        .replaceAll(r'\arcsin', 'arcsin')
        .replaceAll(r'\arccos', 'arccos')
        .replaceAll(r'\arctan', 'arctan')
        // Logarithms and exponentials
        .replaceAll(r'\log', 'log')
        .replaceAll(r'\ln', 'ln')
        .replaceAll(r'\exp', 'exp')
        // Greek letters and mathematical symbols
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\delta', 'δ')
        .replaceAll(r'\epsilon', 'ε')
        .replaceAll(r'\sum', 'Σ')
        .replaceAll(r'\prod', 'Π')
        // Special symbols and relations
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\mp', '∓')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\sim', '∼')
        .replaceAll(r'\in', '∈')
        .replaceAll(r'\notin', '∉')
        .replaceAll(r'\subset', '⊂')
        .replaceAll(r'\supset', '⊃')
        .replaceAll(r'\cup', '∪')
        .replaceAll(r'\cap', '∩')
        .replaceAll(r'\therefore', '∴')
        .replaceAll(r'\because', '∵')
        .trim();
  }

  String _handlePowerExpressions(String latex) {
    // Handle cases like {x=1}^{5}
    final powerRegExp = RegExp(r'\{([^{}]+)\}\^\{([^{}]+)\}');
    while (latex.contains(powerRegExp)) {
      latex = latex.replaceAllMapped(powerRegExp, (match) {
        final base = match.group(1) ?? '';
        final exponent = match.group(2) ?? '';
        return '($base)^($exponent)';
      });
    }
    return latex;
  }

  String _handleMatrices(String latex) {
    // Handle matrix expressions
    final matrixPattern = RegExp(r'\\begin\{([^}]*)\}(.*?)\\end\{\1\}');

    while (latex.contains(matrixPattern)) {
      latex = latex.replaceAllMapped(matrixPattern, (match) {
        final matrixType = match.group(1) ?? '';
        var content = match.group(2) ?? '';

        if (['matrix', 'pmatrix', 'bmatrix', 'vmatrix', 'Vmatrix']
            .contains(matrixType)) {
          // Convert matrix content
          content = content
              .replaceAll(r'\\', '') // Remove backslashes
              .replaceAll('&', ',') // Convert column separators to commas
              .replaceAll(r'\\', ';') // Convert row separators to semicolons
              .replaceAll(' ', ''); // Remove spaces

          switch (matrixType) {
            case 'pmatrix':
              return '($content)';
            case 'bmatrix':
              return '[$content]';
            case 'vmatrix':
              return '|$content|';
            case 'Vmatrix':
              return '‖$content‖';
            default:
              return '[$content]';
          }
        }
        return match.group(0) ?? '';
      });
    }
    return latex;
  }

  String _handleIntegralExpressions(String latex) {
    // Pattern to match integral expressions like \int_(lower)^(upper)
    final integralPattern = RegExp(r'\\int_\{([^}]*)\}\^\{([^}]*)\}');

    while (latex.contains(integralPattern)) {
      latex = latex.replaceAllMapped(integralPattern, (match) {
        final lowerBound = match.group(1) ?? '';
        final upperBound = match.group(2) ?? '';
        return '∫₍$lowerBound₎^($upperBound)'; // Using subscript notation for lower bound
      });
    }

    // Handle simple integrals without bounds
    latex = latex.replaceAll(r'\int', '∫');

    // Clean up dx notation
    latex = latex
        .replaceAll(r'\,dx', ' dx')
        .replaceAll(r'\, dx', ' dx')
        .replaceAll(r'\,d x', ' dx')
        .replaceAll(r'\, d x', ' dx');

    return latex;
  }

  String _handleLimits(String latex) {
    // Handle limit expressions like \lim_{x \to \infty}
    final limitPattern = RegExp(r'\\lim_\{([^}]*)\}');

    return latex.replaceAllMapped(limitPattern, (match) {
      final condition = match.group(1) ?? '';
      return 'lim($condition)';
    });
  }

  String _handleSequencesAndSeries(String latex) {
    // Handle arithmetic and geometric sequences
    latex = latex.replaceAll(r'\arithmetic', 'arith');
    latex = latex.replaceAll(r'\geometric', 'geom');

    // Handle summation with bounds
    final sumPattern = RegExp(r'\\sum_\{([^}]*)\}\^\{([^}]*)\}');
    while (latex.contains(sumPattern)) {
      latex = latex.replaceAllMapped(sumPattern, (match) {
        final lowerBound = match.group(1) ?? '';
        final upperBound = match.group(2) ?? '';
        return 'Σ[$lowerBound..$upperBound]';
      });
    }

    return latex;
  }

  String _determineExpressionType(String expression) {
    if (expression.contains('[') && expression.contains(';')) return 'Matrix';
    if (expression.contains('lim(')) return 'Limit';
    if (expression.contains('∫')) return 'Integral';
    if (_containsTrigFunction(expression)) return 'Trigonometric';
    if (_containsInverseTrigFunction(expression)) {
      return 'Inverse Trigonometric';
    }
    if (_containsHyperbolicFunction(expression)) return 'Hyperbolic';
    if (_containsLogarithm(expression)) return 'Logarithmic';
    if (expression.contains('∞')) return 'Infinite Expression';
    if (expression.contains('Σ')) return 'Series';
    if (expression.contains('Π')) return 'Product';
    if (expression.contains('arith')) return 'Arithmetic Sequence';
    if (expression.contains('geom')) return 'Geometric Sequence';
    if (_containsSetOperations(expression)) return 'Set Theory';
    if (expression.contains('+')) return 'Addition';
    if (expression.contains('-')) return 'Subtraction';
    if (expression.contains('*')) return 'Multiplication';
    if (expression.contains('/')) return 'Division';
    if (expression.contains('^')) return 'Exponentiation';
    if (expression.contains('sqrt') || expression.contains('root')) {
      return 'Root';
    }
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

  bool _containsHyperbolicFunction(String expression) {
    final hyperbolicFunctions = ['sinh', 'cosh', 'tanh'];
    return hyperbolicFunctions.any((func) => expression.contains(func));
  }

  bool _containsLogarithm(String expression) {
    return expression.contains('log') || expression.contains('ln');
  }

  bool _containsSetOperations(String expression) {
    final setOperations = ['∈', '∉', '⊂', '⊃', '∪', '∩'];
    return setOperations.any((op) => expression.contains(op));
  }
}
