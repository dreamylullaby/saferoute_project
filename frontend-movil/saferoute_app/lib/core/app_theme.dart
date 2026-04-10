import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Colores principales
  static const primary      = Color(0xFF2563EB);
  static const primaryDark  = Color(0xFF1E3A8A);
  static const primaryLight = Color(0xFF3B82F6);
  static const background   = Color(0xFFF1F5F9);
  static const surface      = Color(0xFFFFFFFF);
  static const border       = Color(0xFFCBD5E1);
  static const textMain     = Color(0xFF1E293B);
  static const textSub      = Color(0xFF64748B);
  static const error        = Color(0xFFEF4444);

  // Degradado splash/login
  static const gradientStart  = Color(0xFF1E1E7C);
  static const gradientMid    = Color(0xFF333C87);
  static const gradientEnd    = Color(0xFF6D6DF9);

  static const splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
    stops: [0.0, 0.5, 1.0],
    transform: GradientRotation(135 * 3.14159 / 180),
  );

  // Mapa de calor
  static const zonaSegura  = Color(0xFF22C55E);
  static const bajoRiesgo  = Color(0xFFFACC15);
  static const riesgoMedio = Color(0xFFF97316);
  static const altoRiesgo  = Color(0xFFBE185D);

  // Tipos de hurto
  static const hurtoAtraco     = Color(0xFFB91C1C);
  static const hurtoRaponazo   = Color(0xFF9D174D);
  static const hurtoFleteo     = Color(0xFFD946EF);
  static const hurtoCosquilleo = Color(0xFF8A2BE2);

  // Tendencias
  static const tendenciaDecremento = Color(0xFF10B981);
  static const tendenciaVariacion  = Color(0xFFF59E0B);
  static const tendenciaIncremento = Color(0xFFEF4444);

  // Franjas horarias
  static const franjaMannana   = Color(0xFFFBBF24);
  static const franjaTarde     = Color(0xFFF97316);
  static const franjaNoche     = Color(0xFFBE185D);
  static const franjaMadrugada = Color(0xFFD946EF);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textMain,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textSub,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      prefixIconColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(color: AppColors.textSub),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      surface: const Color(0xFF1E293B),
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFFE2E8F0),
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF94A3B8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      prefixIconColor: AppColors.primaryLight,
      labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

/// Notifier global para el modo oscuro, accesible desde cualquier página.
final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
