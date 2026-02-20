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
      (community.platform.communityPrefix, prefixColor ?? theme.colorScheme.onSurfaceVariant),
      if (community.name != null)
        (community.name!, nameColor),
      if (community.platform.host == null) ...[
        ('@', theme.colorScheme.onSurfaceVariant),
        (community.host, nameColor)
      ]
    ];
    return applyAppBarAlpha ? MultiColoredAppBarTitle(texts: texts) : MultiColoredText(texts: texts);
  }

}

// class NameText extends StatelessWidget {

//   final String? before;
//   final String prefix;
//   final String? name;
//   final String? suffix;
//   final String? after;
//   final Color? beforeColor;
//   final Color? prefixColor;
//   final Color? nameColor;
//   final Color? suffixColor;
//   final Color? afterColor;
//   final bool applyAppBarAlpha;

//   const NameText({
//     super.key,
//     this.before,
//     required this.prefix,
//     this.name,
//     this.suffix,
//     this.after,
//     this.beforeColor,
//     this.prefixColor,
//     this.nameColor,
//     this.suffixColor,
//     this.afterColor,
//     this.applyAppBarAlpha = false
//   });

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('nameColor: ${this.nameColor}');
//     final theme = Theme.of(context);
//     Color beforeColor = this.beforeColor ?? theme.colorScheme.onSurfaceVariant;
//     Color prefixColor = this.prefixColor ?? theme.colorScheme.onSurfaceVariant;
//     Color nameColor = this.nameColor ?? theme.colorScheme.onSurface;
//     Color suffixColor = this.suffixColor ?? theme.colorScheme.onSurfaceVariant;
//     Color afterColor = this.afterColor ?? theme.colorScheme.onSurfaceVariant;
//     if (applyAppBarAlpha) {
//       final alpha = (DefaultTextStyle.of(context).style.color!.a * 255).toInt();
//       beforeColor = beforeColor.withAlpha(alpha);
//       prefixColor = prefixColor.withAlpha(alpha);
//       nameColor = nameColor.withAlpha(alpha);
//       suffixColor = suffixColor.withAlpha(alpha);
//       afterColor = afterColor.withAlpha(alpha);
//     }
//     return Text.rich(
//       maxLines: 1,
//       overflow: TextOverflow.ellipsis,
//       TextSpan(
//         children: [
//           if (before != null)
//             TextSpan(
//               text: before,
//               style: TextStyle(color: beforeColor)
//             ),
//           TextSpan(
//             text: prefix,
//             style: TextStyle(color: prefixColor),
//           ),
//           if (name != null)
//             TextSpan(
//               text: name,
//               style: TextStyle(color: nameColor),
//             ),
//           if (suffix != null)
//             TextSpan(
//               text: suffix,
//               style: TextStyle(color: suffixColor),
//             ),
//           if (after != null)
//             TextSpan(
//               text: after,
//               style: TextStyle(color: afterColor)
//             ),
//         ],
//       ),
//     );
//   }

// }

// class CommunityNameText extends StatelessWidget {

//   final Community community;
//   final Color? prefixColor;
//   final Color? nameColor;
//   final bool applyAppBarAlpha;

//   const CommunityNameText({
//     super.key,
//     required this.community,
//     this.prefixColor,
//     this.nameColor,
//     this.applyAppBarAlpha = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     String? prefix;
//     String? name;
//     String? suffix;
//     String? after;
//     if (community.name == null) {
//       if (community.platform.host != null) {
//         prefix = community.platform.communityPrefix;
//       }
//       else {
//         prefix = '${community.platform.communityPrefix}@';
//         name = community.host;
//       }
//     }
//     else {
//       prefix = community.platform.communityPrefix;
//       name = community.name;
//       if (community.platform.host == null) {
//         suffix = '@';
//         after = community.host;
//       }
//     }
//     final color = nameColor ?? Theme.of(context).colorScheme.onSurface;
//     return NameText(
//       prefix: prefix,
//       name: name,
//       suffix: suffix,
//       after: after,
//       prefixColor: prefixColor,
//       nameColor: color,
//       afterColor: color,
//       applyAppBarAlpha: applyAppBarAlpha,
//     );
//   }

// }