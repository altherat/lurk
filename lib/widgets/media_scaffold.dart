import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class MediaScaffold extends StatelessWidget {

  final PlatformContext platformContext;
  final String url;
  final Post? post;
  final String type;
  final Widget body;
  final void Function(BuildContext context)? onSave;

  const MediaScaffold({
    super.key,
    required this.platformContext,
    required this.url,
    this.post,
    required this.type,
    required this.body,
    required this.onSave
  });

  static Map<Widget, void Function(BuildContext context)> getOptions({
    required PlatformContext platformContext,
    required String type,
    required String url,
    Post? post,
    void Function(BuildContext context)? onSave,
  }) => {
    Text('Save $type'): ?onSave,
    if (post != null)
      Text('View comments'): (context) {
        context.push(() {
          return PostDetailsScreen.fromPost(
            platformContext: platformContext,
            post: post
          );
        });
      },
    Text('View in browser'): (context) => openInBrowser(url),
    Text('Copy link'): (context) => copyToClipboard(url)
  };

  @override
  Widget build(BuildContext context) {
    final Widget title;
    final Widget? subtitle;
    if (post != null) {
      title = Text(post!.title);
      subtitle = Text(post!.community.prefixedNameAndMaybeHost);
    }
    else {
      final uri = Uri.parse(url);
      title = Text('${uri.host}${uri.path}');
      subtitle = null;
    }
    return MainScaffold(
      platformContext: platformContext,
      title: title,
      subtitle: subtitle,
      popupMenuActions: getOptions(
        platformContext: platformContext,
        type: type,
        url: url,
        post: post,
        onSave: onSave
      ),
      body: body
    );
  }

}