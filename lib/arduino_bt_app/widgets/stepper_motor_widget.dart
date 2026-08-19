import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/arduino_bt_theme.dart';

class StepperMotorWidget extends StatefulWidget {
  final bool isRunning;
  final bool isForward;
  final bool isEmergencyStopped;
  final double size;

  const StepperMotorWidget({
    super.key,
    required this.isRunning,
    required this.isForward,
    required this.isEmergencyStopped,
    this.size = 200,
  });

  @override
  State<StepperMotorWidget> createState() => _StepperMotorWidgetState();
}

class _StepperMotorWidgetState extends State<StepperMotorWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.isRunning && !widget.isEmergencyStopped) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant StepperMotorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isEmergencyStopped) {
      _controller.stop();
    } else if (widget.isRunning) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double rotationAngle = _controller.value * 2 * math.pi;
        if (!widget.isForward) {
          rotationAngle = -rotationAngle;
        }

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ArduinoBtTheme.cardBg,
            border: Border.all(
              color: widget.isEmergencyStopped
                  ? ArduinoBtTheme.dangerRed
                  : (widget.isRunning
                      ? (widget.isForward ? ArduinoBtTheme.primaryCyan : ArduinoBtTheme.accentPurple)
                      : ArduinoBtTheme.cardBorder),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isEmergencyStopped
                    ? ArduinoBtTheme.dangerRed.withOpacity(0.4)
                    : (widget.isRunning
                        ? (widget.isForward
                            ? ArduinoBtTheme.primaryCyan.withOpacity(0.3)
                            : ArduinoBtTheme.accentPurple.withOpacity(0.3))
                        : Colors.transparent),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Stator Ring & Coils
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: StatorPainter(
                  isEmergencyStopped: widget.isEmergencyStopped,
                  isRunning: widget.isRunning,
                  isForward: widget.isForward,
                ),
              ),

              // Rotating Rotor Core
              Transform.rotate(
                angle: rotationAngle,
                child: Container(
                  width: widget.size * 0.55,
                  height: widget.size * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF334155),
                        const Color(0xFF0F172A),
                      ],
                    ),
                    border: Border.all(color: ArduinoBtTheme.cardBorder, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shaft notch indicator
                      Positioned(
                        top: 10,
                        child: Container(
                          width: 8,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.isEmergencyStopped
                                ? ArduinoBtTheme.dangerRed
                                : (widget.isForward ? ArduinoBtTheme.primaryCyan : ArduinoBtTheme.accentPurple),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Center Motor Axle
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Center Status Label Overdrive
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ArduinoBtTheme.bgDark.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isEmergencyStopped ? ArduinoBtTheme.dangerRed : ArduinoBtTheme.cardBorder,
                    ),
                  ),
                  child: Text(
                    widget.isEmergencyStopped
                        ? "HALTED"
                        : (widget.isRunning
                            ? (widget.isForward ? "CW (FWD)" : "CCW (REV)")
                            : "IDLE"),
                    style: ArduinoBtTheme.monoStyle(
                      fontSize: 10,
                      color: widget.isEmergencyStopped
                          ? ArduinoBtTheme.dangerRed
                          : (widget.isForward ? ArduinoBtTheme.primaryCyan : ArduinoBtTheme.accentPurple),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatorPainter extends CustomPainter {
  final bool isEmergencyStopped;
  final bool isRunning;
  final bool isForward;

  StatorPainter({
    required this.isEmergencyStopped,
    required this.isRunning,
    required this.isForward,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final paint = Paint()
      ..color = isEmergencyStopped
          ? ArduinoBtTheme.dangerRed
          : (isRunning
              ? (isForward ? ArduinoBtTheme.primaryCyan : ArduinoBtTheme.accentPurple)
              : ArduinoBtTheme.textDim)
      ..style = PaintingStyle.fill;

    // Draw 4 Stator Pole Inductors
    for (int i = 0; i < 4; i++) {
      double angle = i * math.pi / 2;
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
