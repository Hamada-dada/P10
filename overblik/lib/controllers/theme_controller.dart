import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppColorOption {
  green,
  blue,
  purple,
  orange,
  pink,
}

class ThemeController extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _colorKey = 'app_color';

  ThemeMode _themeMode = ThemeMode.light;
  AppColorOption _colorOption = AppColorOption.green;

  ThemeMode get themeMode => _themeMode;
  AppColorOption get colorOption => _colorOption;

  Color get seedColor {
    switch (_colorOption) {
      case AppColorOption.green:
        return const Color(0xFF6BBF73);
      case AppColorOption.blue:
        return const Color(0xFF5DADE2);
      case AppColorOption.purple:
        return const Color(0xFFB57EDC);
      case AppColorOption.orange:
        return const Color(0xFFFFB74D);
      case AppColorOption.pink:
        return const Color(0xFFF48FB1);
    }
  }

  Color get lightBackgroundColor {
    switch (_colorOption) {
      case AppColorOption.green:
        return const Color(0xFFA2E5AD);
      case AppColorOption.blue:
        return const Color(0xFFAEDCF7);
      case AppColorOption.purple:
        return const Color(0xFFDCC4F0);
      case AppColorOption.orange:
        return const Color(0xFFFFDCA8);
      case AppColorOption.pink:
        return const Color(0xFFF8C8D8);
    }
  }

  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme.copyWith(
        primary: seedColor,
        primaryContainer: lightBackgroundColor,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerHighest: const Color(0xFFF4F4F4),
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: Colors.white,
      dividerColor: Colors.black12,
    );
  }

  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme.copyWith(
        primary: seedColor,
        surface: const Color(0xFF101312),
        onSurface: Colors.white,
        primaryContainer: const Color(0xFF050706),
        surfaceContainerHighest: const Color(0xFF171A19),
      ),
      scaffoldBackgroundColor: const Color(0xFF050706),
      cardColor: const Color(0xFF101312),
      dividerColor: const Color(0xFF2A2D2C),
    );
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final savedThemeMode = prefs.getString(_themeModeKey);
    final savedColor = prefs.getString(_colorKey);

    _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedThemeMode,
      orElse: () => ThemeMode.light,
    );

    _colorOption = AppColorOption.values.firstWhere(
          (color) => color.name == savedColor,
      orElse: () => AppColorOption.green,
    );

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode.name);

    notifyListeners();
  }

  Future<void> setColorOption(AppColorOption colorOption) async {
    _colorOption = colorOption;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, colorOption.name);

    notifyListeners();
  }
}