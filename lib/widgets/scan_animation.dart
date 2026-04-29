import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/element_palette.dart';

class ScanAnimation extends StatefulWidget {
  final bool isScanning;
  final double size;

  const ScanAnimation({
    super.key,
    this.isScanning = true,
    this.size = 200,
  });

  @override
  State<ScanAnimation> createState() => _ScanAnimationState();
}

class _ScanAnimationState extends State<ScanAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(ScanAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!widget.isScanning) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) {
      return Icon(
        Icons.bluetooth_searching,
        size: widget.size * 0.4,
        color: ElementPalette.muted,
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _waveController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _WavePainter(
              pulseValue: _pulseController.value,
              waveValue: _waveController.value,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double pulseValue;
  final double waveValue;

  _WavePainter({
    required this.pulseValue,
    required this.waveValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveOffset = (waveValue + i * 0.33) % 1.0;
      final radius = maxRadius * waveOffset;
      final opacity = (1.0 - waveOffset) * (0.3 + pulseValue * 0.2);

      final paint = Paint()
        ..color = ElementPalette.accent.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }

    final centerPaint = Paint()
      ..color = ElementPalette.accent.withOpacity(0.5 + pulseValue * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 20 + pulseValue * 5, centerPaint);

    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, iconPaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.waveValue != waveValue;
  }
}

class ScanAnimationWithDevices extends StatelessWidget {
  final bool isScanning;
  final List<DiscoveredDevice> devices;
  final Function(DiscoveredDevice)? onDeviceTap;

  const ScanAnimationWithDevices({
    super.key,
    this.isScanning = true,
    this.devices = const [],
    this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScanAnimation(isScanning: isScanning),
        const SizedBox(height: 24),
        if (devices.isEmpty)
          const Text(
            'Procurando dispositivos...',
            style: TextStyle(
              color: ElementPalette.muted,
              fontSize: 14,
            ),
          )
        else
          Text(
            '${devices.length} dispositivo(s) encontrado(s)',
            style: const TextStyle(
              color: ElementPalette.muted,
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}

class DiscoveredDevice {
  final String name;
  final String address;
  final int rssi;
  final DateTime discoveredAt;

  DiscoveredDevice({
    required this.name,
    required this.address,
    required this.rssi,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  String get distance {
    if (rssi >= -50) return 'Próximo';
    if (rssi >= -70) return 'Perto';
    if (rssi >= -85) return 'Longe';
    return 'Muito longe';
  }

  int get signalBars {
    if (rssi >= -50) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }
}