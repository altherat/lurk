import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/feed.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/list_tile_icon.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/name_text.dart';
import 'package:lurk/widgets/user_stats.dart';

class SearchScreen extends StatelessWidget {

  final PlatformContext platformContext;
  final String? searchWithinCommunityName;
  final String query;

  const SearchScreen({
    super.key,
    required this.platformContext,
    required this.searchWithinCommunityName,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final FeedOptionsGroup feedOptions;
    final Widget title;
    if (searchWithinCommunityName != null) {
      feedOptions = platformContext.platform.searchWithinCommunityFeedOptions;
      title = MultiColoredAppBarTitle(
        texts: [
          ('"', theme.colorScheme.onSurfaceVariant),
          (query, theme.colorScheme.onSurface),
          ('" in ${platformContext.platform.getPrefixedCommunityName(searchWithinCommunityName)}', theme.colorScheme.onSurfaceVariant)
        ],
      );
    }
    else {
      feedOptions = platformContext.platform.searchFeedOptions;
      title = MultiColoredAppBarTitle(
        texts: [
          ('"', theme.colorScheme.onSurfaceVariant),
          (query, theme.colorScheme.onSurface),
          ('"', theme.colorScheme.onSurfaceVariant)
        ],
      );
    }
    return FeedScreen(
      platformContext: platformContext,
      feedOptions: feedOptions,
      fetchItems: (options, pageToken) => getApi(platformContext, UserManager.getActiveUser(platformContext.platform)).fetchSearchResults(query, searchWithinCommunityName, pageToken, options),
      title: title,
      subtitle: F.appFlavor == Flavor.combined ? '${platformContext.platform.supportsMultipleHosts ? platformContext.host : platformContext.platform.name.toTitleCase()} search' : null,
      itemBuilder: (context, index, item) {
        if (item is Post) {
          return PostTile(
            platformContext: platformContext,
            post: item
          );
        }
        if (item is Comment) {
          return CommentTile(
            platformContext: platformContext,
            comment: item,
            padding: const EdgeInsets.symmetric(vertical: 4),
            showCommunityName: true
          );
        }
        if (item is CommunityDetails) {
          final theme = Theme.of(context);
          return ListTile(
            title: Row(
              children: [
                ListTileIcon(
                  url: item.iconUrl,
                  placeholderIcon: Icons.groups_rounded,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      TextSpan(
                        children: [
                          TextSpan(
                            text: item.community.platform.preferredCommunityPrefix,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          TextSpan(
                            text: item.community.name,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.subscriberCount!.toPluralString('subscriber'),
                      style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant)
                    )
                  ],
                ),
              ],
            ),
            onTap: () => context.push(() => CommunityScreen(community: item.community)),
            subtitle: item.shortDescription != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    item.shortDescription!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null
          );
        }
        if (item is LookedUpUser) {
          final Widget subtitle;
          if (item.isSuspended) {
            subtitle = Text(
              'Suspended',
              style: TextStyle(fontSize: 13),
            );
          }
          else {
            subtitle = UserStats(
              stats: item.stats!,
              valueFontSize: 13,
              valueColor: theme.colorScheme.onSurfaceVariant,
              labelFontSize: 10,
            );
          }
          return ListTile(
            leading: ListTileIcon(
              url: item.iconUrl,
              placeholderIcon: Icons.no_accounts_rounded,
            ),
            title: Text(item.name),
            subtitle: subtitle,
            onTap: () {
              context.push(() {
                return UserDetailsScreen(
                  platformContext: platformContext,
                  user: item,
                );
              });
            }
          );
        }
        return null;
      },
      noItemsBuilder: (context) {
        return const LargeVerticalIconMessage(
          icon: Icons.feed_outlined,
          message: 'No results'
        );
      }
    );
  }

}