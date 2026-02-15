import 'package:flutter/material.dart';

class PrefixedName extends StatelessWidget {

  final String prefix;
  final String? name;
  final TextSpan? before;
  final TextSpan? after;
  final Color? prefixColor;
  final bool applyAppBarAlpha;

  const PrefixedName({
    super.key,
    required this.prefix,
    required this.name,
    this.before,
    this.after,
    this.prefixColor,
    this.applyAppBarAlpha = false
  });

  @override
  Widget build(BuildContext context) {
    Color prefixColor = this.prefixColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    if (applyAppBarAlpha) {
      prefixColor = prefixColor.withAlpha((DefaultTextStyle.of(context).style.color!.a * 255).toInt());
    }
    return Text.rich(
      TextSpan(
        children: [
          ?before,
          TextSpan(
            text: prefix,
            style: TextStyle(color: prefixColor),
          ),
          if (name != null && name!.isNotEmpty)
            TextSpan(
              text: name,
            ),
          ?after
        ],
      ),
    );
  }

}