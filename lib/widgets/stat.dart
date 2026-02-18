import 'package:flutter/material.dart';

class Stat extends StatelessWidget {
  
  final String value;
  final String label;
  final double valueFontSize;
  final double labelFontSize;
  final Color? valueColor;
  final Color? labelColor;


  const Stat({
    super.key,
    required this.value,
    required this.label,
    this.valueFontSize = 18,
    this.labelFontSize = 11,
    this.valueColor,
    this.labelColor,
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
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            color: labelColor
          ),
        ),
      ],
    );
  }
}
