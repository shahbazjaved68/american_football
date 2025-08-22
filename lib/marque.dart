import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class LiveMatchMarquee extends StatelessWidget {
  final String message;

  const LiveMatchMarquee({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.black.withOpacity(0.8),
      child: Marquee(
        text: message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        scrollAxis: Axis.horizontal,
        blankSpace: 20.0,
        velocity: 50.0,
        startPadding: 10.0,
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}
