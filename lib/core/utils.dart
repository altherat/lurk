import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/image_gallery_viewer.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/screens/video_viewer.dart';
import 'package:lurk/screens/web_viewer.dart';
import 'package:lurk/widgets/snack_bar_progress_content.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

String? getPlatformNameOrCommunityHost(Platform platform, Community? community) => platform.host != null || community == null ? platform.name.toTitleCase() : community.host;

Future<void> openInBrowser(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

Future navigate(BuildContext context, Community activeCommunity, String url, {Post? post}) async {
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
        activeCommunity: activeCommunity,
        url: url,
        post: post,
      )
    );
  }

  if (host == 'giphy.com' || host == 'www.giphy.com') {
    final directGiphyUrl = getGiphyDirectUrl(url);
    if (directGiphyUrl != null) {
      return context.push(
        () => ImageViewerScreen(
          activeCommunity: activeCommunity,
          url: directGiphyUrl,
          post: post,
        )
      );
    }
  }

  if (uri.host == 'v.redd.it' || pathLowerCase.endsWith('.mp4') || pathLowerCase.endsWith('.mov')) {
    return context.push(
      () => VideoViewerScreen(
        activeCommunity: activeCommunity,
        url: url,
        post: post
      )
    );
  }

  final resolvedPlatform = Platform.forHost(host);
  if (resolvedPlatform != null) {

    final communityName = resolvedPlatform.getCommunityNameFromPath(path);
    if (communityName != null) {
      final community = Community(
        platform: resolvedPlatform,
        host: host,
        name: communityName
      );
      return context.push(
        () => CommunityScreen(
          activeCommunity: activeCommunity.platform.supportsMultipleHosts ? activeCommunity : community,
          community: community
        )
      );
    }

    final userName = resolvedPlatform.getUserNameFromPath(path);
    if (userName != null) {
      return context.push(
        () => UserDetailsScreen(
          activeCommunity: activeCommunity,
          username: userName
        )
      );
    }

    final postUrlInfo = resolvedPlatform.getPostUrlInfoFromPath(path);
    if (postUrlInfo != null) {
      return context.push(
        () => PostDetailsScreen.fromUrl(
          activeCommunity: activeCommunity,
          platform: resolvedPlatform,
          host: host,
          url: url,
          urlInfo: postUrlInfo,
        )
      );
    }

    if (resolvedPlatform.isGallery(path)) {
      return context.push(
        () => ImageGalleryViewerScreen(
          activeCommunity: activeCommunity,
          platform: resolvedPlatform,
          host: host,
          post: post,
          url: url
        )
      );
    }

    if (resolvedPlatform.isUnresolved(path)) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        request.followRedirects = false; 
        request.headers.set('User-Agent', resolvedPlatform.savedOrDefaultUserAgent);
        final response = await request.close();
        if (response.statusCode == 301) {
          final resolvedUrl = response.headers.value('location');
          if (context.mounted && resolvedUrl != null) {
            return navigate(context, activeCommunity, resolvedUrl, post: post);
          }
        }
      }
      finally {
        client.close();
      }
    }
  }

  if (!context.mounted) return;

  return context.push(
    () => WebViewerScreen(
      activeCommunity: activeCommunity,
      post: post,
      url: url,
    )
  );
  
}

String? getGiphyDirectUrl(String url) {
  final match = RegExp(r'gifs\/(?:.*-)?([a-zA-Z0-9]{5,})').firstMatch(url);
  return match != null ? 'https://media.giphy.com/media/${match.group(1)}/giphy.webp' : null;
}

Future<void> showSimpleBottomSheet({
  required BuildContext context,
  String? title,
  required Widget body,
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: title != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                  ),
                  body
                ]
              )
            : body
        )
      );
    }
  );
}

Future<void> showSimpleTextBottomSheet({
  required BuildContext context,
  String? title,
  required String content
}) {
  return showSimpleBottomSheet(
    context: context,
    title: title,
    body: Text(
      content,
      style: Theme.of(context).textTheme.bodyLarge
    )
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
    isScrollControlled: true,
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

Future<void> showSimpleOptionsBottomSheet({
  required BuildContext context,
  String? title,
  required Map<Widget, void Function(BuildContext context)?> options
}) {
  return showOptionsBottomSheet(
    context: context,
    title: title,
    options: options.entries.map((entry) {
      return ListTile(
        title: entry.key,
        onTap: entry.value != null
        ? () {
            context.pop();
            entry.value?.call(context);
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
              dialogContext.pop();
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
    final filePath = await downloadMediaToTemp(url, platform.savedOrDefaultUserAgent);
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
    final filePath = await downloadMediaToTemp(url, platform.savedOrDefaultUserAgent);
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

String debugTruncateLongString(String? longString, [int maxLength = 10]) {
  if (longString == null) {
    return 'null';
  }
  return longString.length > maxLength ? '${longString.substring(0, maxLength ~/ 2)}...${longString.substring(longString.length - maxLength ~/ 2)}' : longString;
}