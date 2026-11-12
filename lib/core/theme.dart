import 'package:flutter/material.dart';

/// Identidad visual "Dirección B · Índigo Atlético".
class AppColors {
  // Paleta de marca
  static const niebla = Color(0xFFF5F6FB); // fondo
  static const indigo = Color(0xFF23246B); // marca, encabezados, superficies destacadas
  static const cobalto = Color(0xFF3A55E8); // botones secundarios, enlaces, progreso
  static const ambar = Color(0xFFFFB547); // acento, botón principal, logros
  static const pizarra = Color(0xFF565A7A); // texto secundario

  // Derivados
  static const ink = Color(0xFF1B1C4D); // texto principal
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E4EF);
  static const track = Color(0xFFE8EAF4);
  static const indigoSoft = Color(0xFFE9EAF8); // fondos suaves de iconos y chips
  static const onIndigoMuted = Color(0xFFC9CCF2); // texto secundario sobre índigo
  static const success = Color(0xFF1F7A4D); // cambios positivos (contraste AA sobre blanco)
  static const danger = Color(0xFFB3261E);
  static const skeleton = Color(0xFFE4E6F1);
}

// REGLA 7: solo 3 grosores en toda la app.
const kRegular = FontWeight.w400; // Barlow
const kSemi = FontWeight.w600; // Barlow
const kDisplayWeight = FontWeight.w800; // Barlow Condensed (títulos)

const kBodyFont = 'Barlow';
const kDisplayFont = 'BarlowCondensed';

/// Estilo de texto de cuerpo (Barlow 400 / 600).
TextStyle ts(
  double size, {
  FontWeight weight = kRegular,
  Color color = AppColors.ink,
  double? height,
  double? spacing,
}) =>
    TextStyle(
      fontFamily: kBodyFont,
      fontSize: size,
      fontWeight: weight == kSemi ? kSemi : kRegular,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

/// Estilo de títulos (Barlow Condensed 800). Úsalo con textos en mayúsculas.
TextStyle display(
  double size, {
  Color color = AppColors.ink,
  double height = 1.0,
  double? spacing,
}) =>
    TextStyle(
      fontFamily: kDisplayFont,
      fontSize: size,
      fontWeight: kDisplayWeight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: kBodyFont,
    scaffoldBackgroundColor: AppColors.niebla,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      primary: AppColors.cobalto,
      onPrimary: Colors.white,
      secondary: AppColors.ambar,
      onSecondary: AppColors.ink,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: kBodyFont,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.indigo,
      contentTextStyle: ts(14, weight: kSemi, color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      hintStyle: ts(14, color: AppColors.pizarra),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cobalto, width: 2),
      ),
    ),
  );
}
