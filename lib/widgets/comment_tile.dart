import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/votes.dart';
import 'package:lurk/widgets/collection_listenable_builder.dart';
import 'package:lurk/widgets/custom_html.dart';

const _expansionAnimationDuration = Duration(milliseconds: 200);

class CommentTile extends StatefulWidget {

  final Comment comment;
  final int depth;
  final EdgeInsetsGeometry? padding;
  final bool showCommunityName;
  final bool showViewUserOption;
  final bool isCollapsed;
  final bool isInteractable;
  final Map<String, Function()> Function(BuildContext context, LoggedInUser? activeUser)? optionsBuilder;
  final Widget? header;
  final Widget Function(BuildContext context, Widget body)? bodyBuilder;
  final VoidCallback? onExpandOrCollapse;
  final void Function(Comment comment)? onReply;
  final VoidCallback? onDelete;
  
  const CommentTile({
    super.key,
    required this.comment,
    this.depth = 0,
    this.padding,
    this.showCommunityName = false,
    this.showViewUserOption = true,
    this.isCollapsed = false,
    this.isInteractable = true,
    this.optionsBuilder,
    this.header,
    this.bodyBuilder,
    this.onExpandOrCollapse,
    this.onReply,
    this.onDelete
  });

  @override
  State<CommentTile> createState() => _CommentTileState();

}

class _CommentTileState extends State<CommentTile> {

  bool _showToolbar = false;
  
  void _toggleToolbar() => setState(() => _showToolbar = !_showToolbar);

  void _showOptionsBottomSheet() {
    final activeUser = Settings.activeUser.value;
    showSimpleTextOptionsBottomSheet(
      context: context,
      title: '${widget.comment.authorName == null ? 'Deleted' : widget.comment.authorName!.toPosessive()} comment',
      options: {
        if (activeUser != null && activeUser.id == widget.comment.authorId)
          'Delete comment': _onDeleteCommentPressed,
        if (activeUser != null)
          'Reply': _onReplyPressed,
        ...?widget.optionsBuilder?.call(context, activeUser),
        if (widget.showViewUserOption && widget.comment.authorName != null)
          'View ${widget.comment.platform.userPrefix}${widget.comment.authorName}': () {
            context.push(
              () => UserDetailsScreen(
                platform: widget.comment.platform,
                username: widget.comment.authorName!
              )
            );
          },
        if (widget.comment.text != null)
          'Copy text': () => copyToClipboard(widget.comment.text!),
        'Copy link': () => copyToClipboard(widget.comment.platform.api.getCommentUrl(widget.comment)),
      }
    );
  }

  VoidCallback? _getCallback(CommentBehavior behavior) {
    return switch(behavior) {
      CommentBehavior.expandOrCollapse => widget.onExpandOrCollapse,
      CommentBehavior.showToolbar => _toggleToolbar,
      CommentBehavior.showOptions => _showOptionsBottomSheet
    };
  }

  void _onReplyPressed() {
    showAddCommentDialog(
      context: context,
      platform: widget.comment.platform,
      id: widget.comment.id,
      replyingToWidget: CommentTile(
        comment: widget.comment,
        isInteractable: false,
      ),
      onSubmitted: (comment) => widget.onReply?.call(comment)
    );
  }

  void _onDeleteCommentPressed() {
    widget.onDelete?.call();
    widget.comment.platform.api.deleteComment(widget.comment.id);
  }

  void _onVotePressed(bool upVote) {
    final vote = Votes.comments.value(widget.comment.id) == upVote ? null : upVote;
    widget.comment.platform.api.vote(widget.comment.id, vote);
    Votes.comments.setVote(widget.comment.id, vote);
  }

  @override
  Widget build(BuildContext context) {

    final String? authorTag;
    final Color authorColor;
    if (widget.comment.isModerator) {
      authorTag = 'M';
      authorColor = Constants.commentModeratorColor;
    }
    else if (widget.comment.isSubmitter) {
      authorTag = 'S';
      authorColor = Constants.commentSubmitterColor;
    }
    else {
      authorTag = null;
      authorColor = Constants.commentAuthorColor;
    }

    final String? htmlText = widget.comment.isDeleted ? '[deleted]' : widget.comment.textHtml;
    Widget body;
    if (htmlText != null) {
      body = CustomHtml(
        platform: widget.comment.platform,
        html: htmlText,
        imageSizes: widget.comment.images,
      );
    }
    else {
      body = const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: Listenable.merge([Settings.activeUser, Settings.commentTapBehavior, Settings.commentLongPressBehavior]),
      builder: (context, child) {
        final activeUser = Settings.activeUser.value;
        final isUserActive = activeUser != null;
        final commentTapBehavior = Settings.commentTapBehavior.value;
        final commentLongPressBehavior = Settings.commentLongPressBehavior.value;
        final VoidCallback? onTap;
        final VoidCallback? onLongPress;
        if (!widget.isInteractable) {
          onTap = null;
          onLongPress = null;
        }
        else {
          onTap = widget.isCollapsed ? widget.onExpandOrCollapse : _getCallback(commentTapBehavior);
          onLongPress = _getCallback(commentLongPressBehavior);
        }
        if (commentTapBehavior == CommentBehavior.showToolbar || commentLongPressBehavior == CommentBehavior.showToolbar) {
          body = Column(
            children: [
              body,
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                crossFadeState: _showToolbar ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: _expansionAnimationDuration,
                sizeCurve: Curves.easeInOutCubicEmphasized,
                secondChild: Row(
                  children: [
                    CollectionListenableBuilder(
                      id: widget.comment.id,
                      collectionListenable: Votes.comments,
                      builder: (context, vote) {
                        return IconButton(
                          icon: Icon(Icons.arrow_upward_rounded),
                          tooltip: 'Upvote',
                          onPressed: isUserActive ? () => _onVotePressed(true) : null,
                          color: vote == true ? Constants.upvoteColor : null
                          // icon: Image.asset(
                          //   'assets/arrow_drop_up_rounded.png',
                          //   width: 20,
                          //   height: 20
                          // ),
                        );
                      }
                    ),
                    CollectionListenableBuilder(
                      id: widget.comment.id,
                      collectionListenable: Votes.comments,
                      builder: (context, vote) {
                        return IconButton(
                          icon: Icon(Icons.arrow_downward_rounded),
                          tooltip: 'Downvote',
                          onPressed: isUserActive ? () => _onVotePressed(false) : null,
                          color: vote == false ? Constants.downvoteColor : null
                          // icon: Image.asset(
                          //   'assets/arrow_drop_down_rounded.png',
                          //   width: 20,
                          //   height: 20
                          // ),
                        );
                      }
                    ),
                    IconButton(
                      icon: Icon(Icons.reply_rounded),
                      tooltip: 'Reply',
                      onPressed: _onReplyPressed,
                    ),
                    if (isUserActive && activeUser.id == widget.comment.authorId)
                      IconButton(
                        icon: Icon(Icons.delete_rounded),
                        tooltip: 'Delete',
                        onPressed: _onDeleteCommentPressed,
                      ),
                    IconButton(
                      icon: Icon(Icons.more_horiz_rounded),
                      onPressed: _showOptionsBottomSheet,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onExpandOrCollapse,
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant),
                          child: Text('HIDE'),
                        )
                      )
                    )
                  ]
                ),
              )
            ]
          );
        }
        Widget tile = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?widget.header,
            CollectionListenableBuilder(
              id: widget.comment.id,
              collectionListenable: Votes.comments,
              builder: (context, vote) {
                return Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Constants.secondaryTextColor,
                      fontStyle: widget.isCollapsed ? FontStyle.italic : null
                    ),
                    children: [
                      if (vote != null)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: OverflowBox(
                              maxWidth: 28,
                              maxHeight: 28,
                              child: Icon(
                                vote ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                                size: 28, 
                                color: vote ? Constants.upvoteColor : Constants.downvoteColor,
                              ),
                            ),
                          ),
                        ),
                      TextSpan(
                        text: !widget.comment.isDeleted && widget.comment.authorName != null ? widget.comment.authorName : '[deleted]',
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
                      TextSpan(text: ' • ${widget.comment.score?.toPluralString('point') ?? '[~]'} • ${widget.comment.timeAgoLong}${widget.showCommunityName ? ' • ${widget.comment.communityName}' : ''}'),
                      if (widget.isCollapsed)
                        const TextSpan(text: ' [+]'),
                    ],
                  ),
                );
              }
            ),
            widget.bodyBuilder?.call(context, body) ?? body
          ],
        );
        if (widget.padding != null) {
          tile = Padding(
            padding: widget.padding!,
            child: tile
          );
        }
        if (widget.depth > 0) {
          tile = CommentIndent(
            depth: widget.comment.depth,
            child: tile
          );
        }
        tile = InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: tile
        );
        if (!isUserActive) {
          return tile;
        }
        return ValueListenableBuilder(
          valueListenable: Settings.showCommentVotingEdges,
          child: tile,
          builder: (context, showCommentVotingEdges, child) {
            if (!showCommentVotingEdges) {
              return child!;
            }
            return Stack(
              children: [
                child!,
                if (!_showToolbar) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 50,
                    child: Material(
                      clipBehavior: Clip.antiAlias,
                      color: Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8)
                      ),
                      child: InkWell(
                        splashColor: Constants.upvoteColor.withAlpha(100),
                        onTap: () => _onVotePressed(true)
                      ),
                    )
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 50,
                    child: Material(
                      clipBehavior: Clip.antiAlias,
                      color: Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8)
                      ),
                      child: InkWell(
                        splashColor: Constants.downvoteColor.withAlpha(100),
                        onTap: () => _onVotePressed(false)
                      )
                    )
                  ),
                ]
              ],
            );
          }
        );
      }
    );
  }
  
}

class CommentIndent extends StatelessWidget {

  final int depth;
  final Widget child;

  const CommentIndent({
    super.key,
    required this.depth,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    if (depth == 0) return child;
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              depth,
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
          padding: EdgeInsets.only(left: depth * 9),
          child: child,
        ),
      ],
    );
  }

}

Future<void> showAddCommentDialog({
  required BuildContext context,
  required Platform platform,
  required String id,
  required Widget replyingToWidget,
  required void Function(Comment comment) onSubmitted
}) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return _AddCommentBottomSheetContent(
        platform: platform,
        replyingToId: id,
        replyingToWidget: replyingToWidget,
        onSubmitted: onSubmitted
      );
    }
  );
}

class _AddCommentBottomSheetContent extends StatefulWidget {
  
  final Platform platform;
  final String replyingToId;
  final Widget replyingToWidget;
  final void Function(Comment comment) onSubmitted;

  const _AddCommentBottomSheetContent({
    required this.platform,
    required this.replyingToId,
    required this.replyingToWidget,
    required this.onSubmitted
  });

  @override
  State<_AddCommentBottomSheetContent> createState() => _AddCommentBottomSheetContentState();

}

class _AddCommentBottomSheetContentState extends State<_AddCommentBottomSheetContent> {

  final _controller = TextEditingController();
  bool _isSubmitting = false;

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
                    final text = _controller.text.trim();
                    return _isSubmitting
                      ? const CircularProgressIndicator()
                      : IconButton(
                          padding: EdgeInsets.only(right: 16),
                          onPressed: text.isNotEmpty
                            ? () async {
                                setState(() => _isSubmitting = true);
                                final comment = await widget.platform.api.postComment(widget.replyingToId, text);
                                if (context.mounted) {
                                  widget.onSubmitted(comment);
                                  context.pop();
                                }
                              }
                            : null,
                          icon: Icon(
                            Icons.send_rounded,
                            color: text.isNotEmpty ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor
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