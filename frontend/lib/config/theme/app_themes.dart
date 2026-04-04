import 'package:flutter/material.dart';

ThemeData theme() => _buildTheme(brightness: Brightness.light);
ThemeData darkTheme() => _buildTheme(brightness: Brightness.dark);

ThemeData _buildTheme({required Brightness brightness}) {
  const seed = Color(0xFF9CA3AF);
  const accent = Color(0xFFE11D48);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(secondary: accent);

  final isDark = brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Muli',

    scaffoldBackgroundColor: isDark ? const Color(0xFF0B0B0C) : scheme.surface,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Muli',
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? const Color(0xFF141416)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: isDark
          ? const Color(0xFF101012).withValues(alpha: 0.92)
          : scheme.surface.withValues(alpha: 0.92),
      elevation: 0,
      indicatorColor: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.06),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? scheme.onSurface
              : scheme.onSurfaceVariant.withValues(alpha: 0.9),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 26,
          color: selected
              ? scheme.onSurface
              : scheme.onSurfaceVariant.withValues(alpha: 0.9),
        );
      }),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
  );
}
