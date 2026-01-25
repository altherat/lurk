import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/image_gallery_viewer.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/screens/video_player.dart';
import 'package:lurk/screens/web_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

final _commaFormatter = NumberFormat.decimalPattern();

extension NumExtension on num {

  String toCommaString() => _commaFormatter.format(this);

  String toPluralString(String plural)  => this == 1 ? '1 $plural' : '${toCommaString()} ${plural}s';
  
}

extension StringExtension on String {

  String toPosessive() => endsWith('s') || endsWith('S') ? "$this'" : "$this's";
  
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Color? toColor() {
    final trimmed = trim();
    try {
      return trimmed.length == 6 ? Color(int.parse('FF$trimmed', radix: 16)) : trimmed.length == 8 ? Color(int.parse(trimmed, radix: 16)) : null;
    } catch (_) {
      return null;
    }
  }
  
}

extension DateTimeExtension on DateTime {

  String get timeAgo => _timeAgo(false);

  String get timeAgoLong => _timeAgo(true);

  String get timeAgoCompact {
    final Duration diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    if (diff.inDays < 30)    return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365)   return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  String _timeAgo(bool showAgo) {
    final Duration diff = DateTime.now().difference(this);
    final thresholds = {
      'year': 31536000,
      'month': 2592000,
      'week': 604800,
      'day': 86400,
      'hour': 3600,
      'minute': 60,
      'second': 1,
    };

    for (var entry in thresholds.entries) {
      final int count = diff.inSeconds ~/ entry.value;
      if (count >= 1) {
        final String unit = '$count ${entry.key}${count == 1 ? '' : 's'}';
        return showAgo ? '$unit ago' : unit;
      }
    }
    return 'just now';
  }

}

extension ColorExtension on Color {
  
  String toHex() => toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  String toCss() => '#${toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

  Color get contrast => computeLuminance() > 0.5 ? Colors.black : Colors.white;
  
}

extension BuildContextExtension on BuildContext {

  Future<T?> push<T>(Widget Function() builder) {
    return Navigator.push<T>(
      this,
      _PageRoute(builder: (_) => builder()),
    );
  }

  // Future<T?> push<T>(Widget Function() builder) {
  //   return Navigator.push<T>(
  //     this,
  //     MaterialPageRoute(builder: (_) => builder()),
  //   );
  // }

}

class _PageRoute<T> extends MaterialPageRoute<T> {

  _PageRoute({required super.builder});

  @override
  Duration get transitionDuration => Constants.pageTransitionDuration;

  @override
  Duration get reverseTransitionDuration => Constants.pageTransitionDuration;

}

Future<void> openInBrowser(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

Future navigate(BuildContext context, Platform platform, String url, {Post? post}) async {
  // debugPrint('navigate: $url');
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  final host = uri.host;
  if (host.isEmpty) return;

  final path = uri.path.toLowerCase();

  if (host == 'i.redd.it' || host.endsWith('.imgix.net') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.gif') || path.endsWith('.webp')) {
    return context.push(
      () => ImageViewerScreen(
        url: url,
        post: post,
      )
    );
  }

  if (uri.host == 'v.redd.it') {
    return context.push(
      () => VideoPlayerScreen(
        platform: platform,
        url: uri.replace(
          path: '/${uri.pathSegments.first}/DASHPlaylist.mpd',
          queryParameters: {},
          fragment: null,
        ).toString(),
        post: post,
      )
    );
  }
  if (path.endsWith('.mp4') || path.endsWith('.mov')) {
    return context.push(
      () => VideoPlayerScreen(
        platform: platform,
        url: url,
        post: post
      )
    );
  }

  final resolvedPlatform = Platform.forHost(host);
  if (resolvedPlatform != null) {

    final communityName = resolvedPlatform.getCommunityName(path);
    if (communityName != null) {
      return context.push(
        () => PostsScreen(
          community: Community(
            platform: resolvedPlatform,
            name: communityName
          )
        )
      );
    }

    final userName = resolvedPlatform.getUserName(path);
    if (userName != null) {
      return context.push(
        () => UserDetailsScreen(
          platform: resolvedPlatform,
          username: userName
        )
      );
    }

    if (resolvedPlatform.isPostDetails(path)) {
      return context.push(
        () => PostDetailsScreen.fromUrl(
          platform: resolvedPlatform,
          url: url
        )
      );
    }

    if (resolvedPlatform.isGallery(path)) {
      return context.push(
        () => ImageGalleryViewerScreen(
          platform: resolvedPlatform,
          post: post,
          url: url
        )
      );
    }

  }

  return context.push(
    () => WebViewerScreen(
      platform: platform,
      post: post,
      url: url,
    )
  );

  // if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
  //   return true;
  // }
  // else if (context.mounted) {
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong')));
  // }
}

Future<void> showSimpleAlertDialog({
  required BuildContext context,
  String? title,
  required String content
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(content),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context)
          ),
        ]
      );
    }
  );
}

Future<void> showSimpleBottomSheet({
  required BuildContext context,
  String? title,
  required String content
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (dialogContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Text(
            content,
            style: TextStyle(fontSize: 18)
          ),
        )
      );
    }
  );
}

Future<void> showSimpleOptionsBottomSheet({
  required BuildContext context,
  String? title,
  required Map<String, VoidCallback> options
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ...options.entries.map((option) {
              return ListTile(
                title: Text(option.key),
                onTap: () {
                  Navigator.pop(context);
                  option.value();
                }
              );
            })
          ]
        ),
      );
    }
  );
}

Future<void> showSimpleOptionsDialog({
  required BuildContext context,
  String? title,
  required Map<String, VoidCallback> options
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        title: title == null ? null : Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: options.entries.map((entry) {
          return SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () {
              Navigator.pop(dialogContext);
              entry.value();
            },
            child: Text(
              entry.key,
              style: TextStyle(
                fontSize: 16
              ),
            ),
          );
        }).toList()
      );
    },
  );
}

Future<void> copyToClipboard(String text) => Clipboard.setData(ClipboardData(text: text));