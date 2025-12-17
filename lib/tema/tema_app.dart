// lib/tema/tema_app.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Definimos nuestra paleta de colores "Coquette"
const Color _cremaFondo = Color(0xFFFFF9F3);
const Color _coralVibrante = Color.fromARGB(255, 134, 134, 134);
const Color _grisOscuro = Color(0xFF333333);
const Color _mentaSuave = Color(0xFFA0E7E5);

// 2. Creamos nuestro tema
class TemaApp { // Cambiado de AppTheme a TemaApp

  final ThemeData theme = ThemeData(
    useMaterial3: true,

    // Color de fondo principal de la app
    scaffoldBackgroundColor: _cremaFondo,

    // Paleta de colores
    colorScheme: ColorScheme.fromSeed(
      seedColor: _coralVibrante,
      primary: _coralVibrante,
      secondary: _mentaSuave,
      background: _cremaFondo,
      brightness: Brightness.light,
    ),

    // Tema para la barra de navegación (AppBar)
    appBarTheme: AppBarTheme(
      backgroundColor: _cremaFondo,
      elevation: 0, // Sin sombra, para un look más moderno
      centerTitle: true,
      titleTextStyle: GoogleFonts.lora( // Fuente elegante para títulos
        color: _coralVibrante,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: _coralVibrante),
    ),

    // Tema para los botones
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _coralVibrante,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.nunito( // Fuente amigable para botones
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bordes redondeados
        ),
      ),
    ),

    // Tema para campos de texto (Inputs)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Sin borde, para un estilo más "suave"
      ),
      hintStyle: GoogleFonts.nunito(color: _grisOscuro.withOpacity(0.5)),
    ),

    // Definición de las fuentes de texto (Tipografía)
    textTheme: TextTheme(
      titleMedium: GoogleFonts.nunito(color: _grisOscuro), 
      titleSmall: GoogleFonts.nunito(color: _grisOscuro),
      bodyLarge: GoogleFonts.nunito(color: _grisOscuro, fontSize: 16), // Texto principal
      bodyMedium: GoogleFonts.nunito(color: _grisOscuro, fontSize: 14),
      bodySmall: GoogleFonts.nunito(color: _grisOscuro, fontSize: 12),
    ),
  );
}