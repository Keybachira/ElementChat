import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/element_palette.dart';

class IdentityAvatar extends StatelessWidget {
  final String address;
  final double size;
  final bool isOnline;

  const IdentityAvatar({
    super.key,
    required this.address,
    this.size = 40,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _generateColors();
    final shape = _generateShape();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[0],
        shape: shape,
        border: Border.all(
          color: isOnline ? ElementPalette.success : ElementPalette.border,
          width: isOnline ? 2 : 1,
        ),
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: ElementPalette.success.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _AvatarPatternPainter(
          colors: colors,
          address: address,
        ),
      ),
    );
  }

  List<Color> _generateColors() {
    final hash = address.hashCode;
    final hue = (hash % 360).abs().toDouble();
    final baseColor = HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
    final lighterColor = HSLColor.fromAHSL(1.0, hue, 0.6, 0.7).toColor();
    return [baseColor, lighterColor];
  }

  BoxShape _generateShape() {
    final hash = address.hashCode;
    final shapes = [
      BoxShape.circle,
      BoxShape.rectangle,
    ];
    return shapes[hash % shapes.length];
  }
}

class _AvatarPatternPainter extends CustomPainter {
  final List<Color> colors;
  final String address;

  _AvatarPatternPainter({
    required this.colors,
    required this.address,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hash = address.hashCode;
    final pattern = hash % 4;

    final paint1 = Paint()
      ..color = colors[0].withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = colors[1].withOpacity(0.2)
      ..style = PaintingStyle.fill;

    switch (pattern) {
      case 0:
        _drawCircles(canvas, size, paint1, paint2);
        break;
      case 1:
        _drawTriangles(canvas, size, paint1, paint2);
        break;
      case 2:
        _drawRectangles(canvas, size, paint1, paint2);
        break;
      case 3:
        _drawLines(canvas, size, paint1);
        break;
    }
  }

  void _drawCircles(Canvas canvas, Size size, Paint paint1, Paint paint2) {
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      size.width * 0.15,
      paint1,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.2,
      paint2,
    );
  }

  void _drawTriangles(Canvas canvas, Size size, Paint paint1, Paint paint2) {
    final path1 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..close();

    final path2 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height * 0.9)
      ..lineTo(size.width * 0.7, size.height * 0.9)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  void _drawRectangles(Canvas canvas, Size size, Paint paint1, Paint paint2) {
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, size.width * 0.3, size.height * 0.3),
      paint1,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.5, size.width * 0.4, size.height * 0.4),
      paint2,
    );
  }

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IdentityAvatarWithName extends StatelessWidget {
  final String name;
  final String address;
  final double size;
  final bool isOnline;
  final Widget? trailing;

  const IdentityAvatarWithName({
    super.key,
    required this.name,
    required this.address,
    this.size = 40,
    this.isOnline = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IdentityAvatar(
          address: address,
          size: size,
          isOnline: isOnline,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElementPalette.text,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                address.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: ElementPalette.muted,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}