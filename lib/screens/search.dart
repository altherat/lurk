import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/list_tile_icon.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/user_stats.dart';

class SearchScreen extends StatelessWidget {

  final Platform platform;
  final String query;

  const SearchScreen({
    super.key,
    required this.platform,
    required this.query
  });

  @override
  Widget build(BuildContext context) {
    return SimpleFeedScreen(
      platform: platform,
      feedOptions: platform.searchFeedOptions,
      getItems: (options, pageToken) => platform.api.search(query, options: options, pageToken: pageToken),
      title: Text('"$query"'),
      itemBuilder: (context, item) {
        if (item is Post) {
          return PostTile(post: item);
        }
        if (item is Community) {
          final theme = Theme.of(context);
          return ListTile(
            title: Row(
              children: [
                ListTileIcon(
                  platform: platform,
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
                            text: item.platform.communityPrefix,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          TextSpan(
                            text: item.name!,
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
            onTap: () => context.push(() => PostsScreen(community: item)),
            subtitle: item.description != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    item.description!,
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
              platform: platform,
              url: item.iconUrl,
              placeholderIcon: Icons.no_accounts_rounded,
            ),
            title: Text(item.name),
            subtitle: subtitle,
            onTap: item.id != null
              ? () {
                  context.push(() {
                    return UserDetailsScreen(
                      platform: platform,
                      username: item.name
                    );
                  });
                }
              : null
          );
        }
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