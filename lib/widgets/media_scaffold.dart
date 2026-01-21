import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaScaffold extends StatelessWidget {

  final String url;
  final String type;
  final Community? community;
  final Post? post;
  final Widget body;

  const MediaScaffold({
    super.key,
    required this.url,
    required this.type,
    this.community,
    this.post,
    required this.body
  });

  @override
  Widget build(BuildContext context) {
    final options = {
      'Save $type': () {}, //TODO
      if (post != null)
        'View comments': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return PostDetailsScreen(
                  community: community!,
                  post: post,
                  url: url
                );
              }
            )
          );
        },
      'View in browser': () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
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