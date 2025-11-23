import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme { system, light, dark }

class ThemeManager with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.system;

  AppTheme get currentTheme => _currentTheme;

  ThemeManager() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(_themeKey) ?? '';

    if (themeValue.isNotEmpty) {
      _currentTheme = _parseTheme(themeValue);
    } else {
      _currentTheme = AppTheme.system;
    }

    notifyListeners();
  }

  AppTheme _parseTheme(String theme) {
    switch (theme) {
      case 'light':
        return AppTheme.light;
      case 'dark':
        return AppTheme.dark;
      default:
        return AppTheme.system;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.toString().split('.').last);
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
      default:
        return ThemeMode.system;
    }
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF2196F3),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ).copyWith(
            surfaceVariant: Colors.grey[200],
            onSurfaceVariant: Colors.grey[700],
          ),
      textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData.light().textTheme),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF2196F3),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ).copyWith(
            surfaceVariant: const Color(0xFF2E2E2E),
            onSurfaceVariant: Colors.grey[300],
          ),
      textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData.dark().textTheme),
    );
  }
}
