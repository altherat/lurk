import 'package:flutter/material.dart';
import 'package:lurk/models/community.dart';

class MultiColoredText extends StatelessWidget {

  final List<(String, Color?)> texts;

  const MultiColoredText({
    super.key,
    required this.texts
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: texts.map((text) => TextSpan(text: text.$1, style: text.$2 != null ? TextStyle(color: text.$2) : null)).toList(),
      ),
    );
  }

}

class MultiColoredAppBarTitle extends StatelessWidget {

  final List<(String, Color?)> texts;

  const MultiColoredAppBarTitle({
    super.key,
    required this.texts
  });

  @override
  Widget build(BuildContext context) {
    final alpha = (DefaultTextStyle.of(context).style.color!.a * 255).toInt();
    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: texts.map((text) => TextSpan(text: text.$1, style: text.$2 != null ? TextStyle(color: text.$2?.withAlpha(alpha)) : null)).toList(),
      ),
    );
  }

}

class CommunityNameText extends StatelessWidget {

  final Community community;
  final Color? prefixColor;
  final Color? nameColor;
  final bool applyAppBarAlpha;

  const CommunityNameText({
    super.key,
    required this.community,
    this.prefixColor,
    this.nameColor,
    this.applyAppBarAlpha = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameColor = this.nameColor ?? theme.colorScheme.onSurface;
    final texts = [
      (community.platformContext.platform.preferredCommunityPrefix, prefixColor ?? theme.colorScheme.onSurfaceVariant),
      if (community.name != null)
        (community.name!, nameColor),
      if (community.platformContext.platform.supportsMultipleHosts) ...[
        ('@', theme.colorScheme.onSurfaceVariant),
        (community.platformContext.host, nameColor)
      ]
    ];
    return applyAppBarAlpha ? MultiColoredAppBarTitle(texts: texts) : MultiColoredText(texts: texts);
  }

}