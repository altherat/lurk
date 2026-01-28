import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/widgets/large_message.dart';
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
      showDefaultFeedOptionsInSubtitle: true,
      getItems: (options, pageToken) => platform.api.search(query, options: options, pageToken: pageToken),
      title: Text('"$query"'),
      itemBuilder: (context, item) {
        if (item is Post) {
          return PostTile(post: item);
        }
        if (item is Community) {
          return ListTile(
            leading: ListTileIcon(
              platform: platform,
              url: item.iconUrl,
              placeholderIcon: Icons.groups_rounded,
            ),
            title: Text(item.fullDisplayName.toLowerCase()),
            onTap: () {
              context.push(() {
                return PostsScreen(
                  community: item,
                );
              });
            },
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subscriberCount!.toPluralString('subscriber')),
                if (item.description != null)
                  Text(
                    item.description!
                  ),
              ],
            ),
          );
        }
        if (item is LookedUpUser) {
          final Widget subtitle;
          if (item.isSuspended) {
            subtitle = Text('Suspended');
          }
          else {
            subtitle = UserStats(
              stats: item.stats!,
              valueColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
        return const LargeMessage(
          icon: Icons.feed_outlined,
          message: 'No results'
        );
      }
    );
  }

}