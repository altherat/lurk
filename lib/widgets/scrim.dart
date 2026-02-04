import 'package:flutter/material.dart';

class Scrim extends StatelessWidget {

  final Color color;

  const Scrim({
    super.key,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top,
      child: ColoredBox(color: color),
    );
  }

}