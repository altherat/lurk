import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/prefixed_name.dart';
import 'package:lurk/widgets/user_stats.dart';

class UserDetailsScreen extends StatefulWidget {

  final Platform platform;
  final String username;

  const UserDetailsScreen({
    super.key,
    required this.platform,
    required this.username
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();

}

class _UserDetailsScreenState extends State<UserDetailsScreen> {

  late Future<PagedItems<dynamic>> _initialItemsFuture;
  late Future<List<UserStat>>? _userStatsFuture;

  @override
  void initState() {
    super.initState();
    final response = widget.platform.api.getUserDetails(widget.username);
    _initialItemsFuture = response.items;
    _userStatsFuture = response.other;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleFeedScreen(
      platform: widget.platform,
      feedOptions: widget.platform.userFeedOptions,
      initialItems: _initialItemsFuture,
      getItems: (options, pageToken) => widget.platform.api.getUserItems(widget.username, options: options, pageToken: pageToken),
      title: PrefixedName(
        prefix: widget.platform.userPrefix,
        name: widget.username,
      ),
      flexibleSpaceHeader: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: FutureBuilder(
          future: _userStatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CustomCircularProgressIndicator(
                platform: widget.platform,
                padding: const EdgeInsets.all(16),
              );
            }
            if (snapshot.hasError) {
              return Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: HorizontalIconMessage(
                  icon: Icons.warning_amber_rounded,
                  message: 'Failed to load user profile',
                ),
              );
            }
            if (snapshot.hasData) {
              return ValueListenableBuilder(
                valueListenable: Settings.appBarColor,
                builder: (context, appBarColor, child) {
                  return UserStats(
                    stats: snapshot.data!,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    color: appBarColor.contrast,
                  );
                }
              );
            }
            return const SizedBox.shrink();
          },
        )
      ),
      itemBuilder: (context, index, item) { 
        if (item is Post) {
          return PostTile(
            post: item,
            showViewUserOption: false,
            subtitle: PostTileCommentHistorySubtitle(
              post: item,
              extraTexts: [item.timeAgoCompact, ?item.community.name],
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
                    platform: widget.platform,
                    url: widget.platform.api.getCommentUrl(item),
                    urlInfo:widget.platform.getPostUrlInfoFromPath(item.permalink)
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
        return null;
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