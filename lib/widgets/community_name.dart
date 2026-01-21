import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/services/settings.dart';

class CommunityName extends StatelessWidget {

  final Community community;
  final int? alpha;

  const CommunityName({
    super.key,
    required this.community,
    this.alpha
  });

  @override
  Widget build(BuildContext context) {
    final parentColor = DefaultTextStyle.of(context).style.color;
    final parentAlpha = (parentColor!.a * 255).toInt();
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorAccents,
      builder: (context, showPlatformColorAccents, child) {
        final displayName = community.displayName;
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: community.platform.communityPrefix,
                style: TextStyle(color: showPlatformColorAccents ? community.platform.color.withAlpha(alpha != null ? min(alpha!, parentAlpha) : parentAlpha) : parentColor.withAlpha(min(parentAlpha, Constants.communityPrefixAlpha))),
              ),
              if (displayName.isNotEmpty)
                TextSpan(
                  text: displayName,
                ),
            ],
          ),
        );
      }
    );
  }

}