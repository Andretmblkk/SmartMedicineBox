import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdherenceRing extends StatefulWidget {
  final double percentage;
  final double size;
  final double strokeWidth;

  const AdherenceRing({
    super.key,
    required this.percentage,
    this.size = 120,
    this.strokeWidth = 10,
  });

  @override
  State<AdherenceRing> createState() => _AdherenceRingState();
}

class _AdherenceRingState extends State<AdherenceRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              percentage: _animation.value,
              isDark: Theme.of(context).brightness == Brightness.dark,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_animation.value.toInt()}%',
                    style: AppTheme.heading2(context).copyWith(
                      color: AppTheme.primaryTeal,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Adherence',
                    style: AppTheme.label(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final bool isDark;
  final double strokeWidth;

  _RingPainter({
    required this.percentage,
    required this.isDark,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (strokeWidth / 2 + 3);

    // Background ring
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [
          AppTheme.primaryTeal,
          AppTheme.accentCyan,
          AppTheme.primaryBlue,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow dot at the end
    if (percentage > 0) {
      final dotAngle = -math.pi / 2 + sweepAngle;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);
      final dotCenter = Offset(dotX, dotY);

      // Glow
      final glowPaint = Paint()
        ..color = AppTheme.primaryTeal.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dotCenter, 6, glowPaint);

      // Dot
      final dotPaint = Paint()..color = AppTheme.primaryTeal;
      canvas.drawCircle(dotCenter, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
