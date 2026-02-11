import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_html.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';

const _postBodyCollapsedHeightRatio = 0.4;
const _postBodyCollapsedFadingEdgeRatio = 0.9;

class PostDetailsScreen extends StatefulWidget {

  final Platform platform;
  final String url;
  final Post? post;

  final String? inferredTitle;
  final String? inferredSubtitle;

  const PostDetailsScreen._({
    super.key,
    required this.platform,
    required this.url,
    this.post,
    this.inferredTitle,
    this.inferredSubtitle,
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
    required String url,
    required PostUrlInfo? urlInfo,
  }) {
    final String? title;
    final String? subtitle;
    if (urlInfo == null) {
      title = null;
      subtitle = url;
    }
    else  {
      title = urlInfo.inferredTitle ?? url;
      subtitle = platform.getPrefixedCommunityName(urlInfo.communityName);
    }
    return PostDetailsScreen._(
      key: key,
      platform: platform,
      url: url,
      inferredTitle: title,
      inferredSubtitle: subtitle
    );
  }

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
  
}

class _PostDetailsScreenState extends State<PostDetailsScreen> with TickerProviderStateMixin {

  final _simpleFeedScreenKey = GlobalKey<SimpleFeedScreenState<CommentItem>>();
  late Future<PagedItems<CommentItem>> _initialItemsFuture;
  Post? _post;
  String? _contextCommentShortId;
  final Set<String> _collapsedCommentIds = {};
  late final ValueNotifier<Map<FeedOptionType, FeedOption>?> _feedOptionsNotifier;
  final Map<Comment, _ParentCollapsingAnimationState> _parentCollapsingAnimationStates = {};
  final Map<CommentItem, _ChildCollapsingAnimationState> _childCollapsingAnimationStates = {};

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _feedOptionsNotifier = ValueNotifier(null);
    _initialItemsFuture = _getItems(widget.platform.postCommentsFeedOptions.defaults, null);
  }

  @override
  void dispose() {
    for (var state in _parentCollapsingAnimationStates.values) {
      state.controller.dispose();
    }
    _feedOptionsNotifier.dispose();
    super.dispose();
  }

  Future<PagedItems<CommentItem>> _getItems(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) async {
    _feedOptionsNotifier.value = feedOptions;
    final PostDetails postDetails;
    if (_post != null) {
      postDetails = await _post!.community.platform.api.getPostDetailsFromId(_post!.shortId, shortCommentId: _contextCommentShortId, options: feedOptions);
    }
    else {
      postDetails = await widget.platform.api.getPostDetailsFromUrl(widget.url, options: feedOptions);
      _post = postDetails.post;
    }
    _contextCommentShortId = postDetails.contextCommentShortId;
    if (mounted) {
      setState(() {});
    }
    History.postDetails.add(_post!.id);
    return PagedItems(items: postDetails.comments);
  }

  void _addComment(Comment comment, int index, int depth) {
    _simpleFeedScreenKey.currentState!.feedList!.updateItems((items) {
        items.insert(index, comment.copyWith(depth: depth));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget? title;
    final Widget subtitle;
    final Map<String, VoidCallback>? popupMenuActions;
    final List<Widget>? slivers;
    if (_post != null) {
      title = Text(_post!.title);
      subtitle = Text(_post!.community.prefixedName);
      popupMenuActions = {
        'View in browser': () => openInBrowser(widget.url),
        'View comments in browser': () => openInBrowser(_post!.community.platform.api.getPostDetailsUrl(_post!)),
        'Copy link': () => copyToClipboard(widget.url),
        'Copy comments link': () => copyToClipboard(_post!.community.platform.api.getPostDetailsUrl(_post!))
      };
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
                _PostBodyContainer(child: _PostBody(post: _post!))
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
                          style: const TextStyle(color: Constants.secondaryTextColor, fontSize: 11),
                        );
                      }
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
        ),
      ];
    }
    else {
      title = widget.inferredTitle != null ? Text(widget.inferredTitle!) : null;
      subtitle = Text(widget.inferredSubtitle != null ? widget.inferredSubtitle! : widget.url);
      popupMenuActions = const {};
      slivers = [];
    }
    return SimpleFeedScreen(
      key: _simpleFeedScreenKey,
      platform: widget.platform,
      feedOptions: widget.platform.postCommentsFeedOptions,
      initialItems: _initialItemsFuture,
      getItems: _getItems,
      title: title,
      subtitle: subtitle,
      showFeedOptionsSubtitle: false,
      iconActionsBuilder: (Settings.activeUser, (context) {
        final activeUser = Settings.activeUser.value;
        return [
          if (activeUser != null && activeUser.platform == _post?.community.platform)
            IconButton(
              icon: const Icon(Icons.add_comment_rounded),
              tooltip: 'Add comment',
              onPressed: () {
                showAddCommentBottomSheet(
                  context: context,
                  platform: widget.platform,
                  id: _post!.id,
                  replyingToWidget: Column(
                    children: [
                      PostTile(
                        post: _post!,
                        isInteractable: false,
                      ),
                      if (_post!.textHtml != null)
                        _PostBodyContainer(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CustomHtml(
                              platform: _post!.community.platform,
                              html: _post!.textHtml!
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
          final isCollapsed = _collapsedCommentIds.contains(item.id);
          child = CommentTile(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 4),
            comment: item,
            depth: item.depth,
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
                  _collapsedCommentIds.remove(parentComment.id);
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
                  // debugPrint('offscreen: ${childItem is Comment ? childItem.text : 'LoadMoreComment'}');
                  offScreenChildrenToRemove.add(childItem);
                }
                else if ((currentChild?.parentData as SliverMultiBoxAdaptorParentData).index == i) {
                  // debugPrint('collapsing: ${childItem is Comment ? childItem.text : 'LoadMoreComment'}');
                  final height = currentChild!.size.height;
                  childHeights[childItem] = height;
                  childOffsets[childItem] = accumulatedHeight;
                  accumulatedHeight += height;
                  currentChild = renderSliverList.childAfter(currentChild);
                }
              }
              // debugPrint("accumulatedHeight=$accumulatedHeight, offScreenChildrenToRemove=${offScreenChildrenToRemove.length}");
              // debugPrint('offsets=${childOffsets.map((item, value) => MapEntry((item is Comment ? item.id : 'LoadMoreComment'), value))}');
              // debugPrint('heights=${childHeights.map((item, value) => MapEntry((item is Comment ? item.id : 'LoadMoreComment'), value))}');
              final animationController = AnimationController(
                vsync: this, 
                duration: Duration(milliseconds: (225 + accumulatedHeight * 0.1).round()),
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
                    _collapsedCommentIds.add(parentComment.id);
                  });
                });
            },
            onReply: (comment) => _addComment(comment, index + 1, item.depth + 1),
            onDelete: () => _simpleFeedScreenKey.currentState!.feedList!.updateItems((items) => items.removeAt(index))
          );
          if (item.shortId == _contextCommentShortId) {
            child = DecoratedBox(
              decoration: BoxDecoration(color: Constants.contextCommentBackgroundColor),
              child: child
            );
          }
        }
        else {
          child = _LoadMoreComments(
            comment: item as LoadMoreComment,
            onLoadMoreComments: () async {
              final comments = await _post!.community.platform.api.getMoreComments(_post!.id, item.pageToken!, depth: item.depth);
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
        border: Border.all(color: Constants.postTextHtmlBorderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child
    );
  }

}

class _PostBody extends StatefulWidget {

  final Post post;

  const _PostBody({
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
  double _fadingEdgeVisibility = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        setState(() {
          _canExpand = true;
          _fadingEdgeVisibility = 1;
        });
      }
    });
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
    final position = _scrollController.position;
    final newVisibility = ((position.maxScrollExtent - position.pixels) / (_scrollController.position.viewportDimension * _postBodyCollapsedFadingEdgeRatio)).clamp(0.0, 1.0);
    if (newVisibility != _fadingEdgeVisibility) {
      setState(() {
        _fadingEdgeVisibility = newVisibility;
      });
    }
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
              final duration = Duration(milliseconds: (200 + _expandedHeight! * 0.15).toInt());
              _animationController.duration = duration;
              if (_animation.value == 0) {
                _scrollController.animateTo(
                  0,
                  duration: duration,
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
                  final strength = (1.0 - _animation.value) * _fadingEdgeVisibility;
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Theme.of(context).colorScheme.surface.withAlpha((255 * strength).toInt())],
                    stops: [_postBodyCollapsedFadingEdgeRatio, _postBodyCollapsedFadingEdgeRatio + ((1 - _postBodyCollapsedFadingEdgeRatio) * strength)],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstOut,
                child: SingleChildScrollView(
                  physics: _canExpand && _animation.value == 0 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: child,
                  )
                ),
              )
            );
          },
          child: RepaintBoundary(
            child: CustomHtml(
              platform: widget.post.community.platform,
              html: widget.post.textHtml!
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
        size: 20,
        strokeWidth: 2.5
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
          color: Constants.linkTextColor
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