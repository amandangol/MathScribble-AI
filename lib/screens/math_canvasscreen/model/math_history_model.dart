// math_history_model.dart
class MathHistoryItem {
  final String expression;
  final String? solution;
  final List<String>? steps;
  final List<String>? rules;
  final DateTime timestamp;

  MathHistoryItem({
    required this.expression,
    this.solution,
    this.steps,
    this.rules,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'solution': solution,
      'steps': steps,
      'rules': rules,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MathHistoryItem.fromJson(Map<String, dynamic> json) {
    return MathHistoryItem(
      expression: json['expression'] as String,
      solution: json['solution'] as String?,
      steps: json['steps'] != null ? List<String>.from(json['steps']) : null,
      rules: json['rules'] != null ? List<String>.from(json['rules']) : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
