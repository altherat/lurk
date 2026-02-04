import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/centered_full_height_scroll_view.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/feed_option_selector.dart';
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

class _PostDetailsScreenState extends State<PostDetailsScreen> with SingleTickerProviderStateMixin {

  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Post? _post;
  Map<FeedOptionType, FeedOption>? _feedOptions;
  List<CommentItem>? _comments;
  List<CommentItem>? _visibleComments;
  String? _contextCommentShortId;
  bool _isLoading = true;
  final Set<String> _collapsedCommentIds = {};
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: Constants.feedLoadAnimationDuration
    );
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          _animationController.forward();
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
    final String title;
    final Map<String, VoidCallback> popupMenuActions;
    final RefreshCallback? onRefresh;
    final List<Widget>? slivers;
    if (_post != null) {
      title = _post!.title;
      popupMenuActions = {
        'View in browser': () => openInBrowser(widget.url),
        'View comments in browser': () => openInBrowser(_post!.community.platform.api.getPostDetailsUrl(_post!)),
        'Copy link': () => copyToClipboard(widget.url),
        'Copy comments link': () => copyToClipboard(_post!.community.platform.api.getPostDetailsUrl(_post!))
      };
      onRefresh = _getPostDetailsFromPost;
      slivers = [
        SliverToBoxAdapter(
          child: Column(
            children: [
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
            ]
          ),
        )
      ];
      final Widget child;
      if (_isLoading) {
        child = SliverFillRemaining(
          hasScrollBody: false,
          child: LargeCenteredCircularProgressIndicator(platform: widget.platform)
        );
      }
      else if (_visibleComments == null || _visibleComments!.isEmpty) {
        child = SliverFillRemaining(
          hasScrollBody: false,
          child: LargeVerticalIconMessage(
            icon: Icons.feed_outlined,
            message: 'No comments'
          ),
        );
      }
      else {
        child = AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: _visibleComments!.length,
                (context, index) {
                  final item = _visibleComments![index];
                  Widget? child;
                  if (item is Comment) {
                    final isCollapsed = _collapsedCommentIds.contains(item.id);
                    child = CommentTile(
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
                      onTap: () async {
                        setState(() {
                          if (isCollapsed) {
                            _collapsedCommentIds.remove(item.id);
                          }
                          else {
                            _collapsedCommentIds.add(item.id);
                          }
                          _onCommentCollapseChanged();
                        });
                    
                        // Some hack solution to try and get comment collapse animation in a flat list
                    
                        // final parentIndex = _visibleComments!.indexOf(item);
                        // final List<CommentItem> itemsToRemove = [];
                        // for (int i = parentIndex + 1; i < _visibleComments!.length; i++) {
                        //   final current = _visibleComments![i];
                        //   if (current.depth <= item.depth) {
                        //     break; 
                        //   }
                        //   itemsToRemove.add(current);
                        // }
                    
                        // if (itemsToRemove.isEmpty) {
                        //   setState(() => _collapsedCommentIds.add(item.id));
                        //   return;
                        // }
                    
                        // final proxy = _CollapsingCommentItem(children: itemsToRemove);
                        // setState(() {
                        //   // _collapsedCommentIds.add(item.id);
                        //   _visibleComments!.removeWhere((c) => itemsToRemove.contains(c));
                        //   _visibleComments!.insert(parentIndex + 1, proxy);
                        // });
                        // await Future.delayed(const Duration(milliseconds: 2000));
                        // if (mounted) {
                        //   setState(() {
                        //     _visibleComments!.remove(proxy);
                        //   });
                        // }
                      },
                      onDelete: () {
                        setState(() {
                          _visibleComments!.removeAt(index);
                        });
                      }
                    );
                    if (item.shortId == _contextCommentShortId) {
                      child = DecoratedBox(
                        decoration: BoxDecoration(color: Constants.contextCommentBackgroundColor),
                        child: child
                      );
                    }
                  }
                  else if (item is LoadMoreComment) {
                    child =_LoadMoreComments(
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
                  return FeedItemTransition(
                    progress: _animationController.value,
                    child: child!
                  );
                  // if (item is _CollapsingCommentItem) {
                  //   return TweenAnimationBuilder(
                  //     duration: const Duration(milliseconds: 2000),
                  //     tween: Tween(begin: 1.0, end: 0.0),
                  //     builder: (context, value, child) {
                  //       return ClipRect(
                  //         child: Align(
                  //           alignment: Alignment.topCenter,
                  //           heightFactor: value,
                  //           child: child,
                  //         ),
                  //       );
                  //     },
                  //     child: Column(
                  //       children: item.children.map((item) {
                  //         if (item is Comment) {
                  //           return CommentTile(
                  //             padding: EdgeInsets.only(bottom: 4),
                  //             comment: item,
                  //             depth: item.depth,
                  //           );
                  //         }
                  //         if (item is LoadMoreComment) {
                  //           return _LoadMoreComments(
                  //             platform: _post!.community.platform,
                  //             comment: item,
                  //             onLoadMoreComments: () async {},
                  //           );
                  //         }
                  //         return SizedBox.shrink();
                  //       }).toList(),
                  //     )
                  //   );
                  // }
                },
              ),
            );
          }
        );
      }
      slivers.add(child);
    }
    else {
      title = widget.url;
      popupMenuActions = const {};
      final Widget child;
      if (_isLoading) {
        onRefresh = null;
        child = LargeCenteredCircularProgressIndicator(platform: widget.platform);
      }
      else {
        onRefresh = _getPostDetails;
        child = LargeVerticalIconMessage(
          icon: Icons.error_outline_rounded,
          message: 'Something went wrong',
        );
      }
      slivers = [
        SliverFillRemaining(child: child)
      ];
    }
    return MainScaffold(
      platform: widget.platform,
      refreshIndicatorKey: _refreshIndicatorKey,
      title: Text(title),
      subtitle: _post != null ? Text(_post!.community.prefixedName) : null,
      popupMenuActions: popupMenuActions,
      iconActions: [
        FeedFilterIconButton(
          platform: widget.platform,
          feedOptions: widget.platform.postCommentsFeedOptions,
          selectedFeedOptions: _feedOptions,
          onFeedOptionsSelected: (options) {
            setState(() {
              _isLoading = true;
              _comments?.clear();
              _visibleComments?.clear();
              _collapsedCommentIds.clear();
              _feedOptions = options;
            });
            _getPostDetailsFromPost();
          }
        )
      ],
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
      slivers: slivers,
      onPullRefresh: onRefresh,
      onButtonRefresh: () async => _refreshIndicatorKey.currentState?.show(),
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