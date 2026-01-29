import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/votes.dart';
import 'package:lurk/widgets/collection_listenable_builder.dart';

final thumbnailSize = 70;

class PostTile extends StatelessWidget {

  final Post post;
  final Widget? subtitle;
  final bool onTapNavigate;
  final bool showThumbnail;
  final bool showViewCommunityOption;
  final bool showViewUserOption;

  const PostTile({
    super.key,
    required this.post,
    this.subtitle,
    this.onTapNavigate = true,
    this.showThumbnail = true,
    this.showViewCommunityOption = true,
    this.showViewUserOption = true,
  });

  void _showOptions(BuildContext context) {
    showSimpleTextOptionsBottomSheet(
      context: context,
      title: post.title,
      options: {
        if (showViewCommunityOption)
          'View ${post.community.prefixedName}': () => context.push(() => PostsScreen(community: post.community)),
        if (showViewUserOption && post.author != null)
          'View ${post.community.platform.userPrefix}${post.author}': () {
            context.push(
              () => UserDetailsScreen(
                platform: post.community.platform,
                username: post.author!
              )
            );
          },
        'View link in browser': () => openInBrowser(post.url),
        'View comments in browser': () => openInBrowser(post.community.platform.api.getPostDetailsUrl(post)),
        'Copy link': () => copyToClipboard(post.url),
        'Copy comments link': () => copyToClipboard(post.community.platform.api.getPostDetailsUrl(post))
      }      
    );
  }

  void _updateVote(bool? vote) {
    Votes.posts.setVote(post.id, vote);
    post.community.platform.api.vote(post.id, vote);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapNavigate
        ? () {
            if (post.isSelf) {
              History.posts.add(post.id);
            }
            context.push(() => PostDetailsScreen.fromPost(post: post));
          }
        : () => _showOptions(context),
      onLongPress: () { 
        HapticFeedback.mediumImpact();
        _showOptions(context);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder(
            valueListenable: Settings.activeUser,
            builder: (context, activeUser, child) {
              final canVote = activeUser != null;
              return CollectionListenableBuilder(
                id: post.id,
                collectionListenable: Votes.posts,
                builder: (context, vote) {
                  return Column(
                    children: [
                      _VoteArrow(
                        assetName: 'assets/arrow_drop_up_rounded.png',
                        color: vote == true ? Constants.upvoteColor : Constants.secondaryTextColor,
                        onPressed: canVote ? () => _updateVote(vote == true ? null : true) : null
                      ),
                      Text(
                        post.compactScore,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: vote == true ? Constants.upvoteColor : vote == false ? Constants.downvoteColor : Constants.secondaryTextColor,
                        ),
                      ),
                      _VoteArrow(
                        assetName: 'assets/arrow_drop_down_rounded.png',
                        color: vote == false ? Constants.downvoteColor : Constants.secondaryTextColor,
                        onPressed: canVote ? () => _updateVote(vote == false ? null : false) : null
                      ),
                    ],
                  );
                }
              );
            }
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CollectionListenableBuilder(
                    id: post.id,
                    collectionListenable: History.posts,
                    builder: (context, isVisited) {
                      return Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 13.5, height: 1.2),
                          children: [
                            TextSpan(
                              text: post.title,
                              style: TextStyle(
                                fontWeight: post.isStickied ? FontWeight.bold : null,
                                color: post.isStickied ? Constants.postStickiedTitleColor : isVisited ? Constants.visitedTextColor : null
                              )
                            ),
                            TextSpan(
                              text: ' (${post.domain})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Constants.secondaryTextColor
                              )
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  subtitle ?? PostTileCommentHistorySubtitle(
                    post: post,
                    extraTexts: [post.timeAgoCompact, post.community.name!]
                  )
                ],
              ),
            ),
          ),
          if (showThumbnail)
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: post.thumbnailUrl != null
                        ? ExtendedImage.network(
                            post.thumbnailUrl!,
                            headers: {'User-Agent': post.community.platform.api.savedOrDefaultUserAgent},
                            cacheWidth: thumbnailSize * MediaQuery.devicePixelRatioOf(context).round(),
                            fit: BoxFit.cover,
                            loadStateChanged: (state) => state.extendedImageLoadState == LoadState.failed ? const Icon(Icons.broken_image_rounded) : null
                        )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              border: BoxBorder.all(color: Constants.lighterBackgroundColor)
                            ),
                            child: Icon(
                              post.isSelf ? Icons.subject_rounded : Icons.link_rounded,
                              color: Colors.white38,
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          History.posts.add(post.id);
                          if (post.isSelf) {
                            context.push(() => PostDetailsScreen.fromPost(post: post));
                          }
                          else {
                            navigate(context, post.community.platform, post.url, post: post);
                          }
                        }
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

}

class PostTileCommentHistorySubtitle extends StatelessWidget {

  final Post post;
  final List<String>? extraTexts;

  const PostTileCommentHistorySubtitle({
    super.key,
    required this.post,
    this.extraTexts,
  });

  @override
  Widget build(BuildContext context) {
    return CollectionListenableBuilder(
      id: post.id,
      collectionListenable: History.postDetails,
      builder: (context, isVisited) {
        return Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: Constants.secondaryTextColor,
            ),
            children: [
              TextSpan(
                text: post.commentsLabel,
                style: TextStyle(color: isVisited ? Constants.visitedTextColor : null)
              ),
              if (extraTexts != null)
                TextSpan(text: ' • ${extraTexts!.join(' • ')}')
            ]
          )
        );
      }
    );
  }

}

class _VoteArrow extends StatelessWidget {

  final String assetName;
  final Color color;
  final VoidCallback? onPressed;

  const _VoteArrow({
    super.key,
    required this.assetName,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: IconButton(
        padding: const EdgeInsets.all(4.5),
        icon: Image.asset(
          assetName,
          color: color,
        ),
        onPressed: onPressed
      )
    );
    // return IconButton(
    //   visualDensity: VisualDensity.compact,
    //   style: IconButton.styleFrom(
    //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    //     minimumSize: Size.zero
    //   ),
    //   icon: Image.asset(
    //     'assets/arrow_drop_up_rounded.png',
    //     width: 18,
    //     height: 18,
    //     color: _upvote == true ? Constants.upvoteColor : Constants.secondaryTextColor,
    //   ),
    //   onPressed: () => _updateVote(_upvote == true ? null : true)
    // );
  }
}