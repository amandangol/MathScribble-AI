import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static List<String> get geminiApiKeys {
    final keysString = dotenv.env['GEMINI_API_KEYS'] ?? '';
    final keys = keysString.split(',').where((key) => key.isNotEmpty).toList();

    // print('Loading API keys:');
    // print('Raw keys string: $keysString');
    // print('Number of keys found: ${keys.length}');
    // print('Key lengths: ${keys.map((k) => k.length).toList()}');

    // Validate each key
    for (var key in keys) {
      if (key.length != 39 || !key.startsWith('AIzaSy')) {
        print('Warning: Key "$key" appears invalid - length: ${key.length}');
      }
    }

    return keys;
  }
}
