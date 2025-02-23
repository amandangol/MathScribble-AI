import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../services/api_key_manager.dart';
import '../../../utils/canvas_utils.dart';
import '../model/math_solution_model.dart';
import '../widgets/painters/drawing_painter.dart';
import 'abstract_math_service.dart';

class GeminiApiService extends AbstractMathService {
  late GenerativeModel model;
  late ApiKeyRotator _keyRotator;
  String? _currentApiKey;
  final List<String> apiKeys;

  GeminiApiService({required this.apiKeys});

  @override
  Future<void> initialize() async {
    try {
      if (apiKeys.isEmpty) {
        throw Exception('No Gemini API keys found');
      }

      _keyRotator = ApiKeyRotator(
        apiKeys: apiKeys,
        cooldownPeriod: const Duration(minutes: 1),
      );

      await _initializeWithNextKey();
      isInitialized = true;
    } catch (e) {
      print('Error initializing Gemini: $e');
      rethrow;
    }
  }

  Future<void> _initializeWithNextKey() async {
    _currentApiKey = _keyRotator.getNextAvailableKey();
    model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _currentApiKey!,
    );
  }

  Future<T> _executeWithKeyRotation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      if (e.toString().contains('quota exceeded') ||
          e.toString().contains('rate limit') ||
          e.toString().contains('429')) {
        if (_currentApiKey != null) {
          _keyRotator.markKeyAsError(_currentApiKey!);
        }
        await _initializeWithNextKey();
        return await operation();
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> recognizeExpression(
    BuildContext context,
    List<DrawingPoint?> points,
  ) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    return _executeWithKeyRotation(() async {
      final bytes = await CanvasUtils.getCanvasBytes(context, points);
      if (bytes == null) {
        throw Exception('Failed to get canvas image');
      }

      const prompt = """
    Analyze the handwritten mathematical expression in this image and provide a detailed breakdown with the following information:

    1. Raw Expression:
       - Capture the exact expression as written, preserving all symbols, superscripts, subscripts
       - Include any special notations like square roots, fractions, or powers
       - Maintain original spacing and grouping
       - Note any ambiguous or unclear characters

    2. Standardized Expression:
       - Convert to proper mathematical notation
       - Add appropriate spacing between operators and operands
       - Standardize division to use '/' instead of ÷
       - Use proper multiplication symbol '×' or '*'
       - Format exponents using '^' notation
       - Ensure proper parentheses grouping

    3. Classification:
       - Primary operation type (addition, multiplication, etc.)
       - Secondary operations if present
       - Presence of variables or constants
       - Mathematical domain (arithmetic, algebra, etc.)
       - Complexity level (basic, intermediate, complex)

    4. Components:
       - List all numbers detected
       - List all variables detected
       - List all mathematical operators
       - List any special symbols or notations
       - Note any subscripts or superscripts

    Please format the response as a JSON object with the following structure:
    {
      "original": "raw expression exactly as written",
      "standardized": "properly formatted expression",
      "type": {
        "primary": "main operation",
        "secondary": ["list", "of", "other", "operations"],
        "domain": "mathematical domain",
        "complexity": "complexity level"
      },
      "components": {
        "numbers": ["list", "of", "numbers"],
        "variables": ["list", "of", "variables"],
        "operators": ["list", "of", "operators"],
        "special": ["list", "of", "special", "notations"]
      }
    }
    """;

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', bytes),
        ])
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No expression recognized');
      }

      final jsonStr = response.text!.substring(
        response.text!.indexOf('{'),
        response.text!.lastIndexOf('}') + 1,
      );

      final Map<String, dynamic> parsed = json.decode(jsonStr);
      return {
        'original': _cleanExpression(parsed['original'] as String),
        'standardized': _cleanExpression(parsed['standardized'] as String),
        'type': json.encode(parsed['type']),
        'components': json.encode(parsed['components']),
      };
    });
  }

  @override
  Future<MathSolution> solveExpression(String mathExpression) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    return _executeWithKeyRotation(() async {
      const prompt = """
    Provide a JSON solution for the mathematical expression with:
    1. The final numerical answer
    2. Step-by-step solution
    3. Mathematical rules used
    
    Format: {
      "expression": "input",
      "result": "answer",
      "steps": ["step1", "step2"],
      "rules": ["rule1", "rule2"]
    }
    
    Expression: """;

      final response = await model.generateContent([
        Content.text(prompt + mathExpression),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No solution found');
      }

      final jsonStr = response.text!.substring(
        response.text!.indexOf('{'),
        response.text!.lastIndexOf('}') + 1,
      );

      return MathSolution.fromJson(json.decode(jsonStr));
    });
  }

  String _cleanExpression(String expression) {
    return expression
        .replaceAll(RegExp(r'\$|\\frac|{|}|\\'), '')
        .replaceAll('\n', ' ')
        .replaceAll('/', '/')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
