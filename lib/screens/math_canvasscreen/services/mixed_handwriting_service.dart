import 'package:flutter/material.dart';
import '../../../config/env_config.dart';
import '../model/math_solution_model.dart';
import '../widgets/painters/drawing_painter.dart';
import 'abstract_math_service.dart';
import 'handwriting_api_service.dart';
import 'gemini_api_service.dart';

class MixedHandwritingService extends AbstractMathService {
  late HandwritingApiService _handwritingService;
  late GeminiApiService _geminiService;

  @override
  Future<void> initialize() async {
    try {
      // Initialize Handwriting API for recognition
      _handwritingService = HandwritingApiService(
        apiToken: EnvConfig.handwritingApiToken,
      );
      await _handwritingService.initialize();

      // Initialize Gemini for solving
      _geminiService = GeminiApiService(
        apiKeys: EnvConfig.geminiApiKeys,
      );
      await _geminiService.initialize();

      isInitialized = true;
    } catch (e) {
      print('Error initializing mixed services: $e');
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
    // Use handwriting API for recognition
    return await _handwritingService.recognizeExpression(context, points);
  }

  @override
  Future<MathSolution> solveExpression(String mathExpression) async {
    if (!isInitialized) {
      throw Exception('Service not initialized');
    }
    // Use Gemini for solving
    return await _geminiService.solveExpression(mathExpression);
  }
}
