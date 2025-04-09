import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final String _themePreferenceKey = 'theme_preference';
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterial3 = true;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;
  bool get useMaterial3 => _useMaterial3;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Check if we should use dark theme based on ThemeMode and system settings
  bool shouldUseDarkTheme(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Toggle between light and dark theme
  void toggleTheme() {
    _themeMode = (_themeMode == ThemeMode.light) 
      ? ThemeMode.dark 
      : ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }

  // Set a specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemePreference();
    notifyListeners();
  }

  // Toggle Material 3 usage
  void toggleMaterial3() {
    _useMaterial3 = !_useMaterial3;
    _saveThemePreference();
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(_themePreferenceKey);
    
    if (themeValue != null) {
      if (themeValue == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeValue == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }
    
    _useMaterial3 = prefs.getBool('use_material3') ?? true;
    
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    
    String themeValue;
    if (_themeMode == ThemeMode.light) {
      themeValue = 'light';
    } else if (_themeMode == ThemeMode.dark) {
      themeValue = 'dark';
    } else {
      themeValue = 'system';
    }
    
    await prefs.setString(_themePreferenceKey, themeValue);
    await prefs.setBool('use_material3', _useMaterial3);
  }
} 