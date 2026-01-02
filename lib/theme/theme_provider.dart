import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _defaultCurrency = 'EUR';
  int? _defaultAccountId;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  String get defaultCurrency => _defaultCurrency;
  int? get defaultAccountId => _defaultAccountId;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[_prefs?.getInt('themeMode') ?? 0];
    _defaultCurrency = _prefs?.getString('defaultCurrency') ?? 'EUR';
    _defaultAccountId = _prefs?.getInt('defaultAccountId');
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _prefs?.setInt('themeMode', _themeMode.index);
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setInt('themeMode', mode.index);
    notifyListeners();
  }

  void setDefaultCurrency(String currency) {
    if (_defaultCurrency != currency) {
      _defaultCurrency = currency;
      _prefs?.setString('defaultCurrency', currency);
      notifyListeners();
    }
  }

  void setDefaultAccount(int? accountId) {
    if (_defaultAccountId != accountId) {
      _defaultAccountId = accountId;
      if (accountId == null) {
        _prefs?.remove('defaultAccountId');
      } else {
        _prefs?.setInt('defaultAccountId', accountId);
      }
      notifyListeners();
    }
  }
}
