import 'dart:io';
import 'dart:io' as io;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:lurk/app.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api.dart';
import 'package:lurk/services/communities.dart';
import 'package:lurk/screens/image_gallery_viewer.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/screens/video_viewer.dart';
import 'package:lurk/screens/web_viewer.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/snack_bar_progress_content.dart';
import 'package:path_provider/path_provider.dart';

ApiService getApi(PlatformContext platformContext, LoggedInUser? activeUser) => activeUser != null ? Platform.getApi(activeUser.platform, activeUser.host, activeUser.id) : Platform.getApi(platformContext.platform, platformContext.host, null);

Future<void> openInBrowser(String url) async {
  if (io.Platform.isAndroid) {
    final String? defaultBrowserPackageName = await MethodChannel('lurk/navigation').invokeMethod('getDefaultBrowserPackageName');
    if (defaultBrowserPackageName != null) {
      return AndroidIntent(
        action: 'action_view',
        data: url,
        package: defaultBrowserPackageName,
      ).launch();
    }
  }
}

Future<T?> navigateUri<T>(BuildContext context, Uri uri) async {

  final url = uri.toString();

  String getHost(Platform platform) => platform.preferredHost ?? uri.host.toLowerCase().replaceFirst('www.', '');

  for (final platform in F.appFlavor.platforms) {

    if (platform.communityUrlRegex != null) {
      final match = RegExp(platform.communityUrlRegex!).firstMatch(url);
      if (match != null) {
        return navigatorKey.currentContext?.push(() {
          return CommunityScreen(
            community: Community(
              platform: platform,
              host: getHost(platform),
              name: match.namedGroup('communityName')?.toLowerCase()
            )
          );
        });
      }
    }

    if (platform.postDetailsUrlRegex != null) {
      final match = RegExp(platform.postDetailsUrlRegex!).firstMatch(url);
      if (match != null) {
        final host = getHost(platform);
        return navigatorKey.currentContext?.push(() {
          return PostDetailsScreen.fromUrl(
            platformContext: PlatformContext(
              platform: platform,
              host: host,
            ),
            community: Community(
              platform: platform,
              host: _getNamedGroupIfPresent(match, 'communityHostName') ?? host,
              name: _getNamedGroupIfPresent(match, 'communityName')?.toLowerCase()
            ),
            url: url,
            postId: match.namedGroup('postId')!,
            contextCommentShortId: _getNamedGroupIfPresent(match, 'commentId'),
            titleSlug: _getNamedGroupIfPresent(match, 'slug'),
          );
        });
      }
    }

    if (platform.userDetailsUrlRegex != null) {
      final match = RegExp(platform.userDetailsUrlRegex!).firstMatch(url);
      if (match != null) {
        final host = getHost(platform);
        return navigatorKey.currentContext?.push(() {
          return UserDetailsScreen(
            platformContext: PlatformContext(
              platform: platform,
              host: host,
            ),
            user: User(
              platform: platform,
              host: _getNamedGroupIfPresent(match, 'userHostName') ?? host,
              name: match.namedGroup('userName')!,
            )
          );
        });
      }
    }

    if (platform.imageUrlRegex != null) {
      final match = RegExp(platform.imageUrlRegex!).firstMatch(url);
      if (match != null) {
        return navigatorKey.currentContext?.push(() {
          return ImageViewerScreen(
            platformContext: PlatformContext(
              platform: platform,
              host: getHost(platform),
            ),
            url: url,
          );
        });
      }
    }

    if (platform.videoUrlRegex != null) {
      final match = RegExp(platform.videoUrlRegex!).firstMatch(url);
      if (match != null) {
        return navigatorKey.currentContext?.push(() {
          return VideoViewerScreen(
            platformContext: PlatformContext(
              platform: platform,
              host: getHost(platform),
            ),
            url: url,
          );
        });
      }
    }

    if (platform.imageGalleryUrlRegex != null) {
      final match = RegExp(platform.imageGalleryUrlRegex!).firstMatch(url);
      if (match != null) {
        return navigatorKey.currentContext?.push(() {
          return ImageGalleryViewerScreen(
            platformContext: PlatformContext(
              platform: platform,
              host: getHost(platform),
            ),
            url: url,
            postId: match.namedGroup('postId')!,
          );
        });
      }
    }

    if (platform.unresolvedPostDetailsUrlRegex != null) {
      final match = RegExp(platform.unresolvedPostDetailsUrlRegex!).firstMatch(url);
      if (match != null) {
        final resolvedUrl = await _resolveUrlFromRedirect(platform, url);
        if (resolvedUrl != null) {
          if (context.mounted) {
            return navigateUri<T>(context, Uri.parse(resolvedUrl));
          }
        }
      }
    }
    
  }

  return null;
}

Future<T?> navigateWithContext<T>(BuildContext context, PlatformContext platformContext, String url, {Post? post}) async {

  final uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }

  var host = uri.host;
  if (host.isEmpty) {
    return null;
  }

  host = host.toLowerCase();
  final path = uri.path;
  final pathLowerCase = path.toLowerCase();

  if (pathLowerCase.endsWith('.jpg') || pathLowerCase.endsWith('.jpeg') || pathLowerCase.endsWith('.png') || pathLowerCase.endsWith('.gif') || pathLowerCase.endsWith('.webp')) {
    return context.push(() {
      return ImageViewerScreen(
        platformContext: platformContext,
        url: url,
        post: post,
        size: post?.mediaSize
      );
    });
  }

  if (pathLowerCase.endsWith('.mp4') || pathLowerCase.endsWith('.mov')) {
    return context.push(() {
      return VideoViewerScreen(
        platformContext: platformContext,
        url: url,
        post: post
      );
    });
  }

  final hostWithoutWww = host.replaceFirst('www.', '');

  if (hostWithoutWww == 'giphy.com') {
    final directGiphyUrl = getGiphyDirectUrl(url);
    if (directGiphyUrl != null) {
      return context.push(() {
        return ImageViewerScreen(
          platformContext: platformContext,
          url: directGiphyUrl,
          post: post,
          size: post?.mediaSize
        );
      });
    }
  }

  bool matchesHost(String host) => host == hostWithoutWww || host.replaceFirst('www.', '') == hostWithoutWww;

  final Platform? resolvedPlatform = matchesHost(platformContext.host) ? platformContext.platform
    : Platform.values.firstWhereOrNull((platform) => platform.hosts?.any((host) => matchesHost(host)) ?? false)
    ?? Communities.saved.value.firstWhereOrNull((community) => matchesHost(community.host))?.platform
    ?? UserManager.loggedInUsersListenable.value.firstWhereOrNull((user) => matchesHost(user.host))?.platform;

  if (resolvedPlatform != null) {

    RegExpMatch? match = RegExp(resolvedPlatform.communityPathRegex).firstMatch(path);
    if (match != null) {
      return context.push(() {
        return CommunityScreen(
          community: Community(
            platform: resolvedPlatform,
            host: _getNamedGroupIfPresent(match!, 'communityHostName') ?? host,
            name: match.namedGroup('communityName')!.toLowerCase(),
          )
        );
      });
    }

    match = RegExp(resolvedPlatform.userDetailsPathRegex).firstMatch(path);
    if (match != null) {
      host = _getNamedGroupIfPresent(match, 'userHostName') ?? host;
      return context.push(() {
        return UserDetailsScreen(
          platformContext: PlatformContext(
            platform: resolvedPlatform,
            host: host,
          ),
          user: User(
            platform: resolvedPlatform,
            host: host,
            name: match!.namedGroup('userName')!,
          )
        );
      });
    }

    match = RegExp(resolvedPlatform.postDetailsPathRegex).firstMatch(path);
    if (match != null) {
      return context.push(() {
        return PostDetailsScreen.fromUrl(
          platformContext: PlatformContext(
            platform: resolvedPlatform,
            host: host,
          ),
          community: Community(
            platform: resolvedPlatform,
            host: host,
            name: _getNamedGroupIfPresent(match!, 'communityName')?.toLowerCase(),
          ),
          url: url,
          postId: match.namedGroup('postId')!,
          contextCommentShortId: _getNamedGroupIfPresent(match, 'commentId'),
          titleSlug: _getNamedGroupIfPresent(match, 'slug')
        );
      });
    }

    if (resolvedPlatform.imageGalleryPathRegex != null) {
      match = RegExp(resolvedPlatform.imageGalleryPathRegex!).firstMatch(path);
      if (match != null) {
        return context.push(() {
          return ImageGalleryViewerScreen(
            platformContext: PlatformContext(
              platform: resolvedPlatform,
              host: _getNamedGroupIfPresent(match!, 'hostName') ?? host,
            ),
            postId: match.namedGroup('postId')!,
            url: url
          );
        });
      }
    }

    if (resolvedPlatform.unresolvedPostDetailsPathRegex != null) {
      match = RegExp(resolvedPlatform.unresolvedPostDetailsPathRegex!).firstMatch(path);
      if (match != null) {
        final resolvedUrl = await _resolveUrlFromRedirect(resolvedPlatform, url);
        if (resolvedUrl != null && context.mounted) {
          return navigateWithContext<T>(context, platformContext, resolvedUrl);
        }
      }
    }
    
  }

  if (!context.mounted) {
    return null;
  }

  return context.push(() {
    return WebViewerScreen(
      platformContext: platformContext,
      post: post,
      url: url,
    );
  });
  
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
  required Platform? platform,
  required String url,
}) => saveMedia(
  context: context,
  snackbarMediaTypeMessage: 'image',
  save: () async {
    final filePath = await downloadMediaToTemp(url, platform?.savedOrDefaultUserAgent ?? Constants.defaultUserAgent);
    await Gal.putImage(filePath);
  }
);

Future<void> saveVideo({
  required BuildContext context,
  required Platform platform,
  required String url,
}) => saveMedia(
  context: context,
  snackbarMediaTypeMessage: 'video',
  save: () async {
    final filePath = await downloadMediaToTemp(url, platform.savedOrDefaultUserAgent);
    await Gal.putVideo(filePath);
  }
);

Future<void> saveMedia({
  required BuildContext context,
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

String? _getNamedGroupIfPresent(RegExpMatch match, String name) => match.groupNames.contains(name) ? match.namedGroup(name) : null;

Future<String?> _resolveUrlFromRedirect(Platform platform, String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.followRedirects = false; 
    request.headers.set('User-Agent', platform.savedOrDefaultUserAgent);
    final response = await request.close();
    if (response.statusCode == 301) {
      return response.headers.value('location');
    }
  }
  finally {
    client.close();
  }
  return null;
}