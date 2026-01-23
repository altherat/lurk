import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:lurk/widgets/post_tile.dart';

class PostDetailsScreen extends StatefulWidget {

  final Community community;
  final Post? post;
  final String? url;

  const PostDetailsScreen({
    super.key,
    required this.community,
    this.post,
    this.url
  }) : assert(post != null || url != null);

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
    if (widget.post == null) {
      _getPostDetails(() => Api.of(widget.community.platform).getPostDetailsFromUrl(widget.url!));
    }
    else {
      _post = widget.post!;
      _getPostDetailsFromPost();
    }
  }

  Future<void> _getPostDetailsFromPost() => _getPostDetails(() => Api.of(widget.community.platform).getPostDetailsFromId(_post!.id, options: _feedOptions));

  Future<void> _getPostDetails(Function() get) async {
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
      // debugPrint('Error loading post: $e');
      setState(() => _isLoading = false);
      rethrow;
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
    final Widget body;
    if (_post == null) {
      title = widget.url;
      body = const LargeCircularProgressIndicator();
    }
    else {
      title = _post!.title;
      final List<Widget> headers = [
        PostTile(
          community: widget.community,
          post: _post!,
          showThumbnail: !_post!.isSelf,
          subtitle: Text(
            'posted to ${_post!.communityName}\n${_post!.timeAgo} ago by ${_post!.author}',
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
            child: _Html(
              community: widget.community,
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
                'sorted by${_feedOptions != null && _feedOptions!.length > 1 ? ': ${_feedOptions!.values.map((option) => option.label.toLowerCase()).join(' / ')}' : ' ${widget.community.platform.postCommentsFeedOptions.options.first.label.toLowerCase()}'}',
                style: const TextStyle(color: Constants.secondaryTextColor, fontSize: 11),
              )
            ],
          )
        )
      ];
      body = CustomRefreshIndicator(
        key: _refreshIndicatorKey,
        platform: widget.community.platform,
        onRefresh: _getPostDetailsFromPost,
        child: _isLoading
          ? Column(
              children: [
                ...headers,
                const Expanded(child: LargeCircularProgressIndicator())
              ],
            )
          : _visibleComments == null
          ? SingleChildScrollView(
            child: Column(
                children: [
                  ...headers,
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No comments'),
                  )
                ]
              ),
          )
          : Scrollbar(
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
                                  platform: widget.community.platform,
                                  username: commentItem.author!
                                )
                              );
                            },
                            if (commentItem.text != null)
                              'Copy text': () => copyToClipboard(commentItem.text!),
                            'Copy link': () => copyToClipboard(Api.of(widget.community.platform).getCommentUrl(_post!, commentItem)),
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
                                      text: commentItem.isDeleted ? '[deleted]' : commentItem.author ?? '[deleted]',
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
                                _Html(
                                  community: widget.community,
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
                      community: widget.community,
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
          )
      );
    }
    return MainScaffold(
      platform: widget.community.platform,
      title: title != null ? Text(title) : null,
      subtitle: _post != null ? Text(widget.community.fullDisplayName) : null,
      popupMenuActions: {
        'View in browser': () => openInBrowser(widget.url ?? widget.post!.url),
        'View comments in browser': () => openInBrowser(Api.of(widget.community.platform).getPostDetailsUrl(widget.post!)),
        'Copy link': () => copyToClipboard(widget.url ?? widget.post!.url),
        'Copy comments link': () => copyToClipboard(Api.of(widget.community.platform).getPostDetailsUrl(widget.post!))
      },
      feedOptions: widget.community.platform.postCommentsFeedOptions,
      selectedFeedOptions: _feedOptions,
      useSlivers: true,
      body: body,
      onRefresh: () => _refreshIndicatorKey.currentState?.show(),
      onFeedOptionsSelected: (options) {
        setState(() {
          _isLoading = true;
          _comments?.clear();
          _visibleComments?.clear();
          _collapsedCommentIds?.clear();
          _feedOptions = options;
        });
        _getPostDetailsFromPost();
      },
    );
  }

}

class _LoadMoreComments extends StatefulWidget {

  final Community community;
  final String postId;
  final LoadMoreComment comment;
  final Function(List<CommentItem> comments) onMoreCommentsLoaded;

  const _LoadMoreComments({
    super.key,
    required this.community,
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
      child = const Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          ),
        ),
        );
    }
    else {
      onTap = () async {
        setState(() => _isLoading = true);
        widget.onMoreCommentsLoaded(await Api.of(widget.community.platform).getMoreComments(widget.postId, widget.comment.pageToken!, level: widget.comment.level));
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

  const _Indented({super.key, required this.level, required this.child});

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

class _Html extends StatelessWidget {

  final Community community;
  final String html;

  const _Html({
    super.key,
    required this.community,
    required this.html,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      fontSize: 13,
      height: 1.25,
    );
    return ValueListenableBuilder(
      valueListenable: Settings.showCommentImages,
      builder: (context, showImages, child) {
        return HtmlWidget(
          html,
          rebuildTriggers: [showImages],
          textStyle: textStyle,
          customStylesBuilder: (element) {
            if (element.localName == 'p') {
              if (element.parent?.localName == 'blockquote') {
                return {
                  'margin-top': element.previousElementSibling == null ? '0' : '4px',
                  'margin-bottom': element.nextElementSibling == null ? '0' : '4px',
                };
              }
              return {
                'margin-top': '4px', 
                'margin-bottom': '4px', 
              };
            }
            if (element.localName == 'a') {
              final String linkColorCss = Constants.htmlLinkColor.toCss();
              return {
                'color': linkColorCss,
                'text-decoration-color': linkColorCss,
              };
            }
            if (element.localName == 'h1') {
              return {
                'font-size': '20px'
              };
            }
            if (element.localName == 'ul') {
              return {
                'margin': '0',
                'padding-left': '25px'
              };
            }
            if (element.localName == 'li') {
              return {
                'list-style-position': 'inside',
              };
            }
            if (element.localName == 'blockquote') {
              return {
                'margin': '0',
                'padding': '0 0 0 5px',
                'border-left': '1px solid ${Constants.htmlQuoteLineColor.toCss()}',
                // 'color': Constants.htmlQuoteTextColor.toCss(),
                'font-style': 'italic',
              };
            }
            return null;
          },
          customWidgetBuilder: (element) {
            if (element.localName == 'hr') {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 1,
                color: Constants.commentIndentColor,
              );
            }
            if (showImages) {
              if (element.localName == 'img') {
                final String url = element.attributes['src']!;
                return _Image(
                  community: community,
                  url: url
                );
              }
              else if (element.localName == 'a') {
                final String url = element.attributes['href']!;
                if (Uri.tryParse(url)?.host == 'preview.redd.it') {
                  return _Image(
                    community: community,
                    url: url
                  );
                }
              }
            }
            else if (element.localName == 'img') {
              return _HtmlLink(
                url: element.attributes['src']!,
                placeholder: '[gif]',
                textStyle: textStyle
              );
            }
            else if (element.localName == 'a') {
              final String url = element.attributes['href']!;
              if (Uri.tryParse(url)?.host == 'preview.redd.it') {
                return _HtmlLink(
                  url: url,
                  placeholder: '[image]',
                  textStyle: textStyle
                );
              }
            }
            return null;
          },
          onTapUrl: (url) {
            if (url.startsWith('/r/')) {
              context.push(
                () => PostsScreen(
                  community: Community(
                    platform: Platform.reddit,
                    name: Uri.parse(url).pathSegments[1].toLowerCase()
                  )
                )
              );
            }
            else if (url.startsWith('/u/')) {
              context.push(
                () => UserDetailsScreen(
                  platform: Platform.reddit,
                  username: Uri.parse(url).pathSegments[1].toLowerCase()
                )
              );
            }
            else {
              navigate(context, url);
            }
            return true;
          },
          onTapImage: (imageMetadata) {
            final url = imageMetadata.sources.firstOrNull?.url;
             if (url != null) {
              navigate(context, url);
             }
          },
        );
      }
    );
  }

}

class _HtmlLink extends StatelessWidget {

  final String url;
  final String placeholder;
  final TextStyle textStyle;

  const _HtmlLink({
    super.key,
    required this.url,
    required this.placeholder,
    required this.textStyle
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: () => navigate(context, url),
        child: Padding(
          padding: EdgeInsets.only(right: 64),
          child: Text(
            placeholder,
            style: textStyle.copyWith(
              color: Constants.htmlLinkColor,
              decoration: TextDecoration.underline,
              decorationColor: Constants.htmlLinkColor,
            ),
          ),
        ),
      ),
    );
  }
  
}

class _Image extends StatelessWidget {

  final Community community;
  final String url;

  const _Image({
    super.key,
    required this.community,
    required this.url
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.25;
    return Align(
      alignment: Alignment.topLeft,
      child: ExtendedImage.network(
        url,
        headers: {'User-Agent': Settings.userAgent.value},
        cacheHeight: (maxHeight * MediaQuery.devicePixelRatioOf(context)).round(),
        fit: BoxFit.contain,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              );
            case LoadState.completed:
              return Stack(
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    decoration: BoxDecoration(border: Border.all(color: Constants.commentIndentColor)),
                    child: state.completedWidget,
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onLongPress: () {
                          showSimpleOptionsBottomSheet(
                            context: context,
                            options: {
                              'Save image': () {}, //TODO
                              'View in browser': () => openInBrowser(url),
                              'Copy link': () => copyToClipboard(url)
                            }
                          );
                        },
                        onTap: () => context.push(() => ImageViewerScreen(url: url))
                      ),
                    ),
                  )
                ],
              );
            case LoadState.failed:
              return const Icon(
                Icons.broken_image_rounded,
                color: Constants.secondaryTextColor
              );
          }
        }
      ),
    );
  }

}