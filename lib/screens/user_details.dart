import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/feed_screen.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/widgets/centered_scroll_view.dart';
import 'package:lurk/widgets/history_builder.dart';
import 'package:lurk/widgets/html.dart';
import 'package:lurk/widgets/large_message.dart';
import 'package:lurk/widgets/post_tile.dart';

class UserDetailsScreen extends StatelessWidget {

  final Platform platform;
  final String username;

  const UserDetailsScreen({
    super.key,
    required this.platform,
    required this.username
  });

  @override
  Widget build(BuildContext context) {
    return FeedScreen(
      platform: platform,
      feedOptions: platform.userFeedOptions,
      title: Builder(
        builder: (context) {
          final parentColor = DefaultTextStyle.of(context).style.color;
          final parentAlpha = (parentColor!.a * 255).toInt();
          return Text.rich(
            TextSpan(
              // style: baseStyle,
              children: [
                TextSpan(
                  text: platform.userPrefix,
                  style: TextStyle(color: parentColor.withAlpha(min(parentAlpha, Constants.namePrefixAlpha)))
                ),
                TextSpan(text: username),
              ],
            ),
          );
        }
      ),
      get: (options, pageToken) => Api.of(platform).getUserItems(username, options: options, pageToken: pageToken),
      itemBuilder: (context, item) { 
        if (item is Post) {
          return PostTile(
            post: item,
            subtitle: HistoryBuilder(
              id: item.id,
              history: History.postDetails,
              builder: (context, isVisited) {
                return Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Constants.secondaryTextColor,
                    ),
                    children: [
                      TextSpan(
                        text: item.commentsLabel,
                        style: TextStyle(color: isVisited ? Constants.visitedTextColor : null)
                      ),
                      TextSpan(
                        text: ' • ${item.timeAgoCompact} • ${item.community.name}'
                      )
                    ]
                  )
                );
              }
            )
          );
        }
        if (item is Comment) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: item.postTitle,
                      ),
                      TextSpan(
                        text: ' ${platform.communityPrefix}${item.communityName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Constants.secondaryTextColor,
                        )
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Constants.secondaryTextColor,
                    ),
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Constants.commentAuthorColor
                        ),
                      ),
                      TextSpan(text: ' • ${item.score?.toPluralString('point') ?? '[~]'} • ${item.timeAgoCompact}'),
                    ],
                  ),
                ),
                if (item.textHtml != null)
                  Html(
                    platform: platform,
                    html: item.textHtml!
                  )
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      noItemsBuilder: (context) { 
        return const CenteredScrollView(
          child: LargeMessage(
            icon: Icons.feed_outlined,
            message: 'Nothing to show'
          )
        );
      },
    );
  }
}