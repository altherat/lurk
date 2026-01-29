import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/services/settings.dart';

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

// class PrefixedName extends StatelessWidget {

//   final String prefix;
//   final int? prefixAlpha;
//   final String name;

//   const PrefixedName({
//     super.key,
//     required this.prefix,
//     required this.prefixAlpha,
//     required this.name
//   });

//   @override
//   Widget build(BuildContext context) {
//     final parentColor = DefaultTextStyle.of(context).style.color;
//     final parentAlpha = (parentColor!.a * 255).toInt();
//     return Text.rich(
//       TextSpan(
//         children: [
//           TextSpan(
//             text: prefix,
//             style: TextStyle(color: parentColor.withAlpha(min(parentAlpha, Constants.namePrefixAlpha))),
//           ),
//           if (name.isNotEmpty)
//             TextSpan(
//               text: name,
//             ),
//         ],
//       ),
//     );
//   }
// }