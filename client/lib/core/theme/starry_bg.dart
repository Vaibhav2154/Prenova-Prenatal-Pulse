import 'dart:math';
import 'package:flutter/material.dart';

class StarryBackground extends StatefulWidget {
  final Widget child;
  const StarryBackground({Key? key, required this.child}) : super(key: key);

  @override
  _StarryBackgroundState createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> stars;
  final int starCount = 30; // Reduced for a calming effect
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Slow twinkling effect
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateStars();
    });
  }

  void _generateStars() {
    setState(() {
      stars = List.generate(starCount, (_) {
        return Star(
          position: Offset(
            random.nextDouble() * MediaQuery.of(context).size.width,
            random.nextDouble() * MediaQuery.of(context).size.height,
          ),
          size: random.nextDouble() * 3 + 2, // Bigger stars for subtle visibility
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: Colors.black), // Deep black background
            ...stars.map((star) => Positioned(
              left: star.position.dx,
              top: star.position.dy,
              child: Opacity(
                opacity: star.opacity.value,
                child: Container(
                  width: star.size,
                  height: star.size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            )),
            widget.child, // Wrap around this for any page
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Star {
  final Offset position;
  final double size;
  final Animation<double> opacity;
  Star({required this.position, required this.size, required this.opacity});
}
