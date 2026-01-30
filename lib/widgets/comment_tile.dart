import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/votes.dart';
import 'package:lurk/widgets/collection_listenable_builder.dart';
import 'package:lurk/widgets/html.dart';

class CommentTile extends StatelessWidget {

  final EdgeInsetsGeometry? padding;
  final Comment comment;
  final int depth;
  final bool isCollapsed;
  final bool isInteractable;
  final bool showCommunityName;
  final bool showViewUserOption;
  final Map<String, Function()>? options;
  final Widget? header;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  
  const CommentTile({
    super.key,
    this.padding,
    required this.comment,
    this.depth = 0,
    this.isCollapsed = false,
    this.isInteractable = true,
    this.showCommunityName = false,
    this.showViewUserOption = true,
    this.options,
    this.header,
    this.onTap,
    this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    final interactionCallback = isInteractable
      ? () {
          final activeUser = Settings.activeUser.value;
          debugPrint('test: ${activeUser?.id}, ${comment.authorId}');
          showSimpleTextOptionsBottomSheet(
            context: context,
            title: '${comment.authorName == null ? 'Deleted' : comment.authorName!.toPosessive()} comment',
            options: {
              if (activeUser != null && activeUser.id == comment.authorId)
                'Delete comment': () {
                  onDelete?.call();
                  comment.platform.api.deleteComment(comment.id);
                },
              ...?options,
              if (showViewUserOption && comment.authorName != null)
                'View ${comment.platform.userPrefix}${comment.authorName}': () {
                  context.push(
                    () => UserDetailsScreen(
                      platform: comment.platform,
                      username: comment.authorName!
                    )
                  );
                },
              if (comment.text != null)
                'Copy text': () => copyToClipboard(comment.text!),
              'Copy link': () => copyToClipboard(comment.platform.api.getCommentUrl(comment)),
            }
          );
        }
      : null;
    final VoidCallback? onTap;
    final VoidCallback? onLongPress;
    if (this.onTap == null) {
      onTap = interactionCallback;
      onLongPress = null;
    }
    else {
      onTap = this.onTap;
      onLongPress = interactionCallback;
    }

    final String? authorTag;
    final Color authorColor;
    if (comment.isModerator) {
      authorTag = 'M';
      authorColor = Constants.commentModeratorColor;
    }
    else if (comment.isSubmitter) {
      authorTag = 'S';
      authorColor = Constants.commentSubmitterColor;
    }
    else {
      authorTag = null;
      authorColor = Constants.commentAuthorColor;
    }
    final String? htmlText = comment.isDeleted ? '[deleted]' : comment.textHtml;
    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?header,
        CollectionListenableBuilder(
          id: comment.id,
          collectionListenable: Votes.comments,
          builder: (context, vote) {
            return Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Constants.secondaryTextColor,
                  fontStyle: isCollapsed ? FontStyle.italic : null
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
                    text: !comment.isDeleted && comment.authorName != null ? comment.authorName : '[deleted]',
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
                  TextSpan(text: ' • ${comment.score?.toPluralString('point') ?? '[~]'} • ${comment.timeAgoLong}${showCommunityName ? ' • ${comment.communityName}' : ''}'),
                  if (isCollapsed)
                    const TextSpan(text: ' [+]'),
                ],
              ),
            );
          }
        ),
        if (!isCollapsed && htmlText != null)
          Html(
            platform: comment.platform,
            html: htmlText
          )
      ],
    );
    if (padding != null) {
      child = Padding(
        padding: padding!,
        child: child
      );
    }
    if (depth > 0) {
      child = CommentIndent(
        depth: comment.depth,
        child: child
      );
    }
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
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