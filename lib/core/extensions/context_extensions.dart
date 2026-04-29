import 'package:flutter/material.dart';
import '../theme/element_palette.dart';
import '../theme/element_typography.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => mq.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mq.padding;
  EdgeInsets get viewInsets => mq.viewInsets;
}

extension ColorsExtension on BuildContext {
  ElementPalette get element => ElementPalette();
  Color get primary => ElementPalette.primary;
  Color get accent => ElementPalette.accent;
  Color get success => ElementPalette.success;
  Color get warning => ElementPalette.warning;
  Color get danger => ElementPalette.danger;
  Color get text => ElementPalette.text;
  Color get muted => ElementPalette.muted;
  Color get bg => ElementPalette.bg;
  Color get surface => ElementPalette.surface;
  Color get border => ElementPalette.border;
}

extension SizeExtension on BuildContext {
  double get vShort => screenHeight * 0.01;
  double get vMedium => screenHeight * 0.03;
  double get vLarge => screenHeight * 0.05;
  double get hShort => screenWidth * 0.02;
  double get hMedium => screenWidth * 0.04;
  double get hLarge => screenWidth * 0.08;
}

extension TypographyExtension on BuildContext {
  TextStyle get display => ElementTypography.display;
  TextStyle get headline => ElementTypography.headline;
  TextStyle get title => ElementTypography.title;
  TextStyle get subtitle => ElementTypography.subtitle;
  TextStyle get body => ElementTypography.body;
  TextStyle get bodySmall => ElementTypography.bodySmall;
  TextStyle get label => ElementTypography.label;
  TextStyle get caption => ElementTypography.caption;
  TextStyle get button => ElementTypography.button;
}

extension NavigationExtension on BuildContext {
  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(
        MaterialPageRoute(builder: (_) => page),
      );

  Future<T?> pushReplacement<T, TO>(Widget page) =>
      Navigator.of(this).pushReplacement<T, TO>(
        MaterialPageRoute(builder: (_) => page),
      );

  Future<T?> pushAndRemoveUntil<T>(Widget page) =>
      Navigator.of(this).pushAndRemoveUntil<T>(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  void popUntil(String routeName) => Navigator.of(this).popUntil(
        (route) => route.settings.name == routeName,
      );
}

extension SnackBarExtension on BuildContext {
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ElementPalette.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ElementPalette.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showInfo(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ElementPalette.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}