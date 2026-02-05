import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/services/settings.dart';

class PrefixedName extends StatelessWidget {

  final String prefix;
  final String? name;
  final TextSpan? before;
  final TextSpan? after;

  const PrefixedName({
    super.key,
    required this.prefix,
    required this.name,
    this.before,
    this.after
  });

  @override
  Widget build(BuildContext context) {
    final parentColor = DefaultTextStyle.of(context).style.color;
    final parentAlpha = (parentColor!.a * 255).toInt();
    return Text.rich(
      TextSpan(
        children: [
          ?before,
          TextSpan(
            text: prefix,
            style: TextStyle(color: parentColor.withAlpha(min(parentAlpha, Constants.namePrefixAlpha))),
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

class PrefixedCommunityName extends StatelessWidget {

  final Community community;
  final int? alpha;

  const PrefixedCommunityName({
    super.key,
    required this.community,
    this.alpha
  });

  @override
  Widget build(BuildContext context) {
    final parentColor = DefaultTextStyle.of(context).style.color;
    final parentAlpha = (parentColor!.a * 255).toInt();
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorTextAccents,
      builder: (context, showPlatformColorTextAccents, child) {
        final prefixColor = showPlatformColorTextAccents ? community.platform.color.withAlpha(alpha != null ? min(alpha!, parentAlpha) : parentAlpha) : parentColor.withAlpha(min(parentAlpha, Constants.namePrefixAlpha));
        if (community.name == null) {
          return Text(
            community.platform.communityPrefix,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: prefixColor),
          );
        }
        return Text.rich(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          TextSpan(
            children: [
              TextSpan(
                text: community.platform.communityPrefix,
                style: TextStyle(color: prefixColor),
              ),
              TextSpan(
                text: community.name!,
              ),
            ],
          ),
        );
      }
    );
  }

}