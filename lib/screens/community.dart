import 'package:flutter/material.dart';
import 'package:lurk/app.dart' as App;
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/prefixed_name.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';

class CommunityScreen extends StatefulWidget {


  final Community community;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CommunityScreen({
    super.key,
    required this.community,
    this.scaffoldKey,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();

}

class _CommunityScreenState extends State<CommunityScreen> with RouteAware {

  final _feedKey = GlobalKey<SimpleFeedScreenState>();
  bool _isSingleCommunity = false;

  @override
  initState() {
    super.initState();
    Settings.activeUser.addListener(_onActiveUserChanged);
  }

  @override
  void dispose() {
    Settings.activeUser.removeListener(_onActiveUserChanged);
    App.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    App.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    final route = ModalRoute.of(context);
    if (App.routeObserver.staleRoutes.contains(route)) {
      _feedKey.currentState?.refresh();
      App.routeObserver.staleRoutes.remove(route);
    }
  }

  void _onActiveUserChanged() {
    if (widget.community.name == null && widget.community.platform == Settings.activeUser.value?.platform) {
      _feedKey.currentState?.reload();
    }
    else {
      _feedKey.currentState?.refresh();
    }
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
      activeCommunity: widget.community,
      feedOptions: (widget.community.name == null ? widget.community.platform.rootPostsFeedOptions : null) ?? widget.community.platform.postsFeedOptions,
      itemBuilder: (context, index, post) {
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