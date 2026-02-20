import 'dart:math';

import 'package:flutter/material.dart';

class ExpansionIcon extends StatelessWidget {

  final bool up;
  final Duration duration;
  final Curve curve;

  const ExpansionIcon({
    super.key,
    required this.up,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: up ? pi : 0),
      duration: duration,
      curve: curve,
      builder: (context, rotation, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateX(rotation),
          child: const Icon(Icons.expand_less_rounded),
        );
      },
    );
  }

}