import 'package:flutter/material.dart';

/// Colores saturados sobre fondo oscuro para la legibilidad a 3 m (Principio VIII, R12).
abstract final class AppColors {
  static const background = Color(0xFF121212);
  static const saberBlue = Color(0xFF1E6BFF);
  static const saberRed = Color(0xFFFF2D2D);
  static const saberYellow = Color(0xFFFFD400);
  static const saberWhite = Color(0xFFFFFFFF);
  static const outline = Color(0xFF000000);
}

/// Grosor mínimo del contorno del oponente, el sable y las señales, en dp.
const double kOutlineWidth = 4.0;

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.saberYellow,
      brightness: Brightness.dark,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      // Número de la cuenta regresiva.
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontSize: 200,
        fontWeight: FontWeight.w900,
        color: AppColors.saberWhite,
      ),
    ),
  );
}
