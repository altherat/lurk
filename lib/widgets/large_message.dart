import 'package:flutter/material.dart';

const _size = 160.0;

class LargeMessage extends StatelessWidget {

  final IconData icon;
  final String? message;

  const LargeMessage({
    super.key,
    required this.icon,
    required this.message
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).disabledColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _size, color: color),
        if (message != null)
          Text(message!, style: TextStyle(color: color)),
      ],
    );
  }
  
}