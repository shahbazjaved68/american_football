import 'package:flutter/material.dart';

class WaitingLogo extends StatelessWidget {
  final double size; // Size of the logo (default: 50)
  final Color color; // Color of the logo (default: red)
  final bool isSpinning; // Whether the logo should spin (default: false)

  const WaitingLogo({
    Key? key,
    this.size = 50.0,
    this.color = Colors.red,
    this.isSpinning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isSpinning
        ? SizedBox(
            width: size,
            height: size,
            child: _SpinningLogo(size: size, color: color),
          )
        : Icon(
            Icons.sports_football,
            size: size,
            color: color,
          );
  }
}

class _SpinningLogo extends StatefulWidget {
  final double size;
  final Color color;

  const _SpinningLogo({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  State<_SpinningLogo> createState() => _SpinningLogoState();
}

class _SpinningLogoState extends State<_SpinningLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Spin duration
    )..repeat(); // Infinite spinning animation
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
        return Transform.rotate(
          angle: _controller.value * 6.28, // Full rotation (2 * pi)
          child: Icon(
            Icons.sports_football,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}
