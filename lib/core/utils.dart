import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
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
import 'package:lurk/screens/video_viewer.dart';
import 'package:lurk/screens/web_viewer.dart';
import 'package:lurk/widgets/snack_bar_progress_content.dart';
import 'package:path_provider/path_provider.dart';
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

  void pop() => Navigator.pop(this);

  Future<T?> push<T>(Widget Function() builder) {
    return Navigator.push<T>(
      this,
      // MaterialPageRoute(builder: (_) => builder())
      _PageRoute(builder: (_) => builder())
    );
  }

  // Future<T?> pushFadeThrough<T>(Widget Function() builder) {
  //   return Navigator.push<T>(
  //     this,
  //     PageRouteBuilder(
  //       transitionDuration: Constants.screenTransitionDuration,
  //       reverseTransitionDuration: Constants.reverseScreenTransitionDuration,
  //       pageBuilder: (context, animation, secondaryAnimation) => builder(),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         final curve = CurvedAnimation(
  //           parent: animation,
  //           curve: Curves.easeInOutCubicEmphasized,
  //         );
  //         return FadeTransition(
  //           opacity: curve,
  //           child: ScaleTransition(
  //             alignment: Alignment.center, 
  //             scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
  //             child: child,
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar({Duration duration = const Duration(seconds: 4), required Widget content, SnackBarAction? action}) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        duration: duration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        content: content,
        action: action
      )
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBarMessage(String text) => showSnackBar(content: Text(text));

}

class _PageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  
  _PageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
  });

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => Constants.screenTransitionDuration;

  @override
  Duration get reverseTransitionDuration => Constants.reverseScreenTransitionDuration;
  
}

Future<void> openInBrowser(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

Future navigate(BuildContext context, Platform platform, String url, {Post? post}) async {
  // dev.log('navigate: $url');
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  var host = uri.host;
  if (host.isEmpty) return;

  host = host.toLowerCase();

  final path = uri.path;
  final pathLowerCase = path.toLowerCase();

  if (host == 'i.redd.it' || host.endsWith('.imgix.net') || pathLowerCase.endsWith('.jpg') || pathLowerCase.endsWith('.jpeg') || pathLowerCase.endsWith('.png') || pathLowerCase.endsWith('.gif') || pathLowerCase.endsWith('.webp')) {
    return context.push(
      () => ImageViewerScreen(
        platform: platform,
        url: url,
        post: post,
      )
    );
  }

  if (host == 'giphy.com' || host == 'www.giphy.com') {
    final match = RegExp(r'gifs\/(?:.*-)?([a-zA-Z0-9]{5,})').firstMatch(url);
    if (match != null) {
      return context.push(
        () => ImageViewerScreen(
          platform: platform,
          url: 'https://media.giphy.com/media/${match.group(1)}/giphy.webp',
          post: post,
        )
      );
    }
  }

  if (uri.host == 'v.redd.it' || pathLowerCase.endsWith('.mp4') || pathLowerCase.endsWith('.mov')) {
    return context.push(
      () => VideoViewerScreen(
        platform: platform,
        url: url,
        post: post
      )
    );
  }

  final resolvedPlatform = Platform.forHost(host);
  if (resolvedPlatform != null) {

    final communityName = resolvedPlatform.getCommunityNameFromPath(path);
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

    final userName = resolvedPlatform.getUserNameFromPath(path);
    if (userName != null) {
      return context.push(
        () => UserDetailsScreen(
          platform: resolvedPlatform,
          username: userName
        )
      );
    }

    final postUrlInfo = resolvedPlatform.getPostUrlInfoFromPath(path);
    if (postUrlInfo != null) {
      return context.push(
        () => PostDetailsScreen.fromUrl(
          platform: resolvedPlatform,
          url: url,
          urlInfo: postUrlInfo,
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

    if (resolvedPlatform.isUnresolved(path)) {
      final resolvedUrl = await resolvedPlatform.api.resolveUrl(url);
      if (context.mounted && resolvedUrl != null) {
        return navigate(context, platform, resolvedUrl, post: post);
      }
    }

  }

  if (!context.mounted) return;

  return context.push(
    () => WebViewerScreen(
      platform: platform,
      post: post,
      url: url,
    )
  );
  
}

Future<void> showSimpleTextBottomSheet({
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

Future<void> showOptionsBottomSheet({
  required BuildContext context,
  String? title,
  required Iterable<Widget> options,
  EdgeInsetsGeometry? padding
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
                padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ...options
          ]
        ),
      );
    }
  );
}

Future<void> showSimpleTextOptionsBottomSheet({
  required BuildContext context,
  String? title,
  required Map<String, VoidCallback?> options
}) {
  return showOptionsBottomSheet(
    context: context,
    title: title,
    options: options.entries.map((entry) {
      return ListTile(
        title: Text(entry.key),
        onTap: entry.value != null
        ? () {
            context.pop();
            entry.value?.call();
          }
        : null
      );
    })
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

Future<String> downloadMediaToTemp(String path, String userAgent) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(path);
    client.connectionTimeout = const Duration(seconds: 10);
    final request = await client.getUrl(uri);
    request.headers.set('User-Agent', userAgent);
    final response = await request.close();
    final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${uri.pathSegments.last}');
    await file.writeAsBytes(bytes);
    return file.path;
  }
  catch (e) {
    rethrow;
  }
  finally {
    client.close();
  }
}

Future<void> saveImage({
  required BuildContext context,
  required Platform platform,
  required String url,
}) => saveMedia(
  context: context,
  platform: platform,
  snackbarMediaTypeMessage: 'image',
  save: () async {
    final filePath = await downloadMediaToTemp(url, platform.api.savedOrDefaultUserAgent);
    await Gal.putImage(filePath);
  }
);

Future<void> saveVideo({
  required BuildContext context,
  required Platform platform,
  required String url,
}) => saveMedia(
  context: context,
  platform: platform,
  snackbarMediaTypeMessage: 'video',
  save: () async {
    final filePath = await downloadMediaToTemp(url, platform.api.savedOrDefaultUserAgent);
    await Gal.putVideo(filePath);
  }
);

Future<void> saveMedia({
  required BuildContext context,
  required Platform platform,
  required String snackbarMediaTypeMessage,
  required Future<void> Function() save
}) async {
  if (!await Gal.hasAccess()) {
    if (!await Gal.requestAccess()) {
      if (context.mounted) {
        context.showSnackBarMessage('Permission denied — could not save $snackbarMediaTypeMessage');
      }
      return;
    }
  }

  if (!context.mounted) return;

  final future = save();
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;
  controller = context.showSnackBar(
    duration: const Duration(days: 1),
    content: SnackBarProgressContent(
      platform: platform,
      progressMessage: 'Saving $snackbarMediaTypeMessage...',
      completeMessage: 'Successfully saved',
      errorMessage: 'Something went wrong',
      future: future,
      onComplete: () async {
        await Future.delayed(const Duration(seconds: 4));
        if (context.mounted) {
          controller?.close();
        }
      }
    ),
    action: SnackBarAction(
      label: 'Cancel',
      onPressed: () => controller?.close()
    )
  );

}

final alphaNumericRegex = RegExp(r'[a-zA-Z0-9]');
Set<String> hexEscape(String string) {
  final Set<String> escaped = {};
  for (final char in string.runes) {
    final s = String.fromCharCode(char);
    if (!alphaNumericRegex.hasMatch(s)) {
      escaped.add('\\x${char.toRadixString(16).padLeft(2, '0')}');
    }
  }
  return escaped;
}