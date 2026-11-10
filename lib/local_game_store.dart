import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-local persistence for settings, resumable matches and match history.
class LocalGameStore {
  static const _savedMatchKey = 'ludo.saved_match.v1';
  static const _historyKey = 'ludo.match_history.v1';
  static const _soundKey = 'ludo.sound_enabled';
  static const _themeKey = 'ludo.theme';
  static const _languageKey = 'ludo.language';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  Future<void> saveMatch(Map<String, Object?> snapshot) async {
    final prefs = await _preferences;
    await prefs.setString(_savedMatchKey, jsonEncode(snapshot));
  }

  Future<Map<String, dynamic>?> loadMatch() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_savedMatchKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      await prefs.remove(_savedMatchKey);
    }
    return null;
  }

  Future<void> clearSavedMatch() async {
    final prefs = await _preferences;
    await prefs.remove(_savedMatchKey);
  }

  Future<void> recordCompletedMatch(Map<String, Object?> result) async {
    final prefs = await _preferences;
    final raw = prefs.getString(_historyKey);
    final history = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              history.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } on FormatException {
        history.clear();
      }
    }
    history.insert(0, <String, dynamic>{
      ...result,
      'completedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(
      _historyKey,
      jsonEncode(history.take(50).toList()),
    );
    await prefs.remove(_savedMatchKey);
  }

  Future<List<Map<String, dynamic>>> loadHistory() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_historyKey);
    if (raw == null) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } on FormatException {
      return <Map<String, dynamic>>[];
    }
    return <Map<String, dynamic>>[];
  }

  Future<bool> soundEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_soundKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_soundKey, enabled);
  }

  Future<String> themeName() async {
    final prefs = await _preferences;
    return prefs.getString(_themeKey) ?? 'emerald';
  }

  Future<void> setThemeName(String name) async {
    final prefs = await _preferences;
    await prefs.setString(_themeKey, name);
  }

  Future<String> languageCode() async {
    final prefs = await _preferences;
    return prefs.getString(_languageKey) ?? 'ar';
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await _preferences;
    await prefs.setString(_languageKey, code);
  }
}
