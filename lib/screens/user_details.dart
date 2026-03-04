import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/feed.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/name_text.dart';
import 'package:lurk/widgets/user_stats.dart';

class UserDetailsScreen extends StatefulWidget {

  final PlatformContext platformContext;
  final User user;

  const UserDetailsScreen({
    super.key,
    required this.platformContext,
    required this.user,
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
    final response = getApi(widget.platformContext, UserManager.getActiveUser(widget.platformContext.platform)).fetchUserDetails(
      widget.user.nameAndMaybeHost,
      widget.platformContext.platform.userFeedOptions.defaults
    );
    _initialItemsFuture = response.items;
    _userStatsFuture = response.other;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FeedScreen(
      platformContext: widget.platformContext,
      feedOptions: widget.platformContext.platform.userFeedOptions,
      initialItems: _initialItemsFuture,
      fetchItems: (options, pageToken) => getApi(widget.platformContext, UserManager.getActiveUser(widget.platformContext.platform)).fetchUserItems(widget.user.name, pageToken, options),
      title: MultiColoredAppBarTitle(
        texts: [
          (widget.platformContext.platform.userPrefix, theme.colorScheme.onSurfaceVariant),
          (widget.user.name, theme.colorScheme.onSurface),
          if (widget.platformContext.platform.supportsMultipleHosts) ...[
            ('@', theme.colorScheme.onSurfaceVariant),
            (widget.user.host, theme.colorScheme.onSurface)
          ]
        ],
      ),
      flexibleSpaceHeader: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: FutureBuilder(
          future: _userStatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CustomCircularProgressIndicator(
                padding: EdgeInsets.all(16),
                alignment: Alignment.center,
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
                    valueColor: appBarColor.contrast,
                    labelColor: appBarColor.contrast.withAlpha(Constants.onSurfaceVariantAlpha)
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
            platformContext: widget.platformContext,
            post: item,
            showViewUserOption: false,
            subtitle: PostTileCommentHistorySubtitle(
              post: item,
              extraTexts: [
                item.timeAgoCompact,
                ?item.community.nameAndMaybeHost
              ],
            )
          );
        }
        if (item is Comment) {
          return CommentTile(
            platformContext: widget.platformContext,
            comment: item,
            padding: const EdgeInsets.symmetric(vertical: 8),
            showCommunityName: true,
            showViewUserOption: false,
            optionsBuilder: (context, activeUser) => {
              Text('View context'): (context) {
                context.push(() {
                  return PostDetailsScreen.fromComment(
                    platformContext: widget.platformContext,
                    comment: item,
                  );
                });
              }
            },
            header: Text(
              item.postTitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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