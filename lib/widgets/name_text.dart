import 'package:flutter/material.dart';
import 'package:lurk/models/community.dart';

class NameText extends StatelessWidget {

  final String? name;
  final String prefix;
  final String? suffix;
  final String? before;
  final String? after;
  final Color? color;
  final Color? prefixColor;
  final Color? suffixColor;
  final bool applyAppBarAlpha;

  const NameText({
    super.key,
    required this.name,
    required this.prefix,
    this.suffix,
    this.before,
    this.after,
    this.color,
    this.prefixColor,
    this.suffixColor,
    this.applyAppBarAlpha = false
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color prefixColor = this.prefixColor ?? theme.colorScheme.onSurfaceVariant;
    Color suffixColor = this.suffixColor ?? theme.colorScheme.onSurfaceVariant;
    if (applyAppBarAlpha) {
      prefixColor = prefixColor.withAlpha((DefaultTextStyle.of(context).style.color!.a * 255).toInt());
      suffixColor = suffixColor.withAlpha((DefaultTextStyle.of(context).style.color!.a * 255).toInt());
    }
    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: [
          if (before != null)
            TextSpan(text: before),
          TextSpan(
            text: prefix,
            style: TextStyle(color: prefixColor),
          ),
          if (name != null)
            TextSpan(
              text: name,
              style: TextStyle(color: color),
            ),
          if (suffix != null)
            TextSpan(
              text: suffix,
              style: TextStyle(color: suffixColor),
            ),
          if (after != null)
            TextSpan(text: after),
        ],
      ),
    );
  }

}

class CommunityNameText extends StatelessWidget {

  final Community community;
  final String? before;
  final String? after;
  final Color? prefixColor;
  final bool applyAppBarAlpha;

  const CommunityNameText({
    super.key,
    required this.community,
    this.before,
    this.after,
    this.prefixColor,
    this.applyAppBarAlpha = false,
  });

  @override
  Widget build(BuildContext context) {
    return NameText(
      name: community.name,
      prefix: community.platform.communityPrefix,
      suffix: community.platform.host == null ? '@${community.host}' : null,
      before: before,
      after: after,
      prefixColor: prefixColor,
      applyAppBarAlpha: applyAppBarAlpha,
    );
  }

}