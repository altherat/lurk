import 'package:flutter/material.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/prefixed_community_name.dart';
import 'package:lurk/widgets/icon_message.dart';
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

  final _feedKey = GlobalKey<SimpleFeedScreenState>();
  bool _isSingleCommunity = false;

  @override initState() {
    super.initState();
    Settings.activeUser.addListener(_onActiveUserChanged);
  }

  @override
  void dispose() {
    Settings.activeUser.removeListener(_onActiveUserChanged);
    super.dispose();
  }

  void _onActiveUserChanged() {
    _feedKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleFeedScreen(
      key: _feedKey,
      scaffoldKey: widget.scaffoldKey,
      platform: widget.community.platform,
      getItems: (options, pageToken) async {
        final result = await widget.community.platform.api.getPosts(widget.community.name, options: options, pageToken: pageToken);
        if (mounted) {
          setState(() {
            _isSingleCommunity = result.items.every((post) => post.community.name == widget.community.name);
          });
        }
        return result;
      },
      title: widget.community.name == null && widget.community.platform.rootCommunityName.isNotEmpty ? Text(widget.community.platform.rootCommunityName) : PrefixedCommunityName(community: widget.community),
      activeCommunityName: widget.community.name,
      feedOptions: (widget.community.name == null ? widget.community.platform.rootPostsFeedOptions : null) ?? widget.community.platform.postsFeedOptions,
      itemBuilder: (context, post) {
        return PostTile(
          post: post,
          showViewCommunityOption: post.community != widget.community,
          subtitle: PostTileCommentHistorySubtitle(
            post: post,
            extraTexts: [post.timeAgoCompact, if (!_isSingleCommunity) post.community.name!],
          ),
        );
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