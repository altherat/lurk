import 'package:flutter/material.dart';

class Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  final double valueFontSize;
  final double labelFontSize;

  const Stat({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.valueFontSize = 18,
    this.labelFontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: labelFontSize, color: color),
        ),
      ],
    );
  }
}
