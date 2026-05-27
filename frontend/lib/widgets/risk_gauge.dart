import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// ── Risk Gauge Widget ──────────────────────────────────────────────────────
/// Circular gauge displaying churn probability with animated fill
class RiskGauge extends StatefulWidget {
  final double probability;
  final String riskTier;
  final double size;

  const RiskGauge({
    super.key,
    required this.probability,
    required this.riskTier,
    this.size = 200,
  });

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.probability).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.probability != widget.probability) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.probability,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.riskColor(widget.riskTier);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              context: context,
              progress: _animation.value,
              color: color,
              backgroundColor: context.border,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_animation.value * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: widget.size * 0.18,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.riskSurfaceColor(widget.riskTier),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.riskTier.toUpperCase(),
                      style: TextStyle(
                        fontSize: widget.size * 0.07,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Churn Risk',
                    style: TextStyle(
                      fontSize: widget.size * 0.06,
                      color: context.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
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

class _GaugePainter extends CustomPainter {
  final BuildContext context;
  final double progress;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.context,
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 14.0;
    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Tick marks along the arc
    final tickCount = 10;
    final tickPaint = Paint()
      ..color = context.isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= tickCount; i++) {
      final angle = startAngle + (sweepAngle * (i / tickCount));
      final innerRad = radius - 16;
      final outerRad = radius - 6;
      final x1 = center.dx + innerRad * math.cos(angle);
      final y1 = center.dy + innerRad * math.sin(angle);
      final x2 = center.dx + outerRad * math.cos(angle);
      final y2 = center.dy + outerRad * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            context.success,
            context.warning,
            context.error,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        progressPaint,
      );

      // Glow dot at end of progress arc
      final dotAngle = startAngle + (sweepAngle * progress);
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        10,
        Paint()..color = color.withOpacity(0.3),
      );

      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()..color = Colors.white,
      );

      // Draw elegant speedometer needle (Akkio & Pecan style)
      final needleLength = radius - 12;
      final needleX = center.dx + needleLength * math.cos(dotAngle);
      final needleY = center.dy + needleLength * math.sin(dotAngle);

      // Shadow under needle for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx + 1, center.dy + 2),
        Offset(needleX + 1, needleY + 2),
        shadowPaint,
      );

      // Main needle
      final needlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, Offset(needleX, needleY), needlePaint);

      // Center pivot cap
      final pivotPaint = Paint()
        ..color = context.isDark ? AppColors.darkSurface : Colors.white;
      canvas.drawCircle(center, 12, pivotPaint);

      final pivotBorderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, 12, pivotBorderPaint);

      final pivotCenterPaint = Paint()..color = color;
      canvas.drawCircle(center, 5, pivotCenterPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
