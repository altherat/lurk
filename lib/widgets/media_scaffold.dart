import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class MediaScaffold extends StatelessWidget {

  final String url;
  final String type;
  final Post? post;
  final Widget body;

  const MediaScaffold({
    super.key,
    required this.url,
    required this.type,
    this.post,
    required this.body
  });

  @override
  Widget build(BuildContext context) {
    final options = {
      'Save $type': () {
        //TODO
      },
      if (post != null)
        'View comments': () {
          context.push(
            () => PostDetailsScreen(
              post: post,
              url: Api.of(post!.community.platform).getPostDetailsUrl(post!),
            )
          );
        },
      'View in browser': () => openInBrowser(url),
      'Copy link': () => copyToClipboard(url)
    };
    return MainScaffold(
      title: post != null ? Text(post!.title) : null,
      subtitle: Text(url),
      popupMenuActions: options,
      body: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          showSimpleOptionsBottomSheet(
            context: context,
            options: options
          );
        },
        child: body
      )
    );
  }

}