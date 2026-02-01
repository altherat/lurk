import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/centered_full_height_scroll_view.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/html.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:lurk/widgets/post_tile.dart';

class PostDetailsScreen extends StatefulWidget {

  final Platform platform;
  final String url;
  final Post? post;

  const PostDetailsScreen._({
    super.key,
    required this.platform,
    required this.url,
    this.post,
  });

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
  String? _contextCommentShortId;
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

  Future<void> _getPostDetailsFromPost() => _get(() => _post!.community.platform.api.getPostDetailsFromId(_post!.shortId, options: _feedOptions));

  Future<void> _get(Future<PostDetails> Function() get) async {
    try {
      final postDetails = await get();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _post = postDetails.post;
          _comments = postDetails.comments;
          _contextCommentShortId = postDetails.contextCommentShortId;
          _visibleComments = List.of(_comments!);
        });
        History.postDetails.add(_post!.id);
      }
    }
    catch (e) {
      dev.log('Error fetching post details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      rethrow;
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

  void _showAddCommentDialog(String id, Widget replyingToWidget) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _AddCommentBottomSheetContent(
          platform: widget.platform,
          replyingToId: id,
          replyingToWidget: replyingToWidget,
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? title;
    final List<Widget> iconActions = [];
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
        ),
        if (_contextCommentShortId != null)
          InkWell(
            onTap: () => context.push(() => PostDetailsScreen.fromPost(post: _post!)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All comments (${_post!.commentCount.toCommaString()})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ),
          )
        else
          const SizedBox(height: 8)
      ];
      if (_isLoading) {
        body = Column(
          children: [
            ...headers,
            Expanded(child: LargeCenteredCircularProgressIndicator(platform: widget.platform))
          ],
        );
      }
      else if (_visibleComments == null || _visibleComments!.isEmpty) {
        body = CenteredFullHeightScrollView(
          headers: headers,
          child: const LargeVerticalIconMessage(
            icon: Icons.feed_outlined,
            message: 'No comments'
          )
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
                index -= headers.length;
                final item = _visibleComments![index];
                if (item is Comment) {
                  final isCollapsed = _collapsedCommentIds.contains(item.id);
                  final child = CommentTile(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 4),
                    comment: item,
                    depth: item.depth,
                    isCollapsed: isCollapsed,
                    optionsBuilder: (context, activeUser) => {
                      if (activeUser != null)
                        'Reply': () {
                          _showAddCommentDialog(
                            item.id,
                            CommentTile(
                              comment: item,
                              isInteractable: false,
                            )
                          );
                        }
                    },
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
                    },
                    onDelete: () {
                      setState(() {
                        _visibleComments!.removeAt(index);
                      });
                    }
                  );
                  return item.shortId == _contextCommentShortId
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: Constants.contextCommentBackgroundColor
                        ),
                        child: child
                      )
                    : child;
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
        body = LargeCenteredCircularProgressIndicator(platform: widget.platform);
      }
      else {
        onRefresh = _getPostDetails;
        body = const CenteredFullHeightScrollView(
          child: LargeVerticalIconMessage(
            icon: Icons.error_outline_rounded,
            message: 'Something went wrong',
          )
        );
      }
    }
    return MainScaffold(
      platform: widget.platform,
      title: title != null ? Text(title) : null,
      subtitle: _post != null ? Text(_post!.community.prefixedName) : null,
      popupMenuActions: popupMenuActions,
      iconActions: iconActions,
      feedOptions: widget.platform.postCommentsFeedOptions,
      selectedFeedOptions: _feedOptions,
      iconActionsBuilder: (Settings.activeUser, (context, LoggedInUser? activeUser) {
        if (activeUser == null) return [];
        return [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'Add comment',
            onPressed: () {
              _showAddCommentDialog(
                _post!.id,
                PostTile(
                  post: _post!,
                  isInteractable: false,
                ),
              );
            }
          )
        ];
      }),
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
      child = Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 20,
            width: 20,
            child: PlatformCircularProgressIndicator(
              platform: widget.platform,
              strokeWidth: 2.5
            ),
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

class _AddCommentBottomSheetContent extends StatefulWidget {
  
  final Platform platform;
  final String replyingToId;
  final Widget replyingToWidget;

  const _AddCommentBottomSheetContent({
    super.key,
    required this.platform,
    required this.replyingToId,
    required this.replyingToWidget
  });

  @override
  State<_AddCommentBottomSheetContent> createState() => _AddCommentBottomSheetContentState();

}

class _AddCommentBottomSheetContentState extends State<_AddCommentBottomSheetContent> {

  final _controller = TextEditingController();

  @override void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 300,
              ),
              child: SingleChildScrollView(
                child: widget.replyingToWidget,
              )
              // child: ShaderMask(
              //   shaderCallback: (Rect bounds) {
              //     return const LinearGradient(
              //       begin: Alignment.topCenter,
              //       end: Alignment.bottomCenter,
              //       colors: [Colors.black, Colors.transparent],
              //       stops: [0.75, 1.0],
              //     ).createShader(bounds);
              //   },
              //   blendMode: BlendMode.dstIn,
              //   child: SingleChildScrollView(
              //     padding: const EdgeInsets.only(bottom: 24),
              //     child: CommentTile(comment: item),
              //   ),
              // ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    autofocus: true,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Type a reply',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    final isNotEmpty = value.text.trim().isNotEmpty;
                    return IconButton(
                      padding: EdgeInsets.only(right: 16),
                      onPressed: isNotEmpty
                        ? () {
                            context.pop();
                            widget.platform.api.postComment(widget.replyingToId, _controller.text);
                          }
                        : null,
                      icon: Icon(
                        Icons.send_rounded,
                        color: isNotEmpty ? widget.platform.color : Theme.of(context).disabledColor
                      ),
                    );
                  }
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}