import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// DISEÑO ÍNDIGO ATLÉTICO
// MÚSCULO Y FORMA - SPRINT 3

class AnunciosTheme {
  static const Color fondo = Color(0xFFF5F6FB);
  static const Color indigo = Color(0xFF23246B);
  static const Color cobalto = Color(0xFF3A55E8);
  static const Color ambar = Color(0xFFFFB547);
  static const Color pizarra = Color(0xFF565A7A);
  static const Color blanco = Colors.white;
  static const Color borde = Color(0xFFE2E5F0);

  // Títulos: Barlow Condensed
  static TextStyle titulo({
    double size = 30,
    Color color = indigo,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }

  // Textos: Barlow
  static TextStyle texto({
    double size = 15,
    Color color = pizarra,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.barlow(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // Botones principales
  static ButtonStyle botonPrincipal() {
    return ElevatedButton.styleFrom(
      backgroundColor: cobalto,
      foregroundColor: blanco,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 18,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.barlow(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // Tarjetas
  static BoxDecoration tarjeta() {
    return BoxDecoration(
      color: blanco,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borde),
      boxShadow: [
        BoxShadow(
          color: indigo.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Campos de formulario
  static InputDecoration campo(String etiqueta) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: texto(),
      filled: true,
      fillColor: blanco,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: cobalto,
          width: 2,
        ),
      ),
    );
  }
}
