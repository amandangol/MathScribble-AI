import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/math_history_model.dart';

class HistoryPersistenceService {
  static const String _historyKey = 'math_history';
  static const int _maxHistoryItems = 20;

  Future<void> saveHistory(List<MathHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    // Sort by latest first and limit to 20 items
    final sortedHistory = history
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
      ..take(_maxHistoryItems);

    final historyJson = sortedHistory.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }

  Future<List<MathHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey);
    if (historyString == null) return [];

    try {
      final historyJson = jsonDecode(historyString) as List;
      return historyJson
          .map((item) => MathHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
