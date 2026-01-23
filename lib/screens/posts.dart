import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/feed_screen.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/widgets/centered_scroll_view.dart';
import 'package:lurk/widgets/community_name.dart';
import 'package:lurk/widgets/history_builder.dart';
import 'package:lurk/widgets/large_message.dart';
import 'package:lurk/widgets/post_tile.dart';

class PostsScreen extends StatefulWidget {

  final Community community;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const PostsScreen({
    super.key,
    required this.community,
    this.scaffoldKey,
  });

  @override
  State<PostsScreen> createState() => _PostsScreenState();

}

class _PostsScreenState extends State<PostsScreen> {

  bool _isSingleCommunity = false;

  @override
  Widget build(BuildContext context) {
    return FeedScreen(
      platform: widget.community.platform,
      title: CommunityName(community: widget.community),
      activeCommunityName: widget.community.name,
      feedOptions: widget.community.platform.postsFeedOptions,
      get: (options, pageToken) async {
        final result = await Api.of(widget.community.platform).getPosts(widget.community.name, options: options, pageToken: pageToken);
        setState(() {
          _isSingleCommunity = result.items.map((post) => post.community.name).toSet().length == 1;
        });
        return result;
      },
      itemBuilder: (context, post) {
        return PostTile(
          post: post,
          onTap: () {
            context.push(() => PostDetailsScreen(post: post));
            if (post.isSelf) {
              History.posts.setVisited(post.id);
            }
          },
          subtitle: HistoryBuilder(
            id: post.id,
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
                      text: post.commentsLabel,
                      style: TextStyle(color: isVisited ? Constants.visitedTextColor : null)
                    ),
                    TextSpan(
                      text: ' • ${post.timeAgoCompact}${_isSingleCommunity ? '' : ' • ${post.community.name}'}'
                    )
                  ]
                )
              );
            }
          ),
        );
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