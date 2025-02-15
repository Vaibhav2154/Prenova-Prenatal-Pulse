import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlowingButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const GlowingButton({Key? key, required this.text, required this.onPressed}) : super(key: key);

  @override
  _GlowingButtonState createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = ColorTween(
      begin: Colors.purpleAccent.withOpacity(0.5),
      end: Colors.purpleAccent.withOpacity(0.9),
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _glowAnimation.value!,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              backgroundColor: Colors.purpleAccent.withOpacity(0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0, // Remove default elevation
            ),
            child: Text(
              widget.text,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
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
