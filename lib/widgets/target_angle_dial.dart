import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class TargetAngleDial extends StatelessWidget {
  final int targetAngle;
  final int currentAngle;
  final bool isRunning;
  final double size;

  const TargetAngleDial({
    super.key,
    required this.targetAngle,
    required this.currentAngle,
    this.isRunning = false,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DialPainter(
              targetAngle: targetAngle,
              currentAngle: currentAngle,
              isRunning: isRunning,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$targetAngle°",
                style: AppTheme.monoValue(fontSize: 32, color: AppTheme.primaryAccent),
              ),
              const SizedBox(height: 4),
              Text(
                "ACTUAL: $currentAngle°",
                style: AppTheme.monoSubheader(fontSize: 11, color: const Color(0xFFA0A5B0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final int targetAngle;
  final int currentAngle;
  final bool isRunning;

  _DialPainter({
    required this.targetAngle,
    required this.currentAngle,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.4;

    final bgPaint = Paint()
      ..color = const Color(0xFF1E2228)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final tickPaint = Paint()
      ..color = const Color(0xFF3E4550)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw outer background circle
    canvas.drawCircle(center, radius, bgPaint);

    // Draw compass degree tick marks (every 30 degrees)
    for (int deg = 0; deg < 360; deg += 30) {
      final double rad = deg * pi / 180;
      final double x1 = center.dx + (radius - 8) * cos(rad);
      final double y1 = center.dy + (radius - 8) * sin(rad);
      final double x2 = center.dx + radius * cos(rad);
      final double y2 = center.dy + radius * sin(rad);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }

    // Draw active target arc (from 0 to targetAngle)
    final arcPaint = Paint()
      ..color = AppTheme.primaryAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final double startRad = -pi / 2;
    final double sweepRad = (targetAngle % 360) * pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      sweepRad,
      false,
      arcPaint,
    );

    // Draw vector needle pointing to target position
    final double needleRad = (targetAngle - 90) * pi / 180;
    final double needleLength = radius * 0.75;
    final double endX = center.dx + needleLength * cos(needleRad);
    final double endY = center.dy + needleLength * sin(needleRad);

    final needlePaint = Paint()
      ..color = isRunning ? AppTheme.brightAccent : AppTheme.primaryAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(endX, endY), needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = AppTheme.primaryAccent);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.targetAngle != targetAngle ||
      oldDelegate.currentAngle != currentAngle ||
      oldDelegate.isRunning != isRunning;
}
