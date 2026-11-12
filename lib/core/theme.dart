import 'package:flutter/material.dart';

/// Identidad visual "Dirección B · Índigo Atlético".
///
/// Solo hay cinco colores de marca; todo lo demás (líneas, fondos suaves,
/// sombras) son esos mismos colores con transparencia o mezclados con blanco.
class AppColors {
  // Paleta de marca
  static const niebla = Color(0xFFF5F6FB); // fondo
  static const indigo = Color(0xFF23246B); // marca, encabezados, superficies destacadas
  static const cobalto = Color(0xFF3A55E8); // botones secundarios, enlaces, progreso
  static const ambar = Color(0xFFFFB547); // acento, botón principal, logros
  static const pizarra = Color(0xFF565A7A); // texto secundario

  // Derivados de la paleta
  static const ink = Color(0xFF1B1C4D); // texto principal (índigo oscurecido)
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E4EF); // índigo al 12 % sobre blanco
  static const track = Color(0xFFE8EAF4);
  static const fill = Color(0xFFECEEF7); // campos de texto y controles en reposo
  static const indigoSoft = Color(0xFFE9EAF8); // fondos suaves de iconos y chips
  static const cobaltoSoft = Color(0x1A3A55E8); // botones "tintados"
  static const ambarSoft = Color(0x33FFB547);
  static const onIndigoMuted = Color(0xFFC9CCF2); // texto secundario sobre índigo
  static const hover = Color(0x0A23246B); // capa al pasar el puntero
  static const pressed = Color(0x1423246B); // capa al presionar
  static const glass = Color(0xD9FFFFFF); // barras translúcidas
  static const skeleton = Color(0xFFE4E6F1);

  /// Cambios positivos y confirmaciones: cobalto (la paleta no tiene verde).
  static const success = cobalto;

  /// Única excepción a la paleta: rojo solo para errores y acciones destructivas,
  /// porque es la señal que la gente reconoce.
  static const danger = Color(0xFFB3261E);
}

/// Sombras suaves teñidas de índigo: dan profundidad sin bordes duros.
const kShadowCard = [
  BoxShadow(color: Color(0x0A23246B), blurRadius: 24, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x0A23246B), blurRadius: 2, offset: Offset(0, 1)),
];
const kShadowFloating = [
  BoxShadow(color: Color(0x1F23246B), blurRadius: 32, offset: Offset(0, 12)),
  BoxShadow(color: Color(0x0F23246B), blurRadius: 4, offset: Offset(0, 1)),
];

// Radios
const kRadiusCard = 22.0;
const kRadiusControl = 14.0;

// Movimiento: entradas con desaceleración, salidas más cortas.
const kCurve = Curves.easeOutCubic;
const kFast = Duration(milliseconds: 140);
const kMedium = Duration(milliseconds: 260);

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

OutlineInputBorder _borde(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadiusControl),
      borderSide: BorderSide(color: color, width: width),
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
      onSurfaceVariant: AppColors.pizarra,
      outline: AppColors.line,
      error: AppColors.danger,
    ),
  );
  return base.copyWith(
    // Sin onda de tinta: la respuesta al toque es un cambio suave de tono y escala
    splashFactory: NoSplash.splashFactory,
    highlightColor: AppColors.pressed,
    hoverColor: AppColors.hover,
    focusColor: AppColors.cobaltoSoft,
    dividerColor: AppColors.line,
    textTheme: base.textTheme.apply(
      fontFamily: kBodyFont,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.indigo,
      contentTextStyle: ts(14, weight: kSemi, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x5523246B),
      elevation: 24,
      barrierColor: const Color(0x661B1C4D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x4023246B),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: AppColors.indigo, borderRadius: BorderRadius.circular(8)),
      textStyle: ts(12, weight: kSemi, color: Colors.white),
      waitDuration: const Duration(milliseconds: 500),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.cobalto,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(99),
      thumbColor: const WidgetStatePropertyAll(Color(0x4D565A7A)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.cobalto),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fill,
      hintStyle: ts(15, color: AppColors.pizarra),
      labelStyle: ts(15, color: AppColors.pizarra),
      floatingLabelStyle: ts(15, weight: kSemi, color: AppColors.cobalto),
      prefixIconColor: AppColors.pizarra,
      suffixIconColor: AppColors.pizarra,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      // En reposo no hay borde: el campo se distingue por su fondo
      border: _borde(Colors.transparent),
      enabledBorder: _borde(Colors.transparent),
      disabledBorder: _borde(Colors.transparent),
      focusedBorder: _borde(AppColors.cobalto, 1.5),
      errorBorder: _borde(AppColors.danger),
      focusedErrorBorder: _borde(AppColors.danger, 1.5),
    ),
  );
}
