import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_theme.dart';

class MotorAnimationWidget extends StatefulWidget {
  final int speed;
  final int direction; // 0 for CW, 1 for CCW
  final bool isRunning;

  const MotorAnimationWidget({
    super.key,
    required this.speed,
    required this.direction,
    required this.isRunning,
  });

  @override
  State<MotorAnimationWidget> createState() => _MotorAnimationWidgetState();
}

class _MotorAnimationWidgetState extends State<MotorAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant MotorAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed || oldWidget.direction != widget.direction || oldWidget.isRunning != widget.isRunning) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (!widget.isRunning || widget.speed == 0) {
      _controller.stop();
    } else {
      // Speed is 1-100. Let's make 100 = 0.2s full rotation, 1 = 5s full rotation.
      final seconds = 5.0 - (widget.speed / 100.0 * 4.8); 
      _controller.duration = Duration(milliseconds: (seconds * 1000).toInt());
      if (widget.direction == 0) {
        _controller.repeat();
      } else {
        _controller.repeat(reverse: false); // We'll handle CCW in the builder
      }
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
        double angle = _controller.value * 2 * math.pi;
        if (widget.direction == 1) {
          angle = -angle; // CCW
        }
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.cardBorder, width: 8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryAccent.withOpacity(widget.isRunning ? 0.3 : 0.0),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Shaft
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppTheme.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            // Indicator dot
            Positioned(
              top: 15,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
