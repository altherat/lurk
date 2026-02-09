import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_html.dart';
import 'package:lurk/widgets/feed_list.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';

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
    _initialItemsFuture = _getItems(null, null);
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

  Future<void> _collapseComment(FeedListState feedList, Comment comment, int index) {
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
      if (childItem.depth <= comment.depth) {
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
      duration: Duration(milliseconds: (150 + accumulatedHeight * 0.15).toInt()),
    );
    final childAnimationStates = _ChildCollapsingAnimationState(
      totalHeight: accumulatedHeight,
      childOffsets: childOffsets,
      childHeights: childHeights,
      offScreenChildItems: offScreenChildrenToRemove,
      controller: animationController
    );
    _parentCollapsingAnimationStates[comment] = _ParentCollapsingAnimationState(
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
    return animationController
      .reverse(from: 1)
      .then((_) {
        if (!mounted) return;
        feedList.updateItems((items) {
          items.removeWhere((item) => childOffsets.containsKey(item));
          _collapsedCommentIds.add(comment.id);
        });
      });
  }

  //TODO: add initial expansion animation?
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
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Constants.postTextHtmlBorderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomHtml(
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
        if (activeUser == null) {
          return [];
        }
        return [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'Add comment',
            onPressed: () {
              showAddCommentDialog(
                context: context,
                platform: widget.platform,
                id: _post!.id,
                replyingToWidget: PostTile(
                  post: _post!,
                  isInteractable: false,
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
                return _CollapseAnimation(
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
              final parentItem = item;
              final feedList = _simpleFeedScreenKey.currentState!.feedList!;
              if (isCollapsed) {
                final onScreenExpandingChildItems = parentCollapsingAnimationState!.childCollapsingAnimationState.childOffsets.keys;
                feedList.updateItems((items) {
                  items.insertAll(index + 1, onScreenExpandingChildItems);
                  _collapsedCommentIds.remove(item.id);
                });
                parentCollapsingAnimationState.controller
                  .forward(from: 0)
                  .then((_) {
                    feedList.updateItems((items) {
                      items.insertAll(index + 1 + onScreenExpandingChildItems.length, parentCollapsingAnimationState.childCollapsingAnimationState.offScreenChildItems);
                      _parentCollapsingAnimationStates.remove(parentItem)!.controller.dispose();
                      for (var child in onScreenExpandingChildItems) {
                        _childCollapsingAnimationStates.remove(child);
                      }
                    });
                  });
                return;
              }
              _collapseComment(feedList, item, index);
            },
            onReply: (comment) => _addComment(comment, index + 1, item.depth + 1),
            onDelete: () async {
              final feedList = _simpleFeedScreenKey.currentState!.feedList!;
              await _collapseComment(feedList, item, index);
              if (mounted) {
                feedList.updateItems((items) => items.removeAt(index));
              }
            }
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
          return _CollapseAnimation(
            collapsingCommentsState: childCollapsingAnimationState!,
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

class _CollapseAnimation extends StatelessWidget {

  final _CollapsingAnimationState collapsingCommentsState;
  final double offset;
  final double originalHeight;
  final Widget child;
  
  const _CollapseAnimation({
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
          curve: const Interval(0.15, 0.8, curve: Curves.linear),
          reverseCurve: const Interval(0.15, 0.8, curve: Curves.linear).flipped
          // curve: Curves.linear
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

// class _TextContent extends StatefulWidget {

//   final Widget child;

//   const _TextContent({
//     super.key,
//     required this.child,
//   });

//   @override
//   State<_TextContent> createState() => _TextContentState();

// }

// class _TextContentState extends State<_TextContent> {

//   bool _isExpanded = false;
//   bool _showFadingEdge = false;
//   late ScrollController _scrollController;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     _scrollController.addListener(_updateFade);
//     WidgetsBinding.instance.addPostFrameCallback((_) => _updateFade());
//   }

//   void _updateFade() {
//     if (!_scrollController.hasClients) return;
//     final showFadingEdge = _scrollController.position.maxScrollExtent > 0 && _scrollController.position.pixels < _scrollController.position.maxScrollExtent - 10;
//     if (_showFadingEdge != showFadingEdge) {
//       setState(() => _showFadingEdge = showFadingEdge);
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final availableHeight = MediaQuery.of(context).size.height;
//     final backgroundColor = Theme.of(context).colorScheme.surface;
//     return AnimatedContainer(
//       duration: Constants.postTextContentExpansionAnimationDuration,
//       curve: Curves.easeInOutCubicEmphasized,
//       width: double.infinity,
//       margin: const EdgeInsets.all(8),
//       constraints: BoxConstraints(
//         maxHeight: _isExpanded ? availableHeight * 0.5 : availableHeight * 0.25
//       ),
//       decoration: BoxDecoration(
//         border: Border.all(color: Constants.postTextHtmlBorderColor),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: InkWell(
//         onTap: () => setState(() => _isExpanded = !_isExpanded),
//         child: RawScrollbar(
//           controller: _scrollController,
//           padding: EdgeInsets.zero,
//           radius: const Radius.circular(8),
//           child: ShaderMask(
//             shaderCallback: (Rect rect) {
//               return LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [backgroundColor, Colors.transparent],
//                 stops: [_showFadingEdge ? 0.75 : 1, 1],
//               ).createShader(rect);
//             },
//             blendMode: BlendMode.dstIn,
//             child: SingleChildScrollView(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(8),
//               child: widget.child
//             ),
//           ),
//         )
//       )
//     );
//   }

  // I give up - just using a scroll view
  // @override
  // Widget build(BuildContext context) {
  //   final availableHeight = MediaQuery.of(context).size.height;
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.all(8),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Constants.postTextHtmlBorderColor),
  //       borderRadius: BorderRadius.circular(4),
  //     ),
  //     child: InkWell(
  //       onTap: () => setState(() => _isExpanded = !_isExpanded),
  //       child: Padding(
  //         padding: const EdgeInsets.all(8),
  //         child: ClipRect(
  //           child: AnimatedSize(
  //             alignment: Alignment.topLeft,
  //             duration: Constants.postTextContentExpansionAnimationDuration,
  //             curve: Curves.easeInOutCubicEmphasized,
  //             child: ConstrainedBox(
  //               constraints: BoxConstraints(
  //                 maxHeight: _isExpanded ? double.infinity : availableHeight * 0.25,
  //               ),
  //               child: ShaderMask(
  //                 shaderCallback: (Rect bounds) {
  //                   if (_isExpanded) return const LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds);
  //                   return LinearGradient(
  //                     begin: Alignment.topCenter,
  //                     end: Alignment.bottomCenter,
  //                     colors: [Colors.white, Colors.transparent],
  //                     stops: [0.8, 1.0],
  //                   ).createShader(bounds);
  //                 },
  //                 blendMode: BlendMode.dstIn,
  //                 child: UnconstrainedBox(
  //                   constrainedAxis: Axis.horizontal,
  //                   alignment: Alignment.topCenter,
  //                   child: widget.child
  //                 ),
  //               )
  //             )
  //           ),
  //         ),
  //       ),
  //     )
  //   );
  // }

// }

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
      child = CustomCircularProgressIndicator(
        platform: widget.comment.platform,
        padding: EdgeInsets.symmetric(vertical: 8),
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
      child = _LoadMoreCommentsText(comment: widget.comment);
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

class _LoadMoreCommentsText extends StatelessWidget {

  final LoadMoreComment comment;
  final EdgeInsetsGeometry padding;

  const _LoadMoreCommentsText({
    required this.comment,
    this.padding = const EdgeInsets.symmetric(vertical: 8)
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        'load ${comment.count.toPluralString('more comment')}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Constants.linkTextColor
        ),
      )
    );
  }

}