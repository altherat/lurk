import 'package:flutter/material.dart';

const _largeIconSize = 160.0;
const _largeFontSize = 24.0;

class LargeVerticalIconMessage extends StatelessWidget {

  final IconData icon;
  final String? message;

  const LargeVerticalIconMessage({
    super.key,
    required this.icon,
    required this.message
  });

  @override
  Widget build(BuildContext context) {
    return VerticalIconMessage(
      icon: icon,
      message: message,
      iconSize: _largeIconSize,
      fontSize: _largeFontSize
    );
  }

}

class HorizontalIconMessage extends StatelessWidget {

  final IconData icon;
  final String? message;
  final double iconSize;
  final double? fontSize;
  final double space;

  const HorizontalIconMessage({
    super.key,
    required this.icon,
    required this.message,
    this.iconSize = 32,
    this.fontSize = 18,
    this.space = 4
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurface;
    return Row(
      spacing: space,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Icon(
          icon: icon,
          size: iconSize,
          color: color
        ),
        if (message != null)
          Text(
            message!,
            style: TextStyle(
              fontSize: fontSize,
              color: color
            )
          ),
      ],
    );
  }
  
}

class VerticalIconMessage extends StatelessWidget {

  final IconData icon;
  final String? message;
  final double iconSize;
  final double fontSize;
  final double space;

  const VerticalIconMessage({
    super.key,
    required this.icon,
    required this.message,
    required this.iconSize,
    required this.fontSize,
    this.space = 0
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurface;
    return Column(
      spacing: space,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Icon(
          icon: icon,
          size: iconSize,
          color: color
        ),
        if (message != null)
          Text(
            message!,
            style: TextStyle(
              fontSize: fontSize,
              color: color
            )
          ),
      ],
    );
  }
  
}

class _Icon extends StatelessWidget {

  final IconData icon;
  final double size;
  final Color color;

  final double offset;

  const _Icon({
    required this.icon,
    required this.size,
    required this.color
  }) :  offset = size / 10;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurface;
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(offset, offset),
          child: Icon(
            icon,
            size: size,
            color: color.withAlpha(25)
          )
        ),
        Icon(
          icon,
          size: size,
          color: Color.alphaBlend(
            color.withAlpha(150),
            colorScheme.surface
          )
        ),
      ],
    );
  }
}