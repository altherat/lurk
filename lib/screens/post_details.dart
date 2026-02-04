import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/comment_tile.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/feed_list.dart';
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

  final _feedListKey = GlobalKey<FeedListState>();
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Post? _post;
  Map<FeedOptionType, FeedOption>? _feedOptions;
  String? _contextCommentShortId;
  final Set<String> _collapsedCommentIds = {};
  late List<CommentItem> _allComments;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  Future<PagedItems<CommentItem>> _getItems([String? pageToken]) async {
    final PostDetails postDetails;
    if (_post != null) {
      postDetails = await _getPostDetailsFromPost();
    }
    else {
      postDetails = await widget.platform.api.getPostDetailsFromUrl(widget.url);
      _post = postDetails.post;
    }
    _allComments = postDetails.comments.toList();
    _contextCommentShortId = postDetails.contextCommentShortId;
    History.postDetails.add(_post!.id);
    return PagedItems(items: postDetails.comments);
  }

  Future<PostDetails> _getPostDetailsFromPost() => _post!.community.platform.api.getPostDetailsFromId(_post!.shortId, options: _feedOptions);

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
    final List<Widget>? slivers;
    final RefreshCallback? onRefresh;
    if (_post != null) {
      title = _post!.title;
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
        ),
      ];
      onRefresh = () async {
        final state = _feedListKey.currentState;
        if (state != null){
          await state.refresh();
        }
      };
    }
    else {
      title = widget.url;
      popupMenuActions = const {};
      slivers = [];
      onRefresh = null;
    }
    slivers.add(
      FeedList(
        key: _feedListKey,
        platform: widget.platform,
        getItems: _getItems,
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
                _feedListKey.currentState?.updateItems((items) {
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
              },
              onDelete: () => _feedListKey.currentState?.updateItems((items) => items.removeAt(index))
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
                  _feedListKey.currentState?.updateItems((items) => items.replaceRange(index, index + 1, comments));
                }
              },
            );
          }
          return const SizedBox.shrink();
        },
      )
    );
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
            _feedOptions = options;
            _collapsedCommentIds.clear();
            _feedListKey.currentState?.reload();
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
      onOtherRefresh: () => _refreshIndicatorKey.currentState?.show(),
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