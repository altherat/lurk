import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/screens/image_gallery_viewer.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/votes.dart';
import 'package:lurk/widgets/collection_listenable_builder.dart';

const _voteWidth = 45.0;
const _voteHeight = 70.0;

class PostTile extends StatelessWidget {

  final Post post;
  final Widget? subtitle;
  final bool isInteractable;
  final bool onTapNavigate;
  final bool showThumbnail;
  final bool showViewCommunityOption;
  final bool showViewUserOption;

  const PostTile({
    super.key,
    required this.post,
    this.subtitle,
    this.isInteractable = true,
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
    final VoidCallback? onTap;
    final VoidCallback? onLongPress;
    if (isInteractable) {
      onTap = onTapNavigate
        ? () {
            if (post.isSelf) {
              History.posts.add(post.id);
            }
            context.push(() => PostDetailsScreen.fromPost(post: post));
          }
        : null;
      onLongPress = () => _showOptions(context);
    }
    else {
      onTap = null;
      onLongPress = null;
    }
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _voteWidth,
            height: _voteHeight,
            child: ValueListenableBuilder(
              valueListenable: Settings.activeUser,
              builder: (context, activeUser, child) {
                final canVote = activeUser != null;
                return CollectionListenableBuilder(
                  id: post.id,
                  collectionListenable: Votes.posts,
                  builder: (context, vote) {
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: _VoteArrow(
                            assetName: 'assets/arrow_drop_up_rounded.png',
                            isActive: vote == true,
                            alignment: Alignment.topCenter,
                            activeColor: Constants.upvoteColor,
                            onPressed: () {
                              if (!canVote) return;
                              HapticFeedback.mediumImpact();
                              _updateVote(vote == true ? null : true);
                            }
                          ),
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Text(
                              post.compactScore,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: vote == true ? Constants.upvoteColor : vote == false ? Constants.downvoteColor : Constants.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _VoteArrow(
                            assetName: 'assets/arrow_drop_down_rounded.png',
                            isActive: vote == false,
                            alignment: Alignment.bottomCenter,
                            activeColor: Constants.downvoteColor,
                            onPressed: () {
                              if (!canVote) return;
                              HapticFeedback.mediumImpact();
                              _updateVote(vote == false ? null : false);
                            }
                          ),
                        ),
                      ],
                    );
                  }
                );
              }
            ),
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
              width: Constants.thumbnailSize,
              height: Constants.thumbnailSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: post.thumbnailUrl != null
                      ? ExtendedImage.network(
                          post.thumbnailUrl!,
                          headers: {'User-Agent': post.community.platform.api.savedOrDefaultUserAgent},
                          cacheWidth: (Constants.thumbnailSize * MediaQuery.devicePixelRatioOf(context)).round(),
                          fit: BoxFit.cover,
                          loadStateChanged: (state) => state.extendedImageLoadState == LoadState.failed ? const Icon(Icons.broken_image_rounded) : null,
                          
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
                  if (isInteractable)
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            History.posts.add(post.id);
                            if (post.isSelf) {
                              context.push(() => PostDetailsScreen.fromPost(post: post));
                            }
                            else if (post.isGallery) {
                              context.push(() => ImageGalleryViewerScreen.fromPost(post: post));
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
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onPressed;
  final Alignment alignment;

  const _VoteArrow({
    super.key,
    required this.assetName,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final Color splashColor;
    final Color arrowColor;
    if (isActive) {
      splashColor = Constants.secondaryTextColor;
      arrowColor = activeColor;
    }
    else {
      splashColor = activeColor;
      arrowColor = Constants.secondaryTextColor;
    }
    return SizedBox(
      height: _voteHeight / 2,
      child: InkResponse(
        radius: 10,
        splashColor: splashColor.withAlpha(150),
        onTap: onPressed,
        child: Container(
          alignment: alignment,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: AnimatedScale(
            scale: isActive ? 1.2 : 1, 
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOutCubicEmphasized,
            child: Image.asset(
              assetName,
              color: arrowColor,
            ),
          ),
        ),
      ),
    );
  }

}