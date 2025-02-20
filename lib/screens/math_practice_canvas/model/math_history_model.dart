class MathHistoryItem {
  final String expression;
  final String? solution;
  final DateTime timestamp;

  MathHistoryItem({
    required this.expression,
    this.solution,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'solution': solution,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MathHistoryItem.fromJson(Map<String, dynamic> json) =>
      MathHistoryItem(
        expression: json['expression'],
        solution: json['solution'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}
