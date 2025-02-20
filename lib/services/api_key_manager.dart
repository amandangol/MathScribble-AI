class ApiKeyRotator {
  final List<String> _apiKeys;
  int _currentKeyIndex = 0;
  final Map<String, DateTime> _lastUsedTime = {};
  final Duration _cooldownPeriod;

  ApiKeyRotator({
    required List<String> apiKeys,
    Duration? cooldownPeriod,
  })  : _apiKeys = apiKeys,
        _cooldownPeriod = cooldownPeriod ?? const Duration(minutes: 1) {
    if (_apiKeys.isEmpty) {
      throw Exception('No API keys provided');
    }

    // Initialize last used time for all keys
    for (final key in _apiKeys) {
      _lastUsedTime[key] = DateTime.now().subtract(const Duration(days: 1));
    }
  }

  String getNextAvailableKey() {
    if (_apiKeys.isEmpty) {
      throw Exception('No API keys available');
    }

    final now = DateTime.now();
    String? selectedKey;

    // Try to find a key that has cooled down
    for (int i = 0; i < _apiKeys.length; i++) {
      final keyIndex = (_currentKeyIndex + i) % _apiKeys.length;
      final key = _apiKeys[keyIndex];
      final lastUsed =
          _lastUsedTime[key] ?? now.subtract(const Duration(days: 1));

      if (now.difference(lastUsed) >= _cooldownPeriod) {
        selectedKey = key;
        _currentKeyIndex = keyIndex;
        break;
      }
    }

    // If no key has cooled down, use the least recently used key
    if (selectedKey == null) {
      final leastRecentlyUsedKey = _lastUsedTime.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      selectedKey = leastRecentlyUsedKey;
      _currentKeyIndex = _apiKeys.indexOf(leastRecentlyUsedKey);
    }

    _lastUsedTime[selectedKey] = now;
    return selectedKey;
  }

  void markKeyAsError(String key) {
    // Mark the key as having an error by setting its last used time
    // to now plus the cooldown period
    _lastUsedTime[key] = DateTime.now().add(_cooldownPeriod);
  }
}
