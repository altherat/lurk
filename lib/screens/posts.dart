import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/posts.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/widgets/community_name.dart';
import 'package:lurk/widgets/feed_option_selector.dart';
import 'package:lurk/widgets/history_builder.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';
import 'package:lurk/widgets/main_scaffold.dart';
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

  final _postListKey = GlobalKey<PostsListViewState>();
  Map<FeedOptionType, FeedOption>? _feedOptions;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      platform: widget.community.platform,
      activeCommunityName: widget.community.name,
      scaffoldKey: widget.scaffoldKey,
      title: CommunityName(community: widget.community),
      subtitle: _feedOptions != null ? Text(_feedOptions!.values.map((option) => option.description).join('  •  ')) : null,
      feedOptions: widget.community.platform.postsFeedOptions,
      selectedFeedOptions: _feedOptions,
      useSlivers: true,
      body: PostsListView(
        key: _postListKey,
        community: widget.community,
        feedOptions: _feedOptions,
      ),
      onFeedOptionsSelected: (options) {
        setState(() {
          _feedOptions = options;
        });
      },
      onRefresh: () => _postListKey.currentState?._refresh(),
    );
  }

}

class PostsListView extends StatefulWidget {

  final Community community;
  final Map<FeedOptionType, FeedOption>? feedOptions;

  const PostsListView({
    super.key,
    required this.community,
    required this.feedOptions
  });

  @override
  State<PostsListView> createState() => PostsListViewState();

}

class PostsListViewState extends State<PostsListView> {

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  List<Post> _posts = [];
  String? _postsPageToken;
  bool _isSingleCommunity = false;
  bool _isLoadingInitially = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  @override
  void didUpdateWidget(covariant PostsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.community != oldWidget.community || (!mapEquals(widget.feedOptions, oldWidget.feedOptions) && !(oldWidget.feedOptions == null && listEquals(widget.feedOptions?.values.toList(), [widget.community.platform.postsFeedOptions.options.first])))) {
      setState(() {
        _posts.clear();
        _isLoadingInitially = true;
      });
      _getPosts();
    }
  }

  Future<void> _getPosts() async {
    if (_posts.isEmpty) {
      setState(() {
        _isLoadingInitially = true;
      });
    }
    try {
      final Posts result = await Api.of(widget.community.platform).getPosts(widget.community.name, options: widget.feedOptions);
      if (mounted) {
        setState(() {
          _posts = result.posts;
          _postsPageToken = result.pageToken;
          _isSingleCommunity = _posts.map((post) => post.communityName).toSet().length == 1;
          _isLoadingInitially = false;
        });
      }
    }
    catch (e) {
      debugPrint('Error fetching posts: $e');
      setState(() => _isLoadingInitially = false);
    }
  }

  Future<void> _getMorePosts() async {
    _isLoadingMore = true;
    try {
      final Posts result = await Api.of(widget.community.platform).getPosts(widget.community.name, options: widget.feedOptions, pageToken: _postsPageToken);
      if (mounted) {
        setState(() {
          _posts.addAll(result.posts);
          _postsPageToken = result.pageToken;
          if (_isSingleCommunity) {
            _isSingleCommunity = result.posts.map((post) => post.communityName).toSet().length == 1;
          }
        });
      }
    }
    catch (e) {
      debugPrint('Error fetching more posts: $e');
    }
    finally {
      _isLoadingMore = false;
    }
  }

  Future<void>? _refresh() => _refreshIndicatorKey.currentState?.show();

  @override
  Widget build(BuildContext context) {
    return _isLoadingInitially 
      ? const LargeCircularProgressIndicator()
      : RefreshIndicator(
          key: _refreshIndicatorKey,
          displacement: 15,
          onRefresh: _getPosts,
          child: _posts.isEmpty
          ? LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.feed_outlined,
                          size: 160,
                          color: Colors.white24
                        ),
                        Text(
                          'No posts to show',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white38
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          )
          : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoadingMore && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                  _getMorePosts();
                }
                return false;
              },
              child: Scrollbar(
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                  itemCount: _postsPageToken != null ? _posts.length + 1 : _posts.length,
                  itemBuilder: (context, index) {
                    if (index == _posts.length) {
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3)
                          )
                        ),
                      );
                    }
                        
                    final Post post = _posts[index];
                    return PostTile(
                      community: widget.community,
                      post: post,
                      onTap: () {
                        context.push(
                          () => PostDetailsScreen(
                            community: widget.community,
                            post: post
                          )
                        );
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
                                  text: ' • ${post.timeAgoCompact}${_isSingleCommunity ? '' : ' • ${post.communityName}'}'
                                )
                              ]
                            )
                          );
                        }
                      ),
                    );
                  }
                ),
              ),
            ),
      );
  }

}