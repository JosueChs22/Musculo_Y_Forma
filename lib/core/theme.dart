import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color w(double o) => Color.fromRGBO(255, 255, 255, o);
Color blk(double o) => Color.fromRGBO(0, 0, 0, o);

class AppColors {
  static const bg = Color(0xFF0E0F12);
  static const card = Color(0xFF18191E);
  static const sheet = Color(0xFF1B1C21);
  static const accent = Color(0xFFFF5A36);
  static const accentLight = Color(0xFFFF6B45);
  static const green = Color(0xFF54D6A1);
  static const cream = Color(0xFFF4F1EB);
  static const ink = Color(0xFF161619);
}

const kBlack = FontWeight.w900;
const kXBold = FontWeight.w800;
const kBold = FontWeight.w700;
const kSemi = FontWeight.w600;

TextStyle ts(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = Colors.white,
  double? height,
  double? spacing,
}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.bg,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
        .apply(bodyColor: Colors.white, displayColor: Colors.white),
  );
}
