import 'package:flutter/material.dart';
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

// const _collapseAnimationDuration = Duration(milliseconds: 2000);

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

class _PostDetailsScreenState extends State<PostDetailsScreen> with SingleTickerProviderStateMixin {

  final _simpleFeedScreenKey = GlobalKey<SimpleFeedScreenState>();
  late Future<PagedItems<CommentItem>> _initialItemsFuture;
  Post? _post;
  String? _contextCommentShortId;
  final Set<String> _collapsedCommentIds = {};
  late List<CommentItem> _allComments;
  late final ValueNotifier<Map<FeedOptionType, FeedOption>?> _feedOptionsNotifier;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _feedOptionsNotifier = ValueNotifier(null);
    _initialItemsFuture = _getItems(null, null);
  }

  @override
  void dispose() {
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
    _allComments = postDetails.comments.toList();
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
        if (item is Comment) {
          final isCollapsed = _collapsedCommentIds.contains(item.id);
          Widget child = CommentTile(
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
                if (isCollapsed) {
                  _collapsedCommentIds.remove(item.id);
                }
                else {
                  _collapsedCommentIds.add(item.id);
                }
                _simpleFeedScreenKey.currentState?.feedList?.updateItems((items) {
                  items.clear();
                  int? currentCollapsedDepth;
                  for (var comment in _allComments) {
                    if (currentCollapsedDepth != null) {
                      if (comment.depth > currentCollapsedDepth) {
                        continue; 
                      }
                      else {
                        currentCollapsedDepth = null;
                      }
                    }
                    items.add(comment);
                    if (comment is Comment && _collapsedCommentIds.contains(comment.id)) {
                      currentCollapsedDepth = comment.depth;
                    }
                  }
                });

            //   final listState = _simpleFeedScreenKey.currentState!.feedList!;
            //   final visibleComments = listState.items;
            //   final parentIndex = visibleComments.indexOf(item);
            //   final List<CommentItem> itemsToRemove = [];
            //   for (int i = parentIndex + 1; i < visibleComments.length; i++) {
            //     final current = visibleComments[i];
            //     if (current.depth <= item.depth) {
            //       break; 
            //     }
            //     itemsToRemove.add(current);
            //   }
            //   if (itemsToRemove.isEmpty) {
            //     setState(() => _collapsedCommentIds.add(item.id));
            //     return;
            //   }
            //   final collapsingItem = _CollapsingCommentBlockItem(children: itemsToRemove);
            //   listState.updateItems((items) {
            //     // _collapsedCommentIds.add(item.id);
            //     visibleComments.removeWhere((c) => itemsToRemove.contains(c));
            //     visibleComments.insert(parentIndex + 1, collapsingItem);
            //   });
            // },

            },
            onDelete: () => _simpleFeedScreenKey.currentState?.feedList?.updateItems((items) => items.removeAt(index))
          );
          if (item.shortId == _contextCommentShortId) {
            child = DecoratedBox(
              decoration: BoxDecoration(color: Constants.contextCommentBackgroundColor),
              child: child
            );
          }
          return child;
        }
        if (item is LoadMoreComment) {
          return _LoadMoreComments(
            platform: _post!.community.platform,
            comment: item,
            onLoadMoreComments: () async {
              final comments = await _post!.community.platform.api.getMoreComments(_post!.id, item.pageToken!, depth: item.depth);
              if (mounted) {
                _simpleFeedScreenKey.currentState?.feedList?.updateItems((items) => items.replaceRange(index, index + 1, comments));
              }
            },
          );
        }
        // if (item is _CollapsingCommentBlockItem) {
        //   return TweenAnimationBuilder(
        //     duration: _collapseAnimationDuration,
        //     curve: Curves.easeInOutCubicEmphasized,
        //     tween: Tween(begin: 1.0, end: 0.0),
        //     onEnd: () {
        //       _simpleFeedScreenKey.currentState!.feedList!.updateItems((items) => items.remove(item));
        //     },
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
        //       crossAxisAlignment: CrossAxisAlignment.stretch,
        //       children: item.children.map((item) {
        //         if (item is Comment) {
        //           return CommentTile(
        //             padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 4),
        //             comment: item,
        //             depth: item.depth,
        //             isInteractable: false,
        //           );
        //         }
        //         if (item is LoadMoreComment) {
        //           return _LoadMoreComments(
        //             platform: _post!.community.platform,
        //             comment: item,
        //           );
        //         }
        //         return SizedBox.shrink();
        //       }).toList(),
        //     )
        //   );
        // }
        return const SizedBox.shrink();
      },
    );
  }

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

  final Platform platform;
  final LoadMoreComment comment;
  final Future Function()? onLoadMoreComments;

  const _LoadMoreComments({
    required this.platform,
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
        platform: widget.platform,
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

// class _CollapsingCommentBlockItem extends CommentItem {

//   final List<CommentItem> children;

//   _CollapsingCommentBlockItem({
//     required this.children
//   })  : super(depth: 0);

// }