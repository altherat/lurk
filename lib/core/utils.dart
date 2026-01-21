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
import 'package:lurk/screens/video_player.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

final _commaFormatter = NumberFormat.decimalPattern();

extension IntExtension on int {

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

extension ColorExtension on Color {
  
  String toHex() => toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  String toCss() => '#${toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

  Color get contrast => computeLuminance() > 0.5 ? Colors.black : Colors.white;
  
}

String timeAgo(int timestampMs) {
  final Duration diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
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
      return '$count ${entry.key}${count == 1 ? '' : 's'} ago';
    }
  }
  return 'just now';
}

String timeAgoCompact(int timestampMs) {
  final Duration diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24)   return '${diff.inHours}h';
  if (diff.inDays < 7)     return '${diff.inDays}d';
  if (diff.inDays < 30)    return '${(diff.inDays / 7).floor()}w';
  if (diff.inDays < 365)   return '${(diff.inDays / 30).floor()}mo';
  return '${(diff.inDays / 365).floor()}y';
}

Future<bool> navigate(BuildContext context, String url, {Community? community, Post? post}) async {
  // debugPrint('navigate: $url');
  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (host == 'i.redd.it' || host.endsWith('.imgix.net') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.gif') || path.endsWith('.webp')) {
    Navigator.push(
      context, MaterialPageRoute(
        builder: (_) {
          return ImageViewerScreen(
            url: url,
            community: community,
            post: post,
          );
        }
      )
    );
    return true;
  }

  if (uri.host == 'v.redd.it') {
    Navigator.push(
      context, MaterialPageRoute(
        builder: (_) {
          return VideoPlayerScreen(
            url: '$url/HLSPlaylist.m3u8',
            community: community,
            post: post,
          );
        }
      )
    );
    return true;
  }
  
  if (path.endsWith('.mp4') || path.endsWith('.mov')) {
    Navigator.push(
      context, MaterialPageRoute(
        builder: (_) {
          return VideoPlayerScreen(
            url: url,
            community: community,
            post: post
          );
        }
      )
    );
    return true;
  }

  if (host == 'reddit.com' || host == 'redd.it' || host.endsWith('.reddit.com') || host.endsWith('.redd.it')) {
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final firstPathSegment = pathSegments[0].toLowerCase();
      if (firstPathSegment == 'r') {
        if (pathSegments.length == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return PostsScreen(
                  community: Community(
                    platform: Platform.reddit,
                    name: pathSegments[1].toLowerCase()
                  )
                );
              }
            )
          );
          return true;
        }
        if (pathSegments[2] == 'comments' && pathSegments.length >= 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return PostDetailsScreen(
                  community: Community(
                    platform: Platform.reddit,
                    name: pathSegments[1].toLowerCase()
                  ),
                  post: post,
                  url: url
                );
              }
            )
          );
          return true;
        }
      }
      else if ((firstPathSegment == 'u' || firstPathSegment == 'user')) {
        if (pathSegments.length >= 2) {
          final username = pathSegments[1];
          // TODO: Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(username: username)));
          return true;
        }
      }
      else if (firstPathSegment == 'gallery') {
        if (pathSegments.length == 2) {
          Navigator.push(
            context, MaterialPageRoute(
              builder: (_) {
                return ImageGalleryViewerScreen(
                  url: url,
                  platform: Platform.reddit,
                  community: community,
                  post: post,
                );
              }
            )
          );
          return true;
        }
      }
    }
  }

  if (host == 'digg.com' || host == 'www.digg.com') {
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2) {
      final communityName = pathSegments[0].toLowerCase();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailsScreen(
            community: Community(
              platform: Platform.digg,
              name: communityName,
            ),
            post: post, // If we have the object from a list, pass it
            url: url,
            // You might want to ensure your screen can load via ID if post is null
            // id: postId, 
          ),
        ),
      );
      return true;
    }
  }

  if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
    return true;
  }
  else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong')));
  }

  return false;
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