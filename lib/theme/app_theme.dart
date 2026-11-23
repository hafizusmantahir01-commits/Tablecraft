import 'package:flutter/material.dart';

/// The app is phone-shaped. On wide screens (web, tablets) it is kept this wide and centred.
const double kMaxAppWidth = 520;

/// All colors of the app in one place, so the look stays consistent.
class AppColors {
  static const ink = Color(0xFF3B2A1A); // main text, dark brown
  static const inkSoft = Color(0xFF6E5034); // secondary text
  static const cream = Color(0xFFFBF5EA); // page background
  static const card = Color(0xFFFFFDF8); // cards and panels
  static const line = Color(0xFFEADCC6); // borders
  static const teal = Color(0xFF1E6E68); // buttons and highlights
  static const coin = Color(0xFFF2A93B);
  static const coinDark = Color(0xFFC47D12);
  static const woodText = Color(0xFF5A3415); // titles printed on wood
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito', // bundled in assets/fonts
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        surface: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 54),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.inkSoft, width: 1.5),
          textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
