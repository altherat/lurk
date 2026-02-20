import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/feed.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/list_tile_icon.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/name_text.dart';
import 'package:lurk/widgets/user_stats.dart';

class SearchScreen extends StatelessWidget {

  final Community activeCommunity;
  final String query;

  const SearchScreen({
    super.key,
    required this.activeCommunity,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final FeedOptionsGroup feedOptions;
    final Widget title;
    if (activeCommunity.name != null) {
      feedOptions = activeCommunity.platform.postsFeedOptions;
      title = MultiColoredAppBarTitle(
        texts: [
          ('"', theme.colorScheme.onSurfaceVariant),
          (query, theme.colorScheme.onSurface),
          ('" in ${activeCommunity.fullName}', theme.colorScheme.onSurfaceVariant)
        ],
      );
    }
    else {
      feedOptions = activeCommunity.platform.searchFeedOptions;
      title = MultiColoredAppBarTitle(
        texts: [
          ('"', theme.colorScheme.onSurfaceVariant),
          (query, theme.colorScheme.onSurface),
          ('"', theme.colorScheme.onSurfaceVariant)
        ],
      );
    }
    return FeedScreen(
      activeCommunity: activeCommunity,
      feedOptions: feedOptions,
      fetchItems: (options, pageToken) => activeCommunity.platform.getApi(activeCommunity.host, Settings.activeUser.value?.id).fetchSearchResults(query, activeCommunity.nameAndMaybeHost, options: options, pageToken: pageToken),
      title: title,
      itemBuilder: (context, index, item) {
        if (item is Post) {
          return PostTile(
            activeCommunity: activeCommunity,
            post: item
          );
        }
        if (item is Comment) {
          return CommentTile(
            activeCommunity: activeCommunity,
            comment: item,
            padding: const EdgeInsets.symmetric(vertical: 4),
            showCommunityName: true,
          );
        }
        if (item is CommunityDetails) {
          final theme = Theme.of(context);
          return ListTile(
            title: Row(
              children: [
                ListTileIcon(
                  platform: activeCommunity.platform,
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
                            text: item.community.platform.communityPrefix,
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
            onTap: () => context.push(() => CommunityScreen(activeCommunity: activeCommunity.platform.supportsMultipleHosts ? activeCommunity : item.community, community: item.community)),
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
              valueColor: Theme.of(context).colorScheme.onSurfaceVariant,
              labelFontSize: 10,
            );
          }
          return ListTile(
            leading: ListTileIcon(
              platform: activeCommunity.platform,
              url: item.iconUrl,
              placeholderIcon: Icons.no_accounts_rounded,
            ),
            title: Text(item.name),
            subtitle: subtitle,
            onTap: item.id != null
              ? () {
                  context.push(() {
                    return UserDetailsScreen(
                      activeCommunity: activeCommunity,
                      username: item.name,
                    );
                  });
                }
              : null
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