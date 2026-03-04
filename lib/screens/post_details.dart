import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/posts.dart';
import 'package:lurk/screens/feed.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_html.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';

const _expandCollapseAnimationDuration = Duration(milliseconds: 200);
const _postBodyCollapsedHeightRatio = 0.4;
const _postBodyCollapsedFadingEdgeRatio = 0.9;
const _postBodyCollapsedFadingEdgeThreshold = 16;

class PostDetailsScreen extends StatefulWidget {

  final PlatformContext platformContext;
  final Community community;
  final String postId;
  final String? contextCommentShortId;
  final Post? post;
  final String? title;
  final String subtitle;

  const PostDetailsScreen._({
    super.key,
    required this.platformContext,
    required this.community,
    required this.postId,
    required this.contextCommentShortId,
    required this.post,
    required this.title,
    required this.subtitle,
  });

  PostDetailsScreen.fromPost({
    Key? key,
    required PlatformContext platformContext,
    required Post post
  }) : this._(
    key: key,
    platformContext: platformContext,
    community: post.community,
    postId: post.shortLocalId,
    contextCommentShortId: null,
    post: post,
    title: post.title,
    subtitle: post.community.prefixedNameAndMaybeHost,
  );

  PostDetailsScreen.fromComment({
    Key? key,
    required PlatformContext platformContext,
    required Comment comment
  }) : this._(
    key: key,
    platformContext: platformContext,
    community: comment.community,
    postId: comment.postId!,
    contextCommentShortId: comment.shortLocalId,
    post: null,
    title: comment.postTitle,
    subtitle: comment.community.prefixedNameAndMaybeHost,
  );

  factory PostDetailsScreen.fromUrl({
    Key? key,
    required PlatformContext platformContext,
    required Community community,
    required String url,
    required String postId,
    required String? titleSlug,
    required String? contextCommentShortId,
  }) {
    return PostDetailsScreen._(
      key: key,
      platformContext: platformContext,
      community: community,
      postId: postId,
      contextCommentShortId: contextCommentShortId,
      post: null,
      title: titleSlug != null ? titleSlug[0].toUpperCase() + titleSlug.substring(1).replaceAll(RegExp(r'[_-]+'), ' ') : url,
      subtitle: community.prefixedNameAndMaybeHost,
    );
  }

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
  
}

class _PostDetailsScreenState extends State<PostDetailsScreen> with TickerProviderStateMixin {

  final _simpleFeedScreenKey = GlobalKey<FeedScreenState<CommentItem>>();
  late Future<PagedItems<CommentItem>> _initialItemsFuture;
  Post? _post;
  final Set<String> _collapsedCommentIds = {};
  late final ValueNotifier<Map<FeedOptionType, FeedOption>?> _feedOptionsNotifier;
  final Map<Comment, _ParentCollapsingAnimationState> _parentCollapsingAnimationStates = {};
  final Map<CommentItem, _ChildCollapsingAnimationState> _childCollapsingAnimationStates = {};

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _feedOptionsNotifier = ValueNotifier(null);
    _initialItemsFuture = _fetchItems(widget.platformContext.platform.postCommentsFeedOptions.defaults, null);
  }

  @override
  void dispose() {
    for (var state in _parentCollapsingAnimationStates.values) {
      state.controller.dispose();
    }
    _feedOptionsNotifier.dispose();
    super.dispose();
  }

  Future<PagedItems<CommentItem>> _fetchItems(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) async {
    final activeUser = UserManager.getActiveUser(widget.platformContext.platform);
    _feedOptionsNotifier.value = feedOptions;
    final List<CommentItem> fetchedComments;
    if (_post != null) {
      if (activeUser != null && activeUser.host != _post!.localHost) {
        _post = await getApi(widget.platformContext, activeUser).resolveGlobalToLocalPost(_post!.globalId);
      }
      final (comments, post) = await getApi(widget.platformContext, activeUser).fetchCommentsAndMaybePost(
        _post!.shortLocalId,
        _post!.community.name!,
        widget.contextCommentShortId,
        feedOptions
      );
      fetchedComments = comments;
      if (post != null) {
        _post = post;
      }
    }
    else {
      final (comments, post) = await getApi(widget.platformContext, activeUser).fetchCommentsAndPost(widget.postId, widget.community.name, widget.contextCommentShortId, feedOptions);
      fetchedComments = comments;
      _post = post;
    }
    _collapsedCommentIds.clear();
    _parentCollapsingAnimationStates.clear();
    _childCollapsingAnimationStates.clear();
    if (mounted) {
      setState(() {});
    }
    Posts.visitedDetails.add(_post!.localId);
    return PagedItems(items: fetchedComments);
  }

  void _addComment(Comment comment, int index, int depth) {
    _simpleFeedScreenKey.currentState!.feedList!.updateItems(
      (items) {
        items.insert(index, comment.copyWith(depth: depth));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget? title;
    final String? subtitle;
    final Map<Widget, Function(BuildContext context)>? popupMenuActions;
    final List<Widget>? slivers;
    if (_post != null) {
      final bool isLocal = _post!.contentType == ContentType.local;
      title = Text(_post!.title);
      subtitle = _post!.community.prefixedNameAndMaybeHost;
      popupMenuActions = {
        if (_post!.linkUrl != null && !isLocal)
          Text('View link in browser'): (context) => openInBrowser(_post!.linkUrl!),
        Text('View comments in browser'): (context) => openInBrowser(_post!.community.platform.getPostDetailsUrl(_post!)),
        if (_post!.linkUrl != null && !isLocal)
          Text('Copy link'): (context) => copyToClipboard(_post!.linkUrl!),
        Text('Copy comments link'): (context) => copyToClipboard(_post!.community.platform.getPostDetailsUrl(_post!))
      };
      slivers = [
        SliverToBoxAdapter(
          child: Column(
            children: [
              PostTile(
                platformContext: widget.platformContext,
                post: _post!,
                onTapNavigate: false,
                showThumbnail: _post!.contentType != ContentType.local,
                subtitle: Text(
                  'posted to ${_post!.community.platform.getPrefixedCommunityName(_post!.community.name)}\n${_post!.timeAgoLong} by ${_post!.authorName ?? '[deleted]'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12
                  )
                )
              ),
              if (_post!.bodyHtml != null)
                _PostBodyContainer(
                  child: _PostBody(
                    platformContext: widget.platformContext,
                    post: _post!
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
                    ValueListenableBuilder(
                      valueListenable: _feedOptionsNotifier,
                      builder: (context, feedOptions, child) {
                        return Text(
                          'sorted by${feedOptions != null ? ': ${feedOptions.values.map((option) => option.label.toLowerCase()).join(' / ')}' : ' ${_post!.community.platform.postCommentsFeedOptions.options.first.label.toLowerCase()}'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11
                          ),
                        );
                      }
                    )
                  ],
                )
              ),
              if (widget.contextCommentShortId != null)
                InkWell(
                  onTap: () => context.push(() {
                    return PostDetailsScreen.fromPost(
                      platformContext: widget.platformContext,
                      post: _post!
                    );
                  }),
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
        ),
      ];
    }
    else {
      title = widget.title != null ? Text(widget.title!) : null;
      subtitle = widget.subtitle;
      popupMenuActions = const {};
      slivers = [];
    }
    final activeUserListenable = UserManager.getActiveUserListenable(widget.platformContext.platform);
    return FeedScreen(
      key: _simpleFeedScreenKey,
      platformContext: widget.platformContext,
      activeCommunity: widget.community,
      feedOptions: widget.platformContext.platform.postCommentsFeedOptions,
      initialItems: _initialItemsFuture,
      fetchItems: _fetchItems,
      title: title,
      subtitle: subtitle,
      showFeedOptionsSubtitle: false,
      iconActionsBuilder: (activeUserListenable, (context) {
        final activeUser = activeUserListenable.value;
        return [
          if (activeUser != null)
            IconButton(
              icon: const Icon(Icons.add_comment_rounded),
              tooltip: 'Add comment',
              onPressed: () {
                showAddCommentBottomSheet(
                  context: context,
                  platformContext: widget.platformContext,
                  id: _post!.localId,
                  replyingToWidget: Column(
                    children: [
                      PostTile(
                        platformContext: widget.platformContext,
                        post: _post!,
                        isInteractable: false,
                      ),
                      if (_post!.bodyHtml != null)
                        _PostBodyContainer(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CustomHtml(
                              platformContext: widget.platformContext,
                              html: _post!.bodyHtml!
                            )
                          )
                        )
                    ],
                  ),
                  onSubmitted: (comment) => _addComment(comment, 0, 0)
                );
              }
            )
        ];
      }),
      popupMenuActions: popupMenuActions,
      slivers: slivers,
      noItemsBuilder: (BuildContext context) {
        return LargeVerticalIconMessage(
          icon: Icons.feed_outlined,
          message: 'No comments'
        );
      },
      itemBuilder: (context, index, item) {
        final childCollapsingAnimationState = _childCollapsingAnimationStates[item];
        Widget child;
        if (item is Comment) {
          final parentCollapsingAnimationState = _parentCollapsingAnimationStates[item];
          final isCollapsed = _collapsedCommentIds.contains(item.localId);
          child = CommentTile(
            platformContext: widget.platformContext,
            comment: item,
            depth: item.depth,
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 4),
            isCollapsed: isCollapsed,
            isInteractable: parentCollapsingAnimationState?.controller.isAnimating != true && childCollapsingAnimationState?.controller.isAnimating != true,
            bodyBuilder: (context, body) {
              if (parentCollapsingAnimationState != null) {
                return _CollapseExpandAnimation(
                  collapsingCommentsState: parentCollapsingAnimationState,
                  offset: 0,
                  originalHeight: parentCollapsingAnimationState.bodyHeight,
                  child: body
                );
              }
              return MetaData(
                metaData: 'commentBody',
                child: body
              );
            },
            onExpandOrCollapse: () {
              final parentComment = item;
              final feedList = _simpleFeedScreenKey.currentState!.feedList!;
              if (isCollapsed) {
                final onScreenExpandingChildItems = parentCollapsingAnimationState!.childCollapsingAnimationState.childOffsets.keys;
                feedList.updateItems((items) {
                  items.insertAll(index + 1, onScreenExpandingChildItems);
                  _collapsedCommentIds.remove(parentComment.localId);
                });
                parentCollapsingAnimationState.controller
                  .forward(from: 0)
                  .then((_) {
                    feedList.updateItems((items) {
                      items.insertAll(index + 1 + onScreenExpandingChildItems.length, parentCollapsingAnimationState.childCollapsingAnimationState.offScreenChildItems);
                      _parentCollapsingAnimationStates.remove(parentComment)!.controller.dispose();
                      for (var child in onScreenExpandingChildItems) {
                        _childCollapsingAnimationStates.remove(child);
                      }
                    });
                  });
                return;
              }
              final screenHeight = MediaQuery.of(context).size.height;
              final renderSliverList = context.findRenderObject() as RenderSliverList;
              RenderBox? parentBox = renderSliverList.firstChild;
              double parentBodyHeight = 0;
              while (parentBox != null) {
                final parentData = parentBox.parentData as SliverMultiBoxAdaptorParentData;
                if (parentData.index == index) {

                  void findBody(RenderObject object) {
                    if (parentBodyHeight > 0) return;
                    if (object is RenderMetaData && object.metaData == 'commentBody') {
                      parentBodyHeight = object.size.height;
                      return;
                    }
                    object.visitChildren(findBody);
                  }

                  parentBox.visitChildren(findBody);
                  break;
                }
                parentBox = renderSliverList.childAfter(parentBox);
              }

              final parentTopY = parentBox!.localToGlobal(Offset.zero).dy;
              final Map<CommentItem, double> childOffsets = {};
              final Map<CommentItem, double> childHeights = {};
              double accumulatedHeight = parentBodyHeight;
              RenderBox? currentChild = renderSliverList.childAfter(parentBox);
              final items = _simpleFeedScreenKey.currentState!.feedList!.items;
              final Set<CommentItem> offScreenChildrenToRemove = {};
              for (var i = index + 1; i < items.length; i++) {
                final childItem = items[i];
                if (childItem.depth <= parentComment.depth) {
                  break;
                }
                if (parentTopY + accumulatedHeight > screenHeight) {
                  offScreenChildrenToRemove.add(childItem);
                }
                else if ((currentChild?.parentData as SliverMultiBoxAdaptorParentData).index == i) {
                  final height = currentChild!.size.height;
                  childHeights[childItem] = height;
                  childOffsets[childItem] = accumulatedHeight;
                  accumulatedHeight += height;
                  currentChild = renderSliverList.childAfter(currentChild);
                }
              }
              final animationController = AnimationController(
                vsync: this, 
                duration: _expandCollapseAnimationDuration
                // duration: Duration(milliseconds: (225 + accumulatedHeight * 0.1).round()),
              );
              final childAnimationStates = _ChildCollapsingAnimationState(
                totalHeight: accumulatedHeight,
                childOffsets: childOffsets,
                childHeights: childHeights,
                offScreenChildItems: offScreenChildrenToRemove,
                controller: animationController
              );
              _parentCollapsingAnimationStates[parentComment] = _ParentCollapsingAnimationState(
                totalHeight: accumulatedHeight,
                controller: animationController,
                bodyHeight: parentBodyHeight,
                childCollapsingAnimationState: childAnimationStates
              );
              for (var item in childOffsets.keys) {
                _childCollapsingAnimationStates[item] = childAnimationStates;
              }
              feedList.updateItems((items) {
                items.removeWhere((item) => offScreenChildrenToRemove.contains(item));
              });
              animationController
                .reverse(from: 1)
                .then((_) {
                  if (!mounted) return;
                  feedList.updateItems((items) {
                    items.removeWhere((item) => childOffsets.containsKey(item));
                    _collapsedCommentIds.add(parentComment.localId);
                  });
                });
            },
            onReply: (comment) => _addComment(comment, index + 1, item.depth + 1),
            onDelete: () => _simpleFeedScreenKey.currentState!.feedList!.updateItems((items) => items.removeAt(index))
          );
          if (item.shortLocalId == widget.contextCommentShortId) {
            child = Material(
              color: Constants.contextCommentBackgroundColor,
              child: child
            );
          }
        }
        else {
          child = _LoadMoreComments(
            comment: item as LoadMoreComment,
            onLoadMoreComments: () async {
              final comments = await getApi(widget.platformContext, UserManager.getActiveUser(widget.platformContext.platform)).fetchMoreComments(_post!.localId, item.depth, item.pageToken!, null);
              if (mounted) {
                _simpleFeedScreenKey.currentState?.feedList?.updateItems((items) => items.replaceRange(index, index + 1, comments));
              }
            },
          );
        }
        if (childCollapsingAnimationState != null) {
          return _CollapseExpandAnimation(
            collapsingCommentsState: childCollapsingAnimationState,
            offset: childCollapsingAnimationState.childOffsets[item]!,
            originalHeight: childCollapsingAnimationState.childHeights[item]!,
            child: child
          );
        }
        return child;
      },
    );
  }

}

class _CollapseExpandAnimation extends StatelessWidget {

  final _CollapsingAnimationState collapsingCommentsState;
  final double offset;
  final double originalHeight;
  final Widget child;
  
  const _CollapseExpandAnimation({
    required this.collapsingCommentsState,
    required this.offset,
    required this.originalHeight,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: collapsingCommentsState.controller,
      builder: (context, child) {
        final double curtain = collapsingCommentsState.totalHeight * collapsingCommentsState.sizeAnimation.value;
        final double visibleHeight = (curtain - offset).clamp(0.0, originalHeight).toDouble();
        return Opacity(
          opacity: collapsingCommentsState.opacityAnimation.value,
          child: SizedBox(
            height: visibleHeight,
            child: ClipRect(
              child: OverflowBox(
                minHeight: originalHeight,
                maxHeight: originalHeight,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          ),
        );
      },
      child: RepaintBoundary(child: child)
    );
  }

}

abstract class _CollapsingAnimationState {

  final double totalHeight;
  final AnimationController controller;
  final Animation<double> sizeAnimation;
  final Animation<double> opacityAnimation;

  _CollapsingAnimationState({
    required this.totalHeight,
    required this.controller,
  })  : sizeAnimation = CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOutCubicEmphasized,
          reverseCurve: Curves.easeInExpo
          // curve: Curves.easeOutCubic,
          // reverseCurve: Curves.easeInCubic
          // reverseCurve: Easing.emphasizedDecelerate.flipped
        ),
        opacityAnimation = CurvedAnimation(
          parent: controller,
          curve: Curves.linear
          // curve: const Interval(0.15, 0.8, curve: Curves.linear),
          // reverseCurve: const Interval(0.15, 0.8, curve: Curves.linear).flipped
        );

}

class _ParentCollapsingAnimationState extends _CollapsingAnimationState{

  final double bodyHeight;
  final _ChildCollapsingAnimationState childCollapsingAnimationState;

  _ParentCollapsingAnimationState({
    required super.totalHeight,
    required super.controller,
    required this.bodyHeight,
    required this.childCollapsingAnimationState
  });

}

class _ChildCollapsingAnimationState extends _CollapsingAnimationState {

  final Map<CommentItem, double> childOffsets;
  final Map<CommentItem, double> childHeights;
  final Set<CommentItem> offScreenChildItems;

  _ChildCollapsingAnimationState({
    required super.totalHeight,
    required super.controller,
    required this.childOffsets,
    required this.childHeights,
    required this.offScreenChildItems
  });

}

class _PostBodyContainer extends StatelessWidget {
  
  final Widget child;

  const _PostBodyContainer({
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Constants.postBodyBorderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child
    );
  }

}

class _PostBody extends StatefulWidget {

  final PlatformContext platformContext;
  final Post post;

  const _PostBody({
    required this.platformContext,
    required this.post,
  });

  @override
  State<_PostBody> createState() => _PostBodyState();

}

class _PostBodyState extends State<_PostBody> with SingleTickerProviderStateMixin {

  final _scrollController = ScrollController();
  late final AnimationController _animationController;
  late final Animation _animation;
  double? _expandedHeight;
  bool _canExpand = false;
  double _fadingEdgeStrength = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeInExpo
    );
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) {
      return;
    }
    final newStrength = _getFadingEdgeStrength();
    if (newStrength != _fadingEdgeStrength) {
      setState(() {
        _fadingEdgeStrength = newStrength;
      });
    }
  }

  double _getFadingEdgeStrength() {
    final position = _scrollController.position;
    return ((position.maxScrollExtent - position.pixels) / _postBodyCollapsedFadingEdgeThreshold).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final collapsedHeight = MediaQuery.of(context).size.height * _postBodyCollapsedHeightRatio;
    return InkWell(
      onTap: _canExpand
        ? () {
            if (!_scrollController.hasClients) {
              return;
            }
            setState(() {
              _expandedHeight = min(_scrollController.position.maxScrollExtent + _scrollController.position.viewportDimension, MediaQuery.of(context).size.height - (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero).dy);
              // final duration = Duration(milliseconds: (200 + _expandedHeight! * 0.15).toInt());
              _animationController.duration = _expandCollapseAnimationDuration;
              if (_animation.value == 0) {
                _scrollController.animateTo(
                  0,
                  duration: _expandCollapseAnimationDuration,
                  curve: Curves.easeInOutCubicEmphasized
                );
                _animationController.forward();
              }
              else {
                _animationController.reverse();
              }
            });
          }
        : null,
      onLongPress: () {
        showSimpleOptionsBottomSheet(
          context: context,
          options: {
            Text('Copy text'): (context) => copyToClipboard(widget.post.bodyHtml!)
          }
        );
      },
      child: RawScrollbar(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        radius: const Radius.circular(8),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _animation.value == 0 ? collapsedHeight : _animation.value == 1 ? double.infinity : collapsedHeight + (_expandedHeight! - collapsedHeight) * _animation.value
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  if (!_canExpand) {
                    return const LinearGradient(colors: [Colors.transparent, Colors.transparent]).createShader(bounds);
                  }
                  final strength = (1.0 - _animation.value) * _fadingEdgeStrength;
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Theme.of(context).colorScheme.surface.withAlpha((255 * strength).toInt())],
                    stops: [_postBodyCollapsedFadingEdgeRatio, _postBodyCollapsedFadingEdgeRatio + (1 - _postBodyCollapsedFadingEdgeRatio) * strength],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstOut,
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (notification) {
                    if (!_canExpand && _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
                      setState(() {
                        _canExpand = true;
                        _fadingEdgeStrength = _getFadingEdgeStrength();
                      });
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: _canExpand && _animation.value == 0 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: child,
                    )
                  ),
                ),
              )
            );
          },
          child: RepaintBoundary(
            child: CustomHtml(
              platformContext: widget.platformContext,
              html: widget.post.bodyHtml!,
              loadingBuilder: (context) {
                return const CustomCircularProgressIndicator(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(16),
                  size: 40,
                );
              },
            )
          )
        )
      )
    );
  }

}

class _LoadMoreComments extends StatefulWidget {

  final LoadMoreComment comment;
  final Future Function()? onLoadMoreComments;

  const _LoadMoreComments({
    required this.comment,
    this.onLoadMoreComments,
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
      child = const CustomCircularProgressIndicator(
        alignment: Alignment.topLeft,
        padding: EdgeInsets.symmetric(horizontal: 2.5),
        size: 20,
      );
    }
    else {
      onTap = widget.onLoadMoreComments != null
        ? () async {
            setState(() => _isLoading = true);
            await widget.onLoadMoreComments!();
            setState(() => _isLoading = false);
          }
        : null;
      child = Text(
        'load ${widget.comment.count.toPluralString('more comment')}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Constants.loadMoreCommentsTextColor
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      child: CommentIndent(
        depth: widget.comment.depth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: child,
        )
      ),
    );
  }

}