import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/centered_large_circular_progress_indicator.dart';
import 'package:lurk/widgets/html.dart';
import 'package:lurk/widgets/large_message.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:lurk/widgets/post_tile.dart';

class PostDetailsScreen extends StatefulWidget {

  final Platform platform;
  final String? url;
  final Post? post;

  const PostDetailsScreen._({
    super.key,
    required this.platform,
    this.url,
    this.post,
  })  : assert(post != null || url != null, 'Must provide either a post or a url');

  factory PostDetailsScreen.fromPost({
    Key? key,
    required Post post
  }) {
    return PostDetailsScreen._(
      key: key,
      platform: post.community.platform,
      url: post.url,
      post: post,
    );
  }

  factory PostDetailsScreen.fromUrl({
    Key? key,
    required Platform platform,
    required String url
  }) {
    return PostDetailsScreen._(
      key: key,
      platform: platform,
      url: url,
    );
  }

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
  
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {

  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Post? _post;
  Map<FeedOptionType, FeedOption>? _feedOptions;
  List<CommentItem>? _comments;
  List<CommentItem>? _visibleComments;
  bool _isLoading = true;
  final Set<String> _collapsedCommentIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _post = widget.post!;
      _getPostDetailsFromPost();
    }
    else {
      final platform = Platform.forUrl(widget.url!);
      if (platform != null) {
        _getPostDetails();
      }
      else {
        throw UnimplementedError('Unsupported URL: ${widget.url}');
      }
    }
  }

  Future<void> _getPostDetails() => _get(() => widget.platform.api.getPostDetailsFromUrl(widget.url!));

  Future<void> _getPostDetailsFromPost() => _get(() => _post!.community.platform.api.getPostDetailsFromId(_post!.id, options: _feedOptions));

  Future<void> _get(Future<PostDetails> Function() get) async {
    try {
      final postDetails = await get();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _post = postDetails.post;
          _comments = postDetails.comments;
          _visibleComments = List.of(_comments!);
        });
        History.postDetails.setVisited(_post!.id);
      }
    }
    catch (e) {
      debugPrint('Error fetching post details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCommentCollapseChanged() {
    if (_comments == null) return;
    _visibleComments!.clear();
    int? currentCollapsedDepth;
    for (var item in _comments!) {
      if (currentCollapsedDepth != null) {
        if (item.depth > currentCollapsedDepth) {
          continue; 
        }
        else {
          currentCollapsedDepth = null;
        }
      }
      _visibleComments!.add(item);
      if (item is Comment && _collapsedCommentIds.contains(item.id)) {
        currentCollapsedDepth = item.depth;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String? title;
    final Map<String, VoidCallback> popupMenuActions;
    final RefreshCallback? onRefresh;
    final Widget body;
    if (_post != null) {
      final url = widget.url ?? _post!.url;
      title = _post!.title;
      popupMenuActions = {
        'View in browser': () => openInBrowser(url),
        'View comments in browser': () => openInBrowser(_post!.community.platform.api.getPostDetailsUrl(_post!)),
        'Copy link': () => copyToClipboard(url),
        'Copy comments link': () => copyToClipboard(_post!.community.platform.api.getPostDetailsUrl(_post!))
      };
      onRefresh = _getPostDetailsFromPost;
      final List<Widget> headers = [
        PostTile(
          post: _post!,
          onTapNavigate: false,
          showThumbnail: !_post!.isSelf,
          subtitle: Text(
            'posted to ${_post!.community.name}\n${_post!.timeAgoLong} ago by ${_post!.author}',
            style: const TextStyle(color: Constants.secondaryTextColor, fontSize: 12)
          )
        ),
        if (_post!.textHtml != null)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Constants.postTextHtmlBorderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Html(
              platform: _post!.community.platform,
              html: _post!.textHtml!
            )
          )
        else
          const SizedBox(height: 8),
        Container(
          color: Constants.lighterBackgroundColor,
          padding: const EdgeInsets.only(left: 16, top: 5, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _post!.commentsLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
              ),
              Text(
                'sorted by${_feedOptions != null && _feedOptions!.length > 1 ? ': ${_feedOptions!.values.map((option) => option.label.toLowerCase()).join(' / ')}' : ' ${_post!.community.platform.postCommentsFeedOptions.options.first.label.toLowerCase()}'}',
                style: const TextStyle(color: Constants.secondaryTextColor, fontSize: 11),
              )
            ],
          )
        )
      ];
      if (_isLoading) {
        body = Column(
          children: [
            ...headers,
            Expanded(child: CenteredLargeCircularProgressIndicator(platform: widget.platform))
          ],
        );
      }
      else if (_visibleComments == null || _visibleComments!.isEmpty) {
        body = Column(
          children: [
            ...headers,
            Expanded(
              child: Center(
                child: LargeMessage(
                  icon: Icons.feed_outlined,
                  message: 'No comments'
                ),
              )
            )
          ],
        );
      }
      else {
        body = Scrollbar(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              itemCount: headers.length + _visibleComments!.length,
              itemBuilder: (context, index) {
                if (index < headers.length) {
                  return headers[index];
                }
                final item = _visibleComments![index - headers.length];
                if (item is Comment) {
                  final isCollapsed = _collapsedCommentIds.contains(item.id);
                  return CommentTile(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    comment: item,
                    depth: item.depth,
                    isCollapsed: isCollapsed,
                    onTap: () {
                      setState(() {
                        if (isCollapsed) {
                          _collapsedCommentIds.remove(item.id);
                        }
                        else {
                          _collapsedCommentIds.add(item.id);
                        }
                        _onCommentCollapseChanged();
                      });
                    }
                  );
                }
                else if (item is LoadMoreComment) {
                  return _LoadMoreComments(
                    platform: _post!.community.platform,
                    comment: item,
                    onLoadMoreComments: () async {
                      final comments = await _post!.community.platform.api.getMoreComments(_post!.id, item.pageToken!, depth: item.depth);
                      if (mounted) {
                        setState(() {
                          final index = _comments!.indexOf(item);
                          if (index != -1) {
                            _comments!.removeAt(index);
                            _comments!.insertAll(index, comments);
                            _onCommentCollapseChanged();
                          }
                        });
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        );
      }
    }
    else {
      title = widget.url;
      popupMenuActions = const {};
      if (_isLoading) {
        onRefresh = null;
        body = CenteredLargeCircularProgressIndicator(platform: widget.platform);
      }
      else {
        onRefresh = _getPostDetails;
        body = LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: LargeMessage(
                    icon: Icons.error_outline_rounded,
                    message: 'Something went wrong',
                  )
                ),
              )
            );
          },
        );
      }
    }
    return MainScaffold(
      platform: widget.platform,
      title: title != null ? Text(title) : null,
      subtitle: _post != null ? Text(_post!.community.fullDisplayName) : null,
      popupMenuActions: popupMenuActions,
      feedOptions: widget.platform.postCommentsFeedOptions,
      selectedFeedOptions: _feedOptions,
      useSlivers: true,
      body: CustomRefreshIndicator(
        platform: widget.platform,
        key: _refreshIndicatorKey,
        onRefresh: onRefresh,
        child: body
      ),
      onRefresh: () => _refreshIndicatorKey.currentState?.show(),
      onFeedOptionsSelected: (options) {
        setState(() {
          _isLoading = true;
          _comments?.clear();
          _visibleComments?.clear();
          _collapsedCommentIds.clear();
          _feedOptions = options;
        });
        _getPostDetailsFromPost();
      },
    );
  }

}

class _LoadMoreComments extends StatefulWidget {

  final Platform platform;
  final LoadMoreComment comment;
  final Future Function() onLoadMoreComments;

  const _LoadMoreComments({
    super.key,
    required this.platform,
    required this.comment,
    required this.onLoadMoreComments,
  });

  @override
  State<_LoadMoreComments> createState() => _LoadMoreCommentsState();

}

class _LoadMoreCommentsState extends State<_LoadMoreComments> {

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Function()? onTap;
    final Widget child;
    if (_isLoading) {
      onTap = null;
      child = const Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CustomCircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
        );
    }
    else {
      onTap = () async {
        setState(() => _isLoading = true);
        await widget.onLoadMoreComments();
        setState(() => _isLoading = false);
      };
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'load ${widget.comment.count.toPluralString('more comment')}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Constants.linkTextColor
          ),
        )
      );
    }
    return InkWell(
      onTap: onTap,
      child: CommentIndent(
        depth: widget.comment.depth,
        child: child
      ),
    );
  }

}