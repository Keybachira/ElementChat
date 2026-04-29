import 'package:flutter/material.dart';

class ElementPalette {
  ElementPalette._();

  static const Color bg = Color(0xFF08091A);
  static const Color surface = Color(0xFF111827);
  static const Color border = Color(0xFF1F2D42);
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF00E5FF);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFB800);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color text = Color(0xFFE8EBF0);
  static const Color muted = Color(0xFF4A5568);

  static const Color primaryLight = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42CC);

  static const Color surfaceElevated = Color(0xFF1A2235);
  static const Color surfaceHighlight = Color(0xFF232D42);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryLight, primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get messageBubbleGradient => LinearGradient(
        colors: [primary.withOpacity(0.15), primary.withOpacity(0.08)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class ElementColors {
  ElementColors._();

  static const Color primary = ElementPalette.primary;
  static const Color accent = ElementPalette.accent;
  static const Color success = ElementPalette.success;
  static const Color warning = ElementPalette.warning;
  static const Color danger = ElementPalette.danger;
  static const Color text = ElementPalette.text;
  static const Color muted = ElementPalette.muted;
  static const Color background = ElementPalette.bg;
  static const Color surface = ElementPalette.surface;
  static const Color border = ElementPalette.border;
}