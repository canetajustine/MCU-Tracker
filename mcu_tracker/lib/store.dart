import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted state: which entries are watched, and the chosen theme.
///
/// Everything lives on the device. There is no account and no sync.
class TrackerStore extends ChangeNotifier {
  TrackerStore(this._prefs)
      : _watched = _readWatched(_prefs),
        _themeMode = _readTheme(_prefs);

  static const String _kWatched = 'watched';
  static const String _kTheme = 'themeMode';

  final SharedPreferences _prefs;
  final Set<int> _watched;
  ThemeMode _themeMode;

  static Set<int> _readWatched(SharedPreferences prefs) {
    final List<String>? raw = prefs.getStringList(_kWatched);
    if (raw == null) return <int>{};
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  static ThemeMode _readTheme(SharedPreferences prefs) {
    return switch (prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  ThemeMode get themeMode => _themeMode;

  int get watchedCount => _watched.length;

  bool isWatched(int n) => _watched.contains(n);

  /// Number of watched entries whose id appears in [ids].
  int countWithin(Iterable<int> ids) =>
      ids.where(_watched.contains).length;

  Future<void> toggle(int n) async {
    if (!_watched.remove(n)) _watched.add(n);
    notifyListeners();
    await _saveWatched();
  }

  Future<void> clear() async {
    if (_watched.isEmpty) return;
    _watched.clear();
    notifyListeners();
    await _saveWatched();
  }

  Future<void> cycleTheme() async {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
    await _prefs.setString(_kTheme, _themeMode.name);
  }

  Future<void> _saveWatched() {
    final List<String> ids =
        (_watched.toList()..sort()).map((int n) => n.toString()).toList();
    return _prefs.setStringList(_kWatched, ids);
  }
}
