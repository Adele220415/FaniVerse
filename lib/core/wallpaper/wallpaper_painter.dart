import 'dart:math' as math;

import 'package:flutter/material.dart';

class WallpaperPainter extends CustomPainter {
  WallpaperPainter(this.id, {this.preview = false});

  final String id;
  final bool preview;

  @override
  void paint(Canvas canvas, Size size) {
    switch (id) {
      case 'aurora':
        _aurora(canvas, size);
      case 'sunset':
        _sunset(canvas, size);
      case 'lagoon':
        _lagoon(canvas, size);
      case 'blossom':
        _blossom(canvas, size);
      case 'dunes':
        _dunes(canvas, size);
      default:
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFF0F1419),
        );
    }
  }

  @override
  bool shouldRepaint(WallpaperPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.preview != preview;

  void _fill(
    Canvas canvas,
    Size size,
    List<Color> colors, {
    List<double>? stops,
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    final shader = LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _aurora(Canvas canvas, Size size) {
    _fill(
      canvas,
      size,
      const [Color(0xFF04060F), Color(0xFF0A142C), Color(0xFF05101C)],
      stops: const [0, 0.45, 1],
    );
    _stars(canvas, size);

    for (var band = 0; band < 3; band++) {
      final path = Path();
      final baseY = size.height * (0.3 + band * 0.14);
      final amp = size.height * (0.06 + band * 0.03);
      const steps = 40;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final x = size.width * t;
        final y = baseY +
            math.sin(t * math.pi * 2 * (1.1 + band * 0.4) + band * 1.7) * amp;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final colors = band == 1
          ? const [Color(0x0063A8FF), Color(0x9963A8FF), Color(0x00C47CFF)]
          : const [Color(0x004FF0C0), Color(0xCC4FF0C0), Color(0x008F7CFF)];

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.height * (0.07 + band * 0.03)
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: colors)
              .createShader(Offset.zero & size)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, size.height * 0.03),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, size.height * 0.01)
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              colors[0],
              colors[1].withValues(alpha: 0.85),
              colors[2],
            ],
          ).createShader(Offset.zero & size),
      );
    }
  }

  void _stars(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint();
    final count = preview ? 40 : 150;
    for (var i = 0; i < count; i++) {
      paint.color =
          Colors.white.withValues(alpha: 0.2 + rng.nextDouble() * 0.6);
      canvas.drawCircle(
        Offset(
          rng.nextDouble() * size.width,
          rng.nextDouble() * size.height * 0.85,
        ),
        0.4 + rng.nextDouble() * 1.4,
        paint,
      );
    }
  }

  void _sunset(Canvas canvas, Size size) {
    _fill(
      canvas,
      size,
      const [
        Color(0xFF1A0B2E),
        Color(0xFF5B1E4D),
        Color(0xFFB03F63),
        Color(0xFFEC7F52),
        Color(0xFFF8C07C),
      ],
      stops: const [0, 0.3, 0.55, 0.75, 1],
    );

    final rng = math.Random(3);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.1 + rng.nextDouble() * 0.8),
          size.height * (0.05 + rng.nextDouble() * 0.12),
        ),
        0.8 + rng.nextDouble() * 0.8,
        starPaint,
      );
    }

    final center = Offset(size.width * 0.5, size.height * 0.65);
    final radius = size.width * 0.17;
    final glowRadius = radius * 2.4;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x88FFCF92), const Color(0x00FFCF92)],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFE7C0),
    );

    _ridge(
      canvas,
      size,
      base: 0.76,
      lift: 0.08,
      color: const Color(0xD94A1740),
      seed: 0.4,
    );
    _ridge(
      canvas,
      size,
      base: 0.84,
      lift: 0.06,
      color: const Color(0xEB300F30),
      seed: 1.6,
    );
    _ridge(
      canvas,
      size,
      base: 0.92,
      lift: 0.05,
      color: const Color(0xFF1C0820),
      seed: 2.7,
    );
  }

  void _ridge(
    Canvas canvas,
    Size size, {
    required double base,
    required double lift,
    required Color color,
    required double seed,
  }) {
    const segments = 3;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, size.height * base);
    for (var i = 0; i < segments; i++) {
      final x0 = size.width * i / segments;
      final x1 = size.width * (i + 1) / segments;
      final peak = size.height *
          (base - lift * (0.5 + 0.5 * math.sin(seed + i * 1.7)));
      path.quadraticBezierTo(
        (x0 + x1) / 2,
        peak,
        x1,
        size.height * (base + 0.02 * math.cos(seed + i)),
      );
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _lagoon(Canvas canvas, Size size) {
    _fill(
      canvas,
      size,
      const [
        Color(0xFF02152B),
        Color(0xFF063A63),
        Color(0xFF0B7D9B),
        Color(0xFF12B3A6),
      ],
      stops: const [0, 0.4, 0.68, 1],
    );

    final rng = math.Random(11);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.12 + rng.nextDouble() * 0.7),
          size.height * (0.06 + rng.nextDouble() * 0.12),
        ),
        0.7 + rng.nextDouble() * 0.8,
        starPaint,
      );
    }

    final moonCenter = Offset(size.width * 0.77, size.height * 0.22);
    final glow = size.width * 0.2;
    canvas.drawCircle(
      moonCenter,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x40D8FBFF),
            const Color(0x00D8FBFF),
          ],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: glow)),
    );
    canvas.drawCircle(
      moonCenter,
      size.width * 0.11,
      Paint()..color = const Color(0xFFE6FDFF).withValues(alpha: 0.9),
    );

    for (var band = 0; band < 4; band++) {
      final path = Path();
      final y0 = size.height * (0.62 + band * 0.09);
      const steps = 30;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final x = size.width * t;
        final y =
            y0 + math.sin(t * math.pi * (3 + band) + band) * size.height * 0.02;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      final fills = [
        const Color(0xA604314F),
        const Color(0xD9022640),
        const Color(0xFF011B30),
        const Color(0xFF011B30),
      ];
      canvas.drawPath(path, Paint()..color = fills[band]);
    }

    for (var i = 0; i < 3; i++) {
      final path = Path();
      final y0 = size.height * (0.7 + i * 0.09);
      path.moveTo(size.width * 0.05, y0);
      path.quadraticBezierTo(
        size.width * 0.2,
        y0 - size.height * 0.012,
        size.width * 0.35,
        y0,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0x809FF3EF),
      );
    }
  }

  void _blossom(Canvas canvas, Size size) {
    _fill(
      canvas,
      size,
      const [Color(0xFFFFEFF6), Color(0xFFF4EBFF), Color(0xFFE8F2FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final rng = math.Random(5);
    const petals = [
      Color(0xFFFFC9DD),
      Color(0xFFD9C8FF),
      Color(0xFFBFE4FF),
      Color(0xFFFFD7C4),
      Color(0xFFE7D3FF),
    ];
    final count = preview ? 5 : 9;
    for (var i = 0; i < count; i++) {
      final center = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      final radius = size.shortestSide * (0.14 + rng.nextDouble() * 0.2);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = petals[rng.nextInt(petals.length)]
              .withValues(alpha: 0.8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6),
      );
    }

    final petalPaint = Paint()..color = Colors.white.withValues(alpha: 0.65);
    for (var i = 0; i < 4; i++) {
      final center = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      final rx = 8 + rng.nextDouble() * 8;
      final rect = Rect.fromCenter(center: center, width: rx * 2, height: rx * 1.3);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((rng.nextDouble() - 0.5) * 1.2);
      canvas.drawOval(rect.translate(-center.dx, -center.dy), petalPaint);
      canvas.restore();
    }
  }

  void _dunes(Canvas canvas, Size size) {
    _fill(
      canvas,
      size,
      const [Color(0xFFFFF3DA), Color(0xFFFBD9A6), Color(0xFFF0B877)],
      stops: const [0, 0.45, 1],
    );

    final sunCenter = Offset(size.width * 0.66, size.height * 0.27);
    final glow = size.width * 0.24;
    canvas.drawCircle(
      sunCenter,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xBFFFFFF6), const Color(0x00FFFFF6)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: glow)),
    );
    canvas.drawCircle(
      sunCenter,
      size.width * 0.12,
      Paint()..color = const Color(0xFFFFFDF4),
    );

    _dune(canvas, size, base: 0.64, color: const Color(0xFFE6A765), seed: 0.7);
    _dune(canvas, size, base: 0.76, color: const Color(0xFFD18E4F), seed: 2.1);
    _dune(canvas, size, base: 0.88, color: const Color(0xFFB5713E), seed: 3.4);
  }

  void _dune(
    Canvas canvas,
    Size size, {
    required double base,
    required Color color,
    required double seed,
  }) {
    const segments = 2;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, size.height * base);
    for (var i = 0; i < segments; i++) {
      final x0 = size.width * i / segments;
      final x1 = size.width * (i + 1) / segments;
      final peak = size.height *
          (base - 0.06 * (0.4 + 0.6 * math.sin(seed + i * 2.0)));
      path.quadraticBezierTo(
        (x0 + x1) / 2,
        peak,
        x1,
        size.height * (base + 0.03),
      );
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }
}
