import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../config/env_config.dart';
import '../../../services/api_key_manager.dart';
import '../model/math_solution_model.dart';
import '../widgets/painters/drawing_painter.dart';

class MathRecognitionService {
  late GenerativeModel model;
  bool isInitialized = false;
  late ApiKeyRotator _keyRotator;
  String? _currentApiKey;

  Future<void> initialize() async {
    try {
      final apiKeys = EnvConfig.geminiApiKeys;
      if (apiKeys.isEmpty) {
        throw Exception('No Gemini API keys found in environment');
      }

      print('Initializing MathRecognitionService with ${apiKeys.length} keys');

      _keyRotator = ApiKeyRotator(
        apiKeys: apiKeys,
        cooldownPeriod: const Duration(minutes: 1),
      );

      // Initialize with the first available key
      await _initializeWithNextKey();
      isInitialized = true;
      print('MathRecognitionService initialized successfully');
    } catch (e) {
      print('Error initializing Gemini: $e');
      rethrow;
    }
  }

  Future<void> _initializeWithNextKey() async {
    _currentApiKey = _keyRotator.getNextAvailableKey();
    print(
        'Initializing model with key: ${_currentApiKey!.substring(0, 10)}...');
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
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
        // Mark current key as having an error
        if (_currentApiKey != null) {
          _keyRotator.markKeyAsError(_currentApiKey!);
        }

        // Try with next key
        await _initializeWithNextKey();
        return await operation();
      }
      rethrow;
    }
  }

  Future<Map<String, String>> recognizeExpression(
    BuildContext context,
    List<DrawingPoint?> points,
  ) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    return _executeWithKeyRotation(() async {
      final bytes = await _getCanvasBytes(context, points);
      if (bytes == null) {
        throw Exception('Failed to get canvas image');
      }

      const prompt = """
    Analyze this handwritten mathematical expression image and provide:
    1. The exact mathematical expression as written using simple arithmetic notation (e.g., 1+2/3, not LaTeX)
    2. A cleaned version with proper spacing and standard arithmetic operators (+, -, *, /, ^)
    3. The type of mathematical operation(s) involved (e.g., addition, division, etc.)
    
    Important: Do NOT use LaTeX notation. Use simple arithmetic notation only.
    - Use / for division (not fractions)
    - Use standard operators: +, -, *, /, ^
    - Preserve the exact way numbers are written (e.g., if it's "5+9/6", don't convert to fractions)
    
    Format the response as JSON with keys:
    {
      "original": "raw expression exactly as written",
      "standardized": "cleaned expression with proper spacing",
      "type": "operation type"
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

      try {
        // Extract the JSON string from the response
        final jsonStr = response.text!.substring(
          response.text!.indexOf('{'),
          response.text!.lastIndexOf('}') + 1,
        );

        final Map<String, dynamic> parsed = json.decode(jsonStr);

        // Clean up any remaining LaTeX or special formatting
        final original = _cleanExpression(parsed['original'] as String);
        final standardized = _cleanExpression(parsed['standardized'] as String);

        return {
          "original": original,
          "standardized": standardized,
          "type": parsed['type'] as String,
        };
      } catch (e) {
        print('Error parsing recognition response: $e');
        throw Exception('Failed to parse recognition result');
      }
    });
  }

  String _cleanExpression(String expression) {
    return expression
        .replaceAll(RegExp(r'\$|\\frac|{|}|\\'), '') // Remove LaTeX symbols
        .replaceAll('\n', ' ')
        .replaceAll('/', '/')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<MathSolution> solveExpression(String mathExpression) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }

    return _executeWithKeyRotation(() async {
      const prompt = """
    For the mathematical expression, provide:
    1. The final numerical answer
    2. A step-by-step solution explaining each step
    3. Any relevant mathematical rules or properties used
    
    IMPORTANT: Respond ONLY with a JSON object in the following format:
    {
      "expression": "input expression",
      "result": "final answer",
      "steps": ["step 1", "step 2", "step 3"],
      "rules": ["rule 1", "rule 2"]
    }
    
    Expression: """;

      final response = await model.generateContent([
        Content.text(prompt + mathExpression),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No solution found');
      }

      try {
        //parse the entire response first
        try {
          return MathSolution.fromJson(json.decode(response.text!));
        } catch (_) {
          // if that fails, try to extract JSON with more robust parsing
        }

        // Look for JSON-like structure with regex
        final jsonMatch = RegExp(r'{[\s\S]*}').firstMatch(response.text!);
        if (jsonMatch == null) {
          throw Exception('No valid JSON found in response');
        }

        final jsonStr = jsonMatch.group(0);
        if (jsonStr == null) {
          throw Exception('Failed to extract JSON from response');
        }

        final Map<String, dynamic> resultMap = json.decode(jsonStr);
        return MathSolution.fromJson(resultMap);
      } catch (e) {
        print('Error parsing solution response: $e');
        print('Raw response: ${response.text}');
        throw Exception('Failed to parse solution result: $e');
      }
    });
  }

  Future<Uint8List?> _getCanvasBytes(
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
