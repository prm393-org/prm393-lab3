import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Light/dark theme — Academic Insight Logic.
class AppTheme {
  AppTheme._();

  static const _radius = 12.0;

  static ThemeData get lightTheme => _buildTheme(
        const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.surfaceMuted,
          onPrimaryContainer: AppColors.primary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.white,
          secondaryContainer: AppColors.surfaceMuted,
          onSecondaryContainer: AppColors.primary,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: AppColors.surfaceSubtle,
          surfaceContainerHighest: AppColors.surfaceSubtle,
          error: AppColors.error,
          onError: AppColors.white,
        ),
      );

  static ThemeData get darkTheme => _buildTheme(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.darkPrimaryAccent,
          onPrimary: AppColors.darkBackground,
          primaryContainer: AppColors.darkSurfaceMuted,
          onPrimaryContainer: AppColors.darkOnSurface,
          secondary: AppColors.secondary,
          onSecondary: AppColors.white,
          secondaryContainer: Color(0xFF312E81),
          onSecondaryContainer: Color(0xFFC7D2FE),
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.darkBackground,
          surface: AppColors.darkSurfaceElevated,
          onSurface: AppColors.darkOnSurface,
          onSurfaceVariant: Color(0xFF94A3B8),
          outline: AppColors.darkBorder,
          outlineVariant: Color(0xFF1E293B),
          surfaceContainerHighest: AppColors.darkSurfaceMuted,
          error: AppColors.error,
          onError: AppColors.white,
        ),
        scaffoldColor: AppColors.darkBackground,
        cardColor: AppColors.darkSurfaceElevated,
        navBarColor: AppColors.darkSurfaceElevated,
        inputFillColor: AppColors.darkSurfaceMuted,
      );

  static ThemeData _buildTheme(
    ColorScheme scheme, {
    Color? scaffoldColor,
    Color? cardColor,
    Color? navBarColor,
    Color? inputFillColor,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final scaffold = scaffoldColor ??
        (isDark ? AppColors.darkBackground : AppColors.surface);
    final card = cardColor ?? (isDark ? AppColors.darkSurfaceElevated : AppColors.white);
    final navBar = navBarColor ?? (isDark ? AppColors.darkSurfaceElevated : AppColors.white);
    final inputFill =
        inputFillColor ?? (isDark ? AppColors.darkSurfaceMuted : AppColors.white);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 56,
        backgroundColor: navBar,
        indicatorColor: isDark ? AppColors.secondary : AppColors.primary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? (isDark ? AppColors.darkOnSurface : AppColors.primary)
                : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.white : scheme.onSurfaceVariant,
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
        selectedColor: isDark ? AppColors.secondary : AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkOnSurface : AppColors.primary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        showCheckmark: false,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.white;
            }
            return scheme.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? AppColors.secondary : AppColors.primary;
            }
            return isDark
                ? AppColors.darkSurfaceMuted
                : AppColors.surfaceMuted;
          }),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: scheme.onSurfaceVariant,
          height: 1.45,
        ),
        bodySmall: TextStyle(color: scheme.onSurfaceVariant),
        labelSmall: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          fontSize: 11,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.secondary : AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: card,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: scheme.onSurface),
      ),
    );
  }

  /// Status bar icon màu phù hợp sáng/tối.
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) =>
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            );
}
