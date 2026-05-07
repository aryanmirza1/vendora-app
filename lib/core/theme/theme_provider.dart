import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isPurpleTheme = false;
  bool get isPurpleTheme => _isPurpleTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isPurpleTheme = prefs.getBool('isPurpleTheme') ?? false;
    notifyListeners();
  }

  Future<void> togglePurpleTheme(bool value) async {
    _isPurpleTheme = value;
    notifyListeners();   // 🔥 Refresh entire app UI
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPurpleTheme', value);
  }

  ThemeMode get themeMode => ThemeMode.light;
}
