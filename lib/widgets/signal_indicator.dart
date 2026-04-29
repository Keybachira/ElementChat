import 'package:flutter/material.dart';
import '../core/theme/element_palette.dart';

class SignalIndicator extends StatelessWidget {
  final int latencyMs;

  const SignalIndicator({
    super.key,
    required this.latencyMs,
  });

  @override
  Widget build(BuildContext context) {
    final bars = _calculateBars();
    final color = _getColor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < bars;
        return Container(
          width: 4,
          height: 8.0 + (index * 3),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? color : ElementPalette.border,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  int _calculateBars() {
    if (latencyMs < 50) return 4;
    if (latencyMs < 150) return 3;
    if (latencyMs < 300) return 2;
    return 1;
  }

  Color _getColor() {
    if (latencyMs < 50) return ElementPalette.success;
    if (latencyMs < 150) return ElementPalette.success;
    if (latencyMs < 300) return ElementPalette.warning;
    return ElementPalette.danger;
  }
}

class SignalIndicatorWithLabel extends StatelessWidget {
  final int latencyMs;
  final String? label;

  const SignalIndicatorWithLabel({
    super.key,
    required this.latencyMs,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SignalIndicator(latencyMs: latencyMs),
        if (label != null) ...[
          const SizedBox(width: 6),
          Text(
            label!,
            style: const TextStyle(
              fontSize: 10,
              color: ElementPalette.muted,
            ),
          ),
        ],
      ],
    );
  }
}