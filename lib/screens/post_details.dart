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
import 'package:lurk/services/history.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Sort? _sort;
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

  Future<void> _getPostDetailsFromPost() => _getPostDetails(() => Api.of(widget.community.platform).getPostDetailsFromId(_post!.id, sort: _sort));

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
            child: _HtmlWrapper(
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
                'sorted by ${(_sort?.label ?? widget.community.platform.commentSorts.first.label).toLowerCase()}',
                style: const TextStyle(color: Constants.secondaryTextColor, fontSize: 11),
              )
            ],
          )
        )
      ];
      body = RefreshIndicator(
        key: _refreshIndicatorKey,
        displacement: 15,
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
                              //TODO
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
                                _HtmlWrapper(
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
        'View in browser': () => launchUrl(Uri.parse(widget.url ?? widget.post!.url), mode: LaunchMode.externalApplication),
        'View comments in browser': () => launchUrl(Uri.parse(Api.of(widget.community.platform).getPostDetailsUrl(widget.post!)), mode: LaunchMode.externalApplication),
        'Copy link': () => copyToClipboard(widget.url ?? widget.post!.url),
        'Copy comments link': () => copyToClipboard(Api.of(widget.community.platform).getPostDetailsUrl(widget.post!))
      },
      sorts: widget.community.platform.commentSorts,
      initialSort: _sort,
      useSlivers: true,
      body: body,
      onRefresh: () => _refreshIndicatorKey.currentState?.show(),
      onSortSelected: (sort) {
        Navigator.pop(context);
        setState(() {
          _isLoading = true;
          _comments?.clear();
          _visibleComments?.clear();
          _collapsedCommentIds?.clear();
          _sort = sort;
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

class _HtmlWrapper extends StatelessWidget {

  final Community community;
  final String html;

  const _HtmlWrapper({
    super.key,
    required this.community,
    required this.html
  });

  @override
  Widget build(BuildContext context) {
    // return SelectionArea(
    //   child: 
    return ValueListenableBuilder(
      valueListenable: Settings.showCommentImages,
      builder: (context, showImages, child) {
        return _Html(
          community: community,
          html: html,
          showImages: showImages,
        );
      }
    );
  }

}

class _Html extends StatelessWidget {

  final Community community;
  final String html;
  final bool showImages;

  const _Html({
    super.key,
    required this.community,
    required this.html,
    required this.showImages,
  });

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      rebuildTriggers: [showImages],
      textStyle: const TextStyle(
        fontSize: 13,
        height: 1.25,
      ),
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
          final url = element.attributes['src']!;
          return _Html(
            community: community,
            html: '<a href="$url">$url</a>',
            showImages: false,
          );
        }
        return null;
      },
      onTapUrl: (url) => navigate(context, url),
      onTapImage: (imageMetadata) {
        final url = imageMetadata.sources.firstOrNull?.url;
         if (url != null) {
          navigate(context, url);
         }
      },
    );
  }
}

class _Image extends StatelessWidget {

  final double _height = 200;

  final Community community;
  final String url;

  const _Image({
    super.key,
    required this.community,
    required this.url
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ExtendedImage.network(
        url,
        headers: {'User-Agent': Settings.userAgent.value},
        cacheHeight: (_height * MediaQuery.devicePixelRatioOf(context)).round(),
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
                    constraints: BoxConstraints(maxHeight: _height),
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
                              'View in browser': () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                              'Copy link': () => copyToClipboard(url)
                            }
                          );
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ImageViewerScreen(url: url))
                          );
                        }
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