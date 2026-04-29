import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'element_palette.dart';

class ElementTheme {
  ElementTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ElementPalette.bg,
        colorScheme: const ColorScheme.dark(
          primary: ElementPalette.primary,
          secondary: ElementPalette.accent,
          surface: ElementPalette.surface,
          error: ElementPalette.danger,
          onPrimary: Colors.white,
          onSecondary: ElementPalette.bg,
          onSurface: ElementPalette.text,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge: TextStyle(color: ElementPalette.text),
            displayMedium: TextStyle(color: ElementPalette.text),
            displaySmall: TextStyle(color: ElementPalette.text),
            headlineLarge: TextStyle(color: ElementPalette.text),
            headlineMedium: TextStyle(color: ElementPalette.text),
            headlineSmall: TextStyle(color: ElementPalette.text),
            titleLarge: TextStyle(color: ElementPalette.text),
            titleMedium: TextStyle(color: ElementPalette.text),
            titleSmall: TextStyle(color: ElementPalette.text),
            bodyLarge: TextStyle(color: ElementPalette.text),
            bodyMedium: TextStyle(color: ElementPalette.text),
            bodySmall: TextStyle(color: ElementPalette.muted),
            labelLarge: TextStyle(color: ElementPalette.text),
            labelMedium: TextStyle(color: ElementPalette.text),
            labelSmall: TextStyle(color: ElementPalette.muted),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: ElementPalette.bg,
          foregroundColor: ElementPalette.text,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ElementPalette.text,
          ),
        ),
        cardTheme: CardThemeData(
          color: ElementPalette.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ElementPalette.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ElementPalette.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ElementPalette.primary,
            side: const BorderSide(color: ElementPalette.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ElementPalette.surface,
          hintStyle: GoogleFonts.inter(
            color: ElementPalette.muted,
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ElementPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ElementPalette.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ElementPalette.danger),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: ElementPalette.border,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: ElementPalette.surface,
          contentTextStyle: GoogleFonts.inter(color: ElementPalette.text),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: ElementPalette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ElementPalette.text,
          ),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 15,
            color: ElementPalette.muted,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: ElementPalette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        iconTheme: const IconThemeData(
          color: ElementPalette.text,
          size: 24,
        ),
      );
}
