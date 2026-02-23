import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/posts.dart';
import 'package:lurk/screens/image_gallery_viewer.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/collection_listenable_builder.dart';
import 'package:lurk/widgets/swipe_to_vote.dart';

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
    final Map<Widget, Function(BuildContext)> conditionalOptions = {
      if (showViewCommunityOption)
        Text('View ${post.community.fullName}'): (context) => context.push(() => CommunityScreen(community: post.community))
    };
    if (showViewUserOption && post.author != null) {
      final authorHost = post.authorHost ?? post.community.platformContext.host;
      conditionalOptions[Text('View ${post.community.platformContext.platform.getFullUserName(authorHost, post.author!)}')] = (context) {
        context.push(() {
          return UserDetailsScreen(
            platformContext: post.community.platformContext,
            username: post.community.platformContext.platform.supportsMultipleHosts ? '${post.author}@$authorHost' : post.author!,
          );
        });
      };
    }
    showSimpleOptionsBottomSheet(
      context: context,
      title: post.title,
      options: {
        ...conditionalOptions,
        Text('View link in browser'): (context) => openInBrowser(post.url),
        Text('View comments in browser'): (context) => openInBrowser(post.community.platformContext.platform.getPostDetailsUrl(post)),
        Text('Copy link'): (context) => copyToClipboard(post.url),
        Text('Copy comments link'): (context) => copyToClipboard(post.community.platformContext.platform.getPostDetailsUrl(post))
      }      
    );
  }

  void _updateVote(LoggedInUser activeUser, bool up) {
    Platform.getApi(activeUser.platformContext, activeUser).votePost(post.localId, up);
  }

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariantColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final VoidCallback? onTap;
    final VoidCallback? onLongPress;
    if (isInteractable) {
      if (onTapNavigate) {
        onTap = () {
          if (post.isSelf) {
            Posts.visitedLinks.add(post.localId);
          }
          context.push(() => PostDetailsScreen.fromPost(post: post));
        };
      }
      else {
        onTap = () => _showOptions(context);
      }
      onLongPress = () => _showOptions(context);
    }
    else {
      onTap = null;
      onLongPress = null;
    }
    return ValueListenableBuilder(
      valueListenable: UserManager.getActiveUser(post.community.platformContext.platform),
      builder: (context, activeUser, child) {
        final tile = InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _voteWidth,
                height: _voteHeight,
                child: CollectionListenableBuilder(
                  id: (activeUser?.id, post.localId),
                  collectionListenable: Posts.interactionStates,
                  builder: (context, interactionState) {
                    final String scoreText;
                    final score = interactionState?.score ?? post.score;
                    if (score < 1000) {
                      scoreText = score.toString();
                    }
                    else {
                      final double reduced = score / 1000;
                      String formatted = reduced.toStringAsFixed(1);
                      if (reduced >= 9.95) {
                        formatted = reduced.toStringAsFixed(0);
                      }
                      scoreText = '${formatted.replaceAll(RegExp(r'\.0$'), '')}K';
                    }
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: _VoteArrow(
                            assetName: 'assets/arrow_drop_up_rounded.png',
                            isActive: interactionState?.vote == true,
                            alignment: Alignment.topCenter,
                            activeColor: Constants.upvoteColor,
                            onPressed: activeUser != null
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  _updateVote(activeUser, true);
                                }
                              : null
                          ),
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Text(
                              scoreText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: interactionState?.vote == null ? onSurfaceVariantColor : interactionState!.vote! ? Constants.upvoteColor : Constants.downvoteColor,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _VoteArrow(
                            assetName: 'assets/arrow_drop_down_rounded.png',
                            isActive: interactionState?.vote == false,
                            alignment: Alignment.bottomCenter,
                            activeColor: Constants.downvoteColor,
                            onPressed: activeUser != null
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  _updateVote(activeUser, false);
                                }
                              : null
                          ),
                        ),
                      ],
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
                        id: post.localId,
                        collectionListenable: Posts.visitedLinks,
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
                                    color: onSurfaceVariantColor
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
                              headers: {'User-Agent': post.community.platformContext.platform.savedOrDefaultUserAgent},
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
                                Posts.visitedLinks.add(post.localId);
                                if (post.isSelf) {
                                  context.push(() => PostDetailsScreen.fromPost(post: post));
                                }
                                else if (post.isGallery) {
                                  context.push(() => ImageGalleryViewerScreen.fromPost(post: post));
                                }
                                else {
                                  navigate(context, post.community.platformContext, post.community.name, post.url, post: post);
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
        return ValueListenableBuilder(
          valueListenable: Settings.swipePostsToVote,
          child: tile,
          builder: (context, swipePostsToVote, child) {
            if (swipePostsToVote && activeUser != null) {
              return SwipeToVote(
                onVote: (upvote) => _updateVote(activeUser, upvote),
                child: child!
              );
            }
            return child!;
          }
        );
      }
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
      id: post.localId,
      collectionListenable: Posts.visitedDetails,
      builder: (context, isVisited) {
        return Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            children: [
              TextSpan(
                text: post.commentsLabel,
                style: TextStyle(color: isVisited ? Constants.visitedTextColor : null)
              ),
              if (extraTexts != null)
                TextSpan(text: '${Constants.separator}${extraTexts!.join(Constants.separator)}')
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
      splashColor = Theme.of(context).colorScheme.onSurfaceVariant;
      arrowColor = activeColor;
    }
    else {
      splashColor = activeColor;
      arrowColor = Theme.of(context).colorScheme.onSurfaceVariant;
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