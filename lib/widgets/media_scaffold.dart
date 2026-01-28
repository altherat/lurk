import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class MediaScaffold extends StatelessWidget {

  final Platform platform;
  final String url;
  final String type;
  final Post? post;
  final Widget body;
  final VoidCallback onSave;

  const MediaScaffold({
    super.key,
    required this.platform,
    required this.url,
    required this.type,
    this.post,
    required this.body,
    required this.onSave
  });

  @override
  Widget build(BuildContext context) {
    final options = {
      'Save $type': onSave,
      if (post != null)
        'View comments': () => context.push(() => PostDetailsScreen.fromPost(post: post!)),
      'View in browser': () => openInBrowser(url),
      'Copy link': () => copyToClipboard(url)
    };
    return MainScaffold(
      platform: platform,
      title: post != null ? Text(post!.title) : null,
      subtitle: Text(url),
      popupMenuActions: options,
      body: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          showSimpleTextOptionsBottomSheet(
            context: context,
            options: options
          );
        },
        child: body
      )
    );
  }

}