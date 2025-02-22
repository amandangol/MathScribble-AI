import '../../dashboardscreen/model/recognition_model.dart';

class MathHistoryItem {
  final String expression;
  final String? solution;
  final List<String>? steps;
  final List<String>? rules;
  final DateTime timestamp;
  final RecognitionModel recognitionModel;

  MathHistoryItem({
    required this.expression,
    this.solution,
    this.steps,
    this.rules,
    required this.timestamp,
    required this.recognitionModel,
  });

  // Update toJson to store enum value
  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'solution': solution,
      'steps': steps,
      'rules': rules,
      'timestamp': timestamp.toIso8601String(),
      'recognitionModel': recognitionModel.name, // Store enum name
    };
  }

  // Update fromJson to handle enum
  factory MathHistoryItem.fromJson(Map<String, dynamic> json) {
    return MathHistoryItem(
      expression: json['expression'],
      solution: json['solution'],
      steps: json['steps']?.cast<String>(),
      rules: json['rules']?.cast<String>(),
      timestamp: DateTime.parse(json['timestamp']),
      recognitionModel: RecognitionModel.values.firstWhere(
        (model) => model.name == json['recognitionModel'],
        orElse: () => RecognitionModel
            .values.first, // Fallback to first model if not found
      ),
    );
  }
}
