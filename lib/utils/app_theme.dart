import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color bgGrey = Color(0xFFF0F3F8);
  static const Color startRed = Color(0xFFE53935);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: bgGrey,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}