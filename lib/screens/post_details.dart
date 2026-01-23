import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/widgets/centered_scroll_view.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/centered_large_circular_progress_indicator.dart';
import 'package:lurk/widgets/html.dart';
import 'package:lurk/widgets/large_message.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:lurk/widgets/post_tile.dart';

class PostDetailsScreen extends StatefulWidget {

  final Post? post;
  final String? url;

  const PostDetailsScreen({
    super.key,
    this.post,
    this.url
  }) : assert(post != null || url != null);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
  
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {

  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final Platform _platform;

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
      _platform = widget.post!.community.platform;
      _post = widget.post!;
      _getPostDetailsFromPost();
    }
    else {
      final platform = Platform.forUrl(widget.url!);
      if (platform != null) {
        _platform = platform;
        _getPostDetails();
      }
      else {
        throw UnimplementedError('Unsupported URL: ${widget.url}');
      }
    }
  }

  Future<void> _getPostDetails() => _get(() => Api.of(_platform).getPostDetailsFromUrl(widget.url!));

  Future<void> _getPostDetailsFromPost() => _get(() => Api.of(_post!.community.platform).getPostDetailsFromId(_post!.id, options: _feedOptions));

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
    int? currentCollapsedLevel;
    for (var item in _comments!) {
      if (currentCollapsedLevel != null) {
        if (item.level > currentCollapsedLevel) {
          continue; 
        }
        else {
          currentCollapsedLevel = null;
        }
      }
      _visibleComments!.add(item);
      if (item is Comment && _collapsedCommentIds.contains(item.id)) {
        currentCollapsedLevel = item.level;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String? title;
    final RefreshCallback? onRefresh;
    final Widget body;
    if (_post == null) {
      title = widget.url;
      if (_isLoading) {
        onRefresh = null;
        body = CenteredLargeCircularProgressIndicator(platform: _platform);
      }
      else {
        onRefresh = _getPostDetails;
        body = const CenteredScrollView(
          child: LargeMessage(
            icon: Icons.error_outline_rounded,
            message: 'Something went wrong',
          )
        );
      }
    }
    else {
      title = _post!.title;
      onRefresh = _getPostDetailsFromPost;
      final List<Widget> headers = [
        PostTile(
          post: _post!,
          showThumbnail: !_post!.isSelf,
          subtitle: Text(
            'posted to ${_post!.community.name}\n${_post!.timeAgo} ago by ${_post!.author}',
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
            Expanded(child: CenteredLargeCircularProgressIndicator(platform: _platform))
          ],
        );
      }
      else if (_visibleComments == null) {
        body = SingleChildScrollView(
          child: Column(
            children: [
              ...headers,
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No comments'),
              )
            ]
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
                final commentItem = _visibleComments![index - headers.length];
                if (commentItem is Comment) {
                  final isCollapsed = _collapsedCommentIds.contains(commentItem.id);
                  final String? authorTag;
                  final Color authorColor;
                  if (commentItem.isModerator) {
                    authorTag = 'M';
                    authorColor = Constants.commentModeratorColor;
                  }
                  else if (commentItem.isSubmitter) {
                    authorTag = 'S';
                    authorColor = Constants.commentSubmitterColor;
                  }
                  else {
                    authorTag = null;
                    authorColor = Constants.commentAuthorColor;
                  }
                  final String? htmlText = commentItem.isDeleted ? '[deleted]' : commentItem.textHtml;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isCollapsed) {
                          _collapsedCommentIds.remove(commentItem.id);
                        }
                        else {
                          _collapsedCommentIds.add(commentItem.id);
                        }
                        _onCommentCollapseChanged();
                      });
                    },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      showSimpleOptionsBottomSheet(
                        context: context,
                        title: '${commentItem.author!.toPosessive()} comment',
                        options: {
                          'View user': () {
                            context.push(
                              () => UserDetailsScreen(
                                platform: _post!.community.platform,
                                username: commentItem.author!
                              )
                            );
                          },
                          if (commentItem.text != null)
                            'Copy text': () => copyToClipboard(commentItem.text!),
                          'Copy link': () => copyToClipboard(Api.of(_post!.community.platform).getCommentUrl(_post!, commentItem)),
                        }
                      );
                    },
                    child: _Indented(
                      level: commentItem.level,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Constants.secondaryTextColor,
                                  fontStyle: isCollapsed ? FontStyle.italic : null
                                ),
                                children: [
                                  TextSpan(
                                    text: !commentItem.isDeleted && commentItem.author != null ? commentItem.author : '[deleted]',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: authorColor
                                    ),
                                  ),
                                  if (authorTag != null)
                                    TextSpan(
                                      text: ' [$authorTag]',
                                      style: TextStyle(color: authorColor)
                                    ),
                                  TextSpan(text: ' • ${commentItem.score?.toPluralString('point') ?? '[~]'} • ${commentItem.timeAgo}'),
                                  if (isCollapsed)
                                    const TextSpan(text: ' [+]'),
                                ],
                              ),
                            ),
                            if (!isCollapsed && htmlText != null)
                              Html(
                                platform: _post!.community.platform,
                                html: htmlText
                              )
                          ],
                        ),
                      ),
                    ),
                  );
                }
                else if (commentItem is LoadMoreComment) {
                  return _LoadMoreComments(
                    platform: _post!.community.platform,
                    postId: _post!.id,
                    comment: commentItem,
                    onMoreCommentsLoaded: (comments) {
                      if (mounted) {
                        setState(() {
                          final index = _comments!.indexOf(commentItem);
                          if (index != -1) {
                            _comments!.removeAt(index);
                            _comments!.insertAll(index, comments);
                            _onCommentCollapseChanged();
                          }
                        });
                      }
                    }
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        );
      }
    }
    return MainScaffold(
      platform: _platform,
      title: title != null ? Text(title) : null,
      subtitle: _post != null ? Text(_post!.community.fullDisplayName) : null,
      popupMenuActions: {
        'View in browser': () => openInBrowser(widget.url ?? widget.post!.url),
        'View comments in browser': () => openInBrowser(Api.of(_platform).getPostDetailsUrl(widget.post!)),
        'Copy link': () => copyToClipboard(widget.url ?? widget.post!.url),
        'Copy comments link': () => copyToClipboard(Api.of(_platform).getPostDetailsUrl(widget.post!))
      },
      feedOptions: _platform.postCommentsFeedOptions,
      selectedFeedOptions: _feedOptions,
      useSlivers: true,
      body: CustomRefreshIndicator(
        key: _refreshIndicatorKey,
        platform: _platform,
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
  final String postId;
  final LoadMoreComment comment;
  final Function(List<CommentItem> comments) onMoreCommentsLoaded;

  const _LoadMoreComments({
    super.key,
    required this.platform,
    required this.postId,
    required this.comment,
    required this.onMoreCommentsLoaded,
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
            child: CustomCircularProgressIndicator(
              platform: widget.platform,
              strokeWidth: 2.5,
            ),
          ),
        ),
        );
    }
    else {
      onTap = () async {
        setState(() => _isLoading = true);
        widget.onMoreCommentsLoaded(await Api.of(widget.platform).getMoreComments(widget.postId, widget.comment.pageToken!, level: widget.comment.level));
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
      child: _Indented(
        level: widget.comment.level,
        child: child
      ),
    );
  }

}

class _Indented extends StatelessWidget {

  final int level;
  final Widget child;

  const _Indented({
    super.key,
    required this.level,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    if (level == 0) return child;
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              level,
              (index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 1,
                  color: Constants.commentIndentColor,
                );
              },
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: level * 9),
          child: child,
        ),
      ],
    );
  }

}