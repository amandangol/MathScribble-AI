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
    Analyze this handwritten mathematical expression image and provide:
    1. The exact mathematical expression as written using simple arithmetic notation
    2. A cleaned version with proper spacing and standard arithmetic operators
    3. The type of mathematical operation(s) involved
    
    Format as JSON with keys: "original", "standardized", "type"
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
        'type': parsed['type'] as String,
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
