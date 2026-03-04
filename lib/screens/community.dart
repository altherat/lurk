import 'dart:developer' as dev;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/services/communities.dart';
import 'package:lurk/screens/feed.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/custom_html.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:lurk/widgets/name_text.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/stat.dart';

class CommunityScreen extends StatelessWidget {

  final Community community;
  final GlobalKey<MainScaffoldState>? scaffoldKey;

  const CommunityScreen({
    super.key,
    required this.community,
    this.scaffoldKey
  });

  @override
  Widget build(BuildContext context) {
    final platformContext = PlatformContext.fromCommunity(community);
    final isUserCurated = community.name == null;
    return FeedScreen(
      scaffoldKey: scaffoldKey,
      platformContext: platformContext,
      activeCommunity: community,
      isUserCurated: isUserCurated,
      fetchItems: (options, pageToken) => getApi(platformContext, UserManager.getActiveUser(community.platform, isUserCurated ? community.host : null)).fetchCommunityPosts(community.name != null ? community.nameAndMaybeHost : null, pageToken, options),
      title: isUserCurated && community.platform.rootCommunityName != null
        ? Text(community.platform.rootCommunityName!)
        : ValueListenableBuilder(
            valueListenable: Settings.showPlatformColorTextAccents,
            builder: (context, showPlatformColorTextAccents, child) {
              return CommunityNameText(
                community: community,
                prefixColor: showPlatformColorTextAccents ? community.platform.color : null,
                applyAppBarAlpha: true,
              );
            },
          ),
      userFilter: isUserCurated && community.platform.supportsMultipleHosts ? (user) => user.host == community.host : null,
      popupMenuActions: !isUserCurated && !(community.platform.aggregateCommunityNames?.contains(community.name) ?? false)
        ? {
            Text('Info'): (context) {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (context) {
                  return _CommunityInfoBottomSheet(
                    platformContext: platformContext,
                    community: community
                  );
                }
              );
            },
          }
        : null,
      feedOptions:(isUserCurated ? community.platform.curatedPostsFeedOptions : null) ?? community.platform.postsFeedOptions,
      itemBuilder: (context, index, post) {
        return PostTile(
          platformContext: platformContext,
          post: post,
          activeUserHostRestriction: isUserCurated ? community.host : null,
          showViewCommunityOption: post.community.host != community.host || post.community.name != community.name,
          subtitle: PostTileCommentHistorySubtitle(
            post: post,
            extraTexts: [
              post.timeAgoCompact,
              post.community.name!
            ],
          ),
        );
      },
      noItemsBuilder: (context) {
        return const LargeVerticalIconMessage(
          icon: Icons.feed_outlined,
          message: 'Nothing to show',
        );
      },
    );
  }
}

class _CommunityInfoBottomSheet extends StatefulWidget {

  final PlatformContext platformContext;
  final Community community;

  const _CommunityInfoBottomSheet({
    required this.platformContext,
    required this.community,
  });

  @override
  State<_CommunityInfoBottomSheet> createState() => _CommunityInfoBottomSheetState();

}

class _CommunityInfoBottomSheetState extends State<_CommunityInfoBottomSheet> {

  late Future<CommunityDetails> _detailsFuture;
  bool? _isSubscribed;

  @override
  void initState() {
    super.initState();
    _detailsFuture = getApi(widget.platformContext, UserManager.getActiveUser(widget.platformContext.platform)).fetchCommunityDetails(widget.community.nameAndMaybeHost!);
    _detailsFuture.then((details) {
      final activeUser = UserManager.getActiveUser(widget.platformContext.platform);
      if (activeUser != null && activeUser.platform == widget.platformContext.platform && mounted) {
        setState(() {
          _isSubscribed = Communities.isSubscribed(activeUser, widget.community.id!);
        });
      }
    });
  }

  Future<void> _toggleSubscription(String userId, String communityId) async {
    final activeUser = UserManager.getActiveUser(widget.platformContext.platform);
    try {
      if (_isSubscribed!) {
        setState(() {
          _isSubscribed = false;
        });
        await getApi(widget.platformContext, activeUser).unsubscribeFromCommunity(communityId);
      }
      else {
        setState(() {
          _isSubscribed = true;
        });
        await getApi(widget.platformContext, activeUser).subscribeToCommunity(communityId);
      }
    }
    catch (error, stackTrace) {
      dev.log('Error updating subscription', error: error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      constraints: BoxConstraints(
        minWidth: double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: FutureBuilder(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 200,
              child: const LargeCenteredCircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Container(
              height: 200,
              alignment: Alignment.center,
              child: VerticalIconMessage(
                icon: Icons.feed_outlined,
                message: 'Something went wrong',
                iconSize: 96,
                fontSize: 16
              ),
            );
          }
      
          final details = snapshot.data!;
          final theme = Theme.of(context);

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.bannerUrl != null)
                  DecoratedBox(
                    decoration: BoxDecoration(color: details.bannerBackgroundColorHexCode?.toColor()),
                    child: ExtendedImage.network(
                      details.bannerUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadStateChanged: (state) {
                        switch (state.extendedImageLoadState) {
                          case LoadState.loading:
                            return const CustomCircularProgressIndicator(
                              alignment: Alignment.center,
                              size: 48,
                              color: Colors.white,
                            );
                          default:
                            return null;
                        }
                      }
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValueListenableBuilder(
                    valueListenable: UserManager.getActiveUserListenable(widget.platformContext.platform),
                    builder: (context, activeUser, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (details.iconUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: details.primaryColorHexCode?.toColor()
                                    ),
                                    child: ExtendedImage.network(
                                      details.iconUrl!,
                                      fit: BoxFit.cover,
                                      shape: BoxShape.circle,
                                      loadStateChanged: (state) {
                                        switch (state.extendedImageLoadState) {
                                          case LoadState.loading:
                                            return const CustomCircularProgressIndicator(
                                              alignment: Alignment.center,
                                              size: 32,
                                              color: Colors.white,
                                            );
                                          default:
                                            return null;
                                        }
                                      }
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      details.title!,
                                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    CommunityNameText(community: details.community),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (activeUser != null) ...[
                            const SizedBox(height: 24),
                            InkWell(
                              onTap: () => _toggleSubscription(activeUser.id, widget.community.id!),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isSubscribed == true ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _isSubscribed == true ? Colors.transparent : theme.colorScheme.outline),
                                ),
                                child: Text(
                                  _isSubscribed == true ? 'Subscribed' : 'Subscribe',
                                  style: theme.textTheme.labelLarge?.copyWith(color: _isSubscribed == true ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Stat(
                                value: details.subscriberCount!.toCommaString(),
                                label: 'Subscribers',
                              ),
                              if (details.postCount != null) ...[
                                const SizedBox(width: 24),
                                Stat(
                                  value: details.postCount!.toCommaString(),
                                  label: 'Posts',
                                ),
                              ],
                              const SizedBox(width: 24),
                              Stat(
                                value: details.createdDate!.timeAgoLong,
                                label: 'Created',
                              ),
                            ],
                          ),
                          if (details.shortDescription != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              details.shortDescription!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          if (details.longDescriptionHtml != null) ...[
                            const SizedBox(height: 24),
                            CustomHtml(
                              platformContext: widget.platformContext,
                              html: details.longDescriptionHtml!,
                            ),
                          ],
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
