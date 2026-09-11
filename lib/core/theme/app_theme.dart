import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.successGold,
          surface: AppColors.surfaceLight,
        ).copyWith(
          onPrimary: AppColors.surfaceLight,
          onSecondary: AppColors.surfaceLight,
          onTertiary: AppColors.textOnLight,
          onSurface: AppColors.textOnLight,
        );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textOnLight,
        displayColor: AppColors.textOnLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceLight,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textOnLight,
          fontSize: 14,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: AppColors.surfaceLight,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0.6,
        surfaceTintColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.primary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnLight,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textOnLight,
          );
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: GoogleFonts.poppins(
          color: colorScheme.onPrimary,
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.successGold,
          surface: AppColors.backgroundDark,
        ).copyWith(
          onPrimary: AppColors.surfaceLight,
          onSecondary: AppColors.surfaceLight,
          onTertiary: AppColors.textOnLight,
          onSurface: AppColors.textOnDark,
        );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textOnDark,
        displayColor: AppColors.textOnDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceLight,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textOnLight,
          fontSize: 14,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: AppColors.surfaceLight,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0.6,
        surfaceTintColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.primary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark,
            );
          }
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textOnDark,
          );
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: GoogleFonts.poppins(
          color: colorScheme.onPrimary,
          fontSize: 14,
        ),
      ),
    );
  }
}
