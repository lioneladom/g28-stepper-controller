import 'package:flutter/material.dart';

class TechIcon extends StatelessWidget {
  final TechIconType type;
  final double size;
  final Color color;

  const TechIcon({
    super.key,
    required this.type,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TechIconPainter(type: type, color: color),
    );
  }
}

enum TechIconType {
  radarScan,
  bluetooth,
  stepperMotor,
  chip,
  settings,
  controlSliders,
  emergencyWarning,
  copy,
  signalRssi,
  refresh,
  powerDisconnect,
}

class _TechIconPainter extends CustomPainter {
  final TechIconType type;
  final Color color;

  _TechIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (type) {
      case TechIconType.radarScan:
        // Concentric radar circles + crosshair target
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.4, paint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.22, paint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.06, fillPaint);
        canvas.drawLine(Offset(w * 0.5, h * 0.1), Offset(w * 0.5, h * 0.9), paint);
        canvas.drawLine(Offset(w * 0.1, h * 0.5), Offset(w * 0.9, h * 0.5), paint);
        break;

      case TechIconType.bluetooth:
        final path = Path()
          ..moveTo(w * 0.35, h * 0.25)
          ..lineTo(w * 0.65, h * 0.5)
          ..lineTo(w * 0.5, h * 0.1)
          ..lineTo(w * 0.5, h * 0.9)
          ..lineTo(w * 0.65, h * 0.5)
          ..lineTo(w * 0.35, h * 0.75);
        canvas.drawPath(path, paint);
        break;

      case TechIconType.stepperMotor:
        // Mechanical motor body + central shaft & coils
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.7, h * 0.65),
          const Radius.circular(4),
        );
        canvas.drawRRect(rrect, paint);
        // Top shaft protrusion
        canvas.drawRect(Rect.fromLTWH(w * 0.4, h * 0.08, w * 0.2, h * 0.12), fillPaint);
        // Central rotor circle
        canvas.drawCircle(Offset(w * 0.5, h * 0.525), w * 0.18, paint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.525), w * 0.05, fillPaint);
        break;

      case TechIconType.chip:
        // Integrated circuit body with pins
        final rect = Rect.fromLTWH(w * 0.25, h * 0.25, w * 0.5, h * 0.5);
        canvas.drawRect(rect, paint);
        // IC Pins
        for (double p = 0.35; p <= 0.65; p += 0.15) {
          // Top & bottom pins
          canvas.drawLine(Offset(w * p, h * 0.1), Offset(w * p, h * 0.25), paint);
          canvas.drawLine(Offset(w * p, h * 0.75), Offset(w * p, h * 0.9), paint);
          // Left & right pins
          canvas.drawLine(Offset(w * 0.1, h * p), Offset(w * 0.25, h * p), paint);
          canvas.drawLine(Offset(w * 0.75, h * p), Offset(w * 0.9, h * p), paint);
        }
        break;

      case TechIconType.settings:
        // Gear wheel configuration icon
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.22, paint);
        for (int i = 0; i < 6; i++) {
          final double angle = i * 3.14159 / 3;
          canvas.save();
          canvas.translate(w * 0.5, h * 0.5);
          canvas.rotate(angle);
          canvas.drawRect(Rect.fromLTWH(-w * 0.06, -h * 0.42, w * 0.12, h * 0.12), fillPaint);
          canvas.restore();
        }
        break;

      case TechIconType.controlSliders:
        // Equalizer / telemetry sliders icon
        for (int i = 0; i < 3; i++) {
          final double x = w * (0.25 + i * 0.25);
          canvas.drawLine(Offset(x, h * 0.15), Offset(x, h * 0.85), paint);
          final double sliderY = h * (i == 0 ? 0.35 : i == 1 ? 0.65 : 0.4);
          canvas.drawRect(Rect.fromLTWH(x - w * 0.08, sliderY - h * 0.08, w * 0.16, h * 0.16), fillPaint);
        }
        break;

      case TechIconType.emergencyWarning:
        // Diamond hazard icon with exclamation mark
        final path = Path()
          ..moveTo(w * 0.5, h * 0.05)
          ..lineTo(w * 0.95, h * 0.5)
          ..lineTo(w * 0.5, h * 0.95)
          ..lineTo(w * 0.05, h * 0.5)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.58), paint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.72), w * 0.05, fillPaint);
        break;

      case TechIconType.copy:
        canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.1, w * 0.55, h * 0.6), paint);
        canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.3, w * 0.55, h * 0.6), paint);
        break;

      case TechIconType.signalRssi:
        canvas.drawRect(Rect.fromLTWH(w * 0.1, h * 0.7, w * 0.12, h * 0.2), fillPaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.5, w * 0.12, h * 0.4), fillPaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.5, h * 0.3, w * 0.12, h * 0.6), fillPaint);
        canvas.drawRect(Rect.fromLTWH(w * 0.7, h * 0.1, w * 0.12, h * 0.8), fillPaint);
        break;

      case TechIconType.refresh:
        canvas.drawArc(
          Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7),
          0.4,
          5.2,
          false,
          paint,
        );
        final arrowPath = Path()
          ..moveTo(w * 0.75, h * 0.05)
          ..lineTo(w * 0.9, h * 0.25)
          ..lineTo(w * 0.65, h * 0.3);
        canvas.drawPath(arrowPath, fillPaint);
        break;

      case TechIconType.powerDisconnect:
        canvas.drawArc(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7), -2.2, 4.4, false, paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.08), Offset(w * 0.5, h * 0.45), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _TechIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
