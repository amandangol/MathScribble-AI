import '../../../config/env_config.dart';
import '../../dashboardscreen/model/recognition_model.dart';
import 'abstract_math_service.dart';
import 'gemini_api_service.dart';
import 'mixed_handwriting_service.dart';

class MathRecognitionFactory {
  static AbstractMathService createService(RecognitionModel model) {
    switch (model) {
      case RecognitionModel.handwriting:
        return MixedHandwritingService();
      case RecognitionModel.gemini:
        return GeminiApiService(apiKeys: EnvConfig.geminiApiKeys);

      default:
        throw Exception('Unsupported recognition model');
    }
  }
}
