import 'package:flutter/material.dart';
import 'package:prenova/core/theme/app_pallete.dart';
import 'dart:math';

class CustomLoader extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;
  final bool showMessage;

  const CustomLoader({
    Key? key,
    this.size = 60.0,
    this.message,
    this.color,
    this.showMessage = true,
  }) : super(key: key);

  @override
  _CustomLoaderState createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    child: CustomPaint(
                      painter: HeartLoaderPainter(
                        color: widget.color ?? AppPallete.gradient1,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.showMessage && widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                color: AppPallete.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class HeartLoaderPainter extends CustomPainter {
  final Color color;

  HeartLoaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;

    // Draw heart shape
    Path heartPath = Path();
    
    // Heart shape coordinates
    double heartSize = size.width * 0.4;
    double heartCenterX = center.dx;
    double heartCenterY = center.dy;
    
    heartPath.moveTo(heartCenterX, heartCenterY + heartSize * 0.3);
    
    heartPath.cubicTo(
      heartCenterX - heartSize * 0.5, heartCenterY - heartSize * 0.2,
      heartCenterX - heartSize * 0.5, heartCenterY - heartSize * 0.6,
      heartCenterX, heartCenterY - heartSize * 0.3,
    );
    
    heartPath.cubicTo(
      heartCenterX + heartSize * 0.5, heartCenterY - heartSize * 0.6,
      heartCenterX + heartSize * 0.5, heartCenterY - heartSize * 0.2,
      heartCenterX, heartCenterY + heartSize * 0.3,
    );

    canvas.drawPath(heartPath, paint);

    // Draw pulsing circles
    for (int i = 0; i < 3; i++) {
      final circleRadius = radius + (i * 8);
      final alpha = (255 * (1 - i * 0.3)).clamp(0, 255).toInt();
      final circlePaint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(center, circleRadius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Alternative simple circular loader
class SimpleCustomLoader extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;

  const SimpleCustomLoader({
    Key? key,
    this.size = 50.0,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  _SimpleCustomLoaderState createState() => _SimpleCustomLoaderState();
}

class _SimpleCustomLoaderState extends State<SimpleCustomLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: CircularLoaderPainter(
                    progress: _animation.value,
                    color: widget.color ?? AppPallete.gradient1,
                  ),
                );
              },
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.message!,
              style: TextStyle(
                color: AppPallete.textColor,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CircularLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularLoaderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}