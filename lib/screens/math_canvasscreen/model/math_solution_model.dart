class MathSolution {
  final String expression;
  final String result;
  final List<String> steps;
  final List<String> rules;

  MathSolution({
    required this.expression,
    required this.result,
    required this.steps,
    required this.rules,
  });

  factory MathSolution.fromJson(Map<String, dynamic> json) {
    return MathSolution(
      expression: json['expression'] ?? '',
      result: json['result'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      rules: List<String>.from(json['rules'] ?? []),
    );
  }
}

// Add a new class for recognition result
class RecognitionResult {
  final String original;
  final String standardized;
  final String type;

  RecognitionResult({
    required this.original,
    required this.standardized,
    required this.type,
  });

  factory RecognitionResult.fromMap(Map<String, String> map) {
    return RecognitionResult(
      original: map['original'] ?? '',
      standardized: map['standardized'] ?? '',
      type: map['type'] ?? '',
    );
  }
}
