import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  final AppThemeMode mode;
  final String fontFamily;

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    return _buildLightTheme(lightColorScheme);
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    return _buildDarkTheme(darkColorScheme, true);
  }

  ThemeData _buildDarkTheme(ColorScheme? colorScheme, bool isDarkMode) {
    final ColorScheme scheme = colorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9FF),
          brightness: Brightness.dark,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        brightness: Brightness.dark,
        primary: const Color(0xFF00C9FF),
        secondary: const Color(0xFF0099E8),
        surface: const Color(0xFF1A2837),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: (isDarkMode && mode.trueBlack) ? Colors.black : const Color(0xFF0F1C2A),
      appBarTheme: AppBarTheme(
        backgroundColor: (isDarkMode && mode.trueBlack) ? Colors.black : const Color(0xFF0F1C2A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: (isDarkMode && mode.trueBlack) ? Colors.black : const Color(0xFF0B1621),
        selectedIconTheme: const IconThemeData(color: Color(0xFF00C9FF)),
        unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.6)),
        selectedLabelTextStyle: const TextStyle(color: Color(0xFF00C9FF), fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: (isDarkMode && mode.trueBlack) ? Colors.black : const Color(0xFF152535),
        indicatorColor: const Color(0xFF00C9FF).withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF00C9FF));
          }
          return IconThemeData(color: Colors.white.withOpacity(0.6));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: Color(0xFF00C9FF), fontWeight: FontWeight.w600);
          }
          return TextStyle(color: Colors.white.withOpacity(0.6));
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: (isDarkMode && mode.trueBlack) ? Colors.black : const Color(0xFF0B1621),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
      ),
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light,
      },
    );
  }

  ThemeData _buildLightTheme(ColorScheme? colorScheme) {
    final ColorScheme scheme = colorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9FF),
          brightness: Brightness.light,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        brightness: Brightness.light,
        primary: const Color(0xFF00A8E8),
        secondary: const Color(0xFF0099E8),
        surface: Colors.white,
        onSurface: Colors.black87,
        surfaceContainerHighest: const Color(0xFFF5F5F5),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: Color(0xFF00A8E8)),
        unselectedIconTheme: IconThemeData(color: Colors.black.withOpacity(0.6)),
        selectedLabelTextStyle: const TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF00A8E8).withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF00A8E8));
          }
          return IconThemeData(color: Colors.black.withOpacity(0.6));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.w600);
          }
          return TextStyle(color: Colors.black.withOpacity(0.6));
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
        titleLarge: TextStyle(color: Colors.black87),
        titleMedium: TextStyle(color: Colors.black87),
        titleSmall: TextStyle(color: Colors.black87),
        headlineSmall: TextStyle(color: Colors.black87),
        headlineMedium: TextStyle(color: Colors.black87),
        headlineLarge: TextStyle(color: Colors.black87),
      ),
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light,
      },
    );
  }
}
