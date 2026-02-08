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
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_html.dart';
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
            bodyBuilder: (context, body) {
              if (parentCollapsingAnimationState != null) {
                return _CollapseAnimation(
                  collapsingCommentsState: parentCollapsingAnimationState,
                  offset: 0,
                  originalHeight: parentCollapsingAnimationState.bodyHeight,
                  child: body
                );
              }
              return body;
            },
            onTap: () {
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
              final screenHeight = MediaQuery.of(context).size.height;

              final renderSliverList = context.findRenderObject() as RenderSliverList;
              RenderBox? parentBox = renderSliverList.firstChild;
              while (parentBox != null) {
                final parentData = parentBox.parentData as SliverMultiBoxAdaptorParentData;
                if (parentData.index == index) {
                  break;
                }
                parentBox = renderSliverList.childAfter(parentBox);
              }
              
              RenderFlex? parentColumn;
              void visitor(RenderObject child) {
                if (parentColumn != null) return;
                if (child is RenderFlex && child.direction == Axis.vertical) {
                  parentColumn = child;
                  return;
                }
                child.visitChildren(visitor);
              }
              parentBox!.visitChildren(visitor);

              final parentBody = parentColumn!.lastChild;
              final parentBodyHeight = parentBody!.size.height;
              final parentTopY = parentBox.localToGlobal(Offset.zero).dy;
              final Map<CommentItem, double> childOffsets = {};
              final Map<CommentItem, double> childHeights = {};
              double accumulatedHeight = parentBodyHeight;
              RenderBox? currentChild = renderSliverList.childAfter(parentBox);
              final items = _simpleFeedScreenKey.currentState!.feedList!.items;
              final Set<CommentItem> offScreenChildrenToRemove = {};
              for (var i = index + 1; i < items.length; i++) {
                final childItem = items[i];
                if (childItem.depth <= parentItem.depth) {
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
              _parentCollapsingAnimationStates[parentItem] = _ParentCollapsingAnimationState(
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
                    _collapsedCommentIds.add(parentItem.id);
                  });
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

class _AddCommentBottomSheetContent extends StatefulWidget {
  
  final Platform platform;
  final String replyingToId;
  final Widget replyingToWidget;

  const _AddCommentBottomSheetContent({
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