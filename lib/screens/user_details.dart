import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/collection_listenable_builder.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/user_stats.dart';

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
    return SimpleFeedScreen(
      platform: platform,
      feedOptions: platform.userFeedOptions,
      showDefaultFeedOptionsInSubtitle: platform.userFeedOptions.options.first.id != UserFeedType.all,
      getAll: (options) => platform.api.getUserDetails(username, options: options),
      getItems: (options, pageToken) => platform.api.getUserItems(username, options: options, pageToken: pageToken),
      title: Builder(
        builder: (context) {
          final parentColor = DefaultTextStyle.of(context).style.color;
          final parentAlpha = (parentColor!.a * 255).toInt();
          return Text.rich(
            TextSpan(
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
      headersBuilder: (context, loadingState, stats) {
        if (loadingState == LoadingState.error) {
          return [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: HorizontalIconMessage(
                icon: Icons.warning_amber_rounded,
                message: 'Failed to load user profile',
              ),
            )
          ];
        }
        if (stats == null) {
          return [
            CustomCircularProgressIndicator(
              platform: platform,
              padding: const EdgeInsets.all(16),
            )
          ];
        }
        return [
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: UserStats(
                stats: stats,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              ),
            ),
          )
        ];
      },
      itemBuilder: (context, item) { 
        if (item is Post) {
          return PostTile(
            post: item,
            showViewUserOption: false,
            subtitle: CollectionListenableBuilder(
              id: item.id,
              collectionListenable: History.posts,
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
          return CommentTile(
            padding: const EdgeInsets.symmetric(vertical: 8),
            comment: item,
            showCommunityName: true,
            showViewUserOption: false,
            optionsBuilder: (context, activeUser) => {
              'View context': () {
                context.push(() {
                  return PostDetailsScreen.fromUrl(
                    platform: platform,
                    url: platform.api.getCommentUrl(item)
                  );
                });
              }
            },
            header: Text(
              item.postTitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Constants.secondaryTextColor),
            )
          );
        }
      },
      noItemsBuilder: (context) {
        return const LargeVerticalIconMessage(
          icon: Icons.feed_outlined,
          message: 'Nothing to show'
        );
      },
    );
  }
}