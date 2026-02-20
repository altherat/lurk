import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class MediaScaffold extends StatelessWidget {

  final Community activeCommunity;
  final String url;
  final Post? post;
  final String type;
  final Widget body;
  final void Function(BuildContext context)? onSave;

  const MediaScaffold({
    super.key,
    required this.activeCommunity,
    required this.url,
    this.post,
    required this.type,
    required this.body,
    required this.onSave
  });

  static Map<Widget, void Function(BuildContext context)> getOptions({
    required BuildContext context,
    required Community activeCommunity,
    required String type,
    required String url,
    Post? post,
    void Function(BuildContext context)? onSave,
  }) => {
    Text('Save $type'): ?onSave,
    if (post != null)
      Text('View comments'): (context) => context.push(() => PostDetailsScreen.fromPost(activeCommunity: activeCommunity, post: post)),
    Text('View in browser'): (context) => openInBrowser(url),
    Text('Copy link'): (context) => copyToClipboard(url)
  };

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      activeCommunity: activeCommunity,
      title: post != null ? Text(post!.title) : null,
      subtitle: Text(post != null ? post!.community.fullName : url),
      popupMenuActions: getOptions(
        context: context,
        activeCommunity: activeCommunity,
        type: type,
        url: url,
        post: post,
        onSave: onSave
      ),
      body: body
    );
  }

}