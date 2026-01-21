import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/history_builder.dart';
import 'package:url_launcher/url_launcher.dart';

final thumbnailSize = 70;

class PostTile extends StatelessWidget {

  final Community community;
  final Post post;
  final Widget subtitle;
  final VoidCallback? onTap;

  const PostTile({
    super.key,
    required this.community,
    required this.post,
    required this.subtitle,
    this.onTap
  });

  void _showOptions(BuildContext context) {
    showSimpleOptionsBottomSheet(
      context: context,
      title: post.title,
      options: {
        'View ${community.platform.communityLabel} ${community.fullDisplayName}': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:(context) {
                return PostsScreen(
                  community: community
                );
              }
            )
          );
        },
        'View user ${community.platform.userPrefix}${post.author}': () {
          //TODO
        },
        'View link in browser': () => launchUrl(Uri.parse(post.url), mode: LaunchMode.externalApplication),
        'View comments in browser': () => launchUrl(Uri.parse(Api.of(community.platform).getPostDetailsUrl(post)), mode: LaunchMode.externalApplication),
        'Copy link': () => copyToClipboard(post.url),
        'Copy comments link': () => copyToClipboard(Api.of(community.platform).getPostDetailsUrl(post))
      }      
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheSize = thumbnailSize * MediaQuery.devicePixelRatioOf(context).round();
    return InkWell(
      onTap: onTap ?? () => _showOptions(context),
      onLongPress: () { 
        HapticFeedback.mediumImpact();
        _showOptions(context);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: 40,
              child: _Score(
                score: post.compactScore,
                upvoted: null
              )
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HistoryBuilder(
                    id: post.id,
                    history: History.posts,
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
                  subtitle
                ],
              ),
            ),
          ),
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              children: [
                Positioned.fill(
                  child: post.thumbnailUrl != null
                      ? ExtendedImage.network(
                          post.thumbnailUrl!,
                          headers: {'User-Agent': Settings.userAgent.value},
                          width: 70,
                          height: 70,
                          cacheWidth: cacheSize,
                          cacheHeight: cacheSize,
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
                      onTap: () async {
                        if (await navigate(context, post.url, community: community, post: post)) {
                          History.posts.setVisited(post.id);
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

class _Score extends StatefulWidget {

  final String score;
  final bool? upvoted;

  const _Score({
    super.key,
    required this.score,
    required this.upvoted
  });

  @override
  State<_Score> createState() => _ScoreState();
}

class _ScoreState extends State<_Score> {

  bool? _upvoted;

  @override
  void initState() {
    super.initState();
    _upvoted = widget.upvoted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero
          ),
          icon: Image.asset(
            'assets/arrow_drop_up_rounded.png',
            width: 18,
            height: 18,
            color: _upvoted == true ? Constants.upvoteColor : Constants.secondaryTextColor,
          ),
          onPressed: () {
            // setState(() {
            //   _upvoted = _upvoted == true ? null : true;
            // });
          },
        ),
        Text(
          widget.score,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _upvoted == true ? Constants.upvoteColor : _upvoted == false ? Constants.downvoteColor : Constants.secondaryTextColor,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero
          ),
          icon: Image.asset(
            'assets/arrow_drop_down_rounded.png',
            width: 18,
            height: 18,
            color: _upvoted == false ? Constants.downvoteColor : Constants.secondaryTextColor
          ),
          onPressed: () {
            // setState(()  {
            //   _upvoted = _upvoted == false ? null : false;
            // });
          },
        )
      ],
    );
  }

}