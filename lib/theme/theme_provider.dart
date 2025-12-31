import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _defaultCurrency = 'EUR';

  ThemeMode get themeMode => _themeMode;
  String get defaultCurrency => _defaultCurrency;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setDefaultCurrency(String currency) {
    if (_defaultCurrency != currency) {
      _defaultCurrency = currency;
      notifyListeners();
    }
  }
}
