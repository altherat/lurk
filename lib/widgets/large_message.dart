import 'package:flutter/material.dart';

const _iconSize = 160.0;
const _fontSize = 24.0;

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
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Transform.translate(
              offset: const Offset(16, 16),
              child: Icon(icon, size: _iconSize, color: color.withAlpha(25))
            ),
            Icon(
              icon,
              size: _iconSize,
              color: Color.alphaBlend(
                color.withAlpha(150),
                colorScheme.surface
              )
            ),
          ],
        ),
        if (message != null)
          Text(
            message!,
            style: TextStyle(
              fontSize: _fontSize,
              color: color
            )
          ),
      ],
    );
  }
  
}