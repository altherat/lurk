import 'dart:developer' as dev;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
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

class CommunityScreen extends StatefulWidget {

  final Community community;
  final GlobalKey<MainScaffoldState>? scaffoldKey;

  const CommunityScreen({
    super.key,
    required this.community,
    this.scaffoldKey
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();

}

class _CommunityScreenState extends State<CommunityScreen> {

  @override
  Widget build(BuildContext context) {
    final isCurated = widget.community.name == null;
    final isCuratedAndPlatformSupportsMultipleHosts = isCurated && widget.community.platformContext.platform.supportsMultipleHosts;
    return FeedScreen(
      scaffoldKey: widget.scaffoldKey,
      platformContext: widget.community.platformContext,
      activeCommunityName: widget.community.nameAndMaybeHost,
      isCurated: isCurated,
      fetchItems: (options, pageToken) async {
        final result = await Platform.getApi(widget.community.platformContext, isCuratedAndPlatformSupportsMultipleHosts ? null : UserManager.getActiveUser(widget.community.platformContext.platform).value).fetchCommunityPosts(
          widget.community.nameAndMaybeHost,
          options: options,
          pageToken: pageToken,
        );
        return result;
      },
      title: isCurated && widget.community.platformContext.platform.rootCommunityName != null
        ? Text(widget.community.platformContext.platform.rootCommunityName!)
        : ValueListenableBuilder(
            valueListenable: Settings.showPlatformColorTextAccents,
            builder: (context, showPlatformColorTextAccents, child) {
              return CommunityNameText(
                community: widget.community,
                prefixColor: showPlatformColorTextAccents ? widget.community.platformContext.platform.color : null,
                applyAppBarAlpha: true,
              );
            },
          ),
      userFilter: isCuratedAndPlatformSupportsMultipleHosts ? (user) => user.platformContext.host == widget.community.platformContext.host : null,
      popupMenuActions: !isCurated && !(widget.community.platformContext.platform.aggregateCommunityNames?.contains(widget.community.name) ?? false)
        ? {
            Text('Info'): (context) => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) {
                return _CommunityInfoBottomSheet(community: widget.community);
              }
            ),
          }
        : null,
      feedOptions:(isCurated ? widget.community.platformContext.platform.curatedPostsFeedOptions : null) ?? widget.community.platformContext.platform.postsFeedOptions,
      itemBuilder: (context, index, post) {
        return PostTile(
          post: post,
          showViewCommunityOption: post.community != widget.community,
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

  final Community community;

  const _CommunityInfoBottomSheet({
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
    _detailsFuture = Platform.getApi(widget.community.platformContext, UserManager.getActiveUser(widget.community.platformContext.platform).value).fetchCommunityDetails(widget.community.name!);
    _detailsFuture.then((details) {
      final activeUser = UserManager.getActiveUser(widget.community.platformContext.platform).value;
      if (activeUser != null && mounted) {
        setState(() {
          _isSubscribed = Communities.isSubscribed(widget.community.platformContext.platform, activeUser.id, widget.community.name!);
        });
      }
    });
  }

  Future<void> _toggleSubscription(String userId, String communityId) async {
    final activeUser = UserManager.getActiveUser(widget.community.platformContext.platform).value;
    try {
      if (_isSubscribed!) {
        setState(() {
          _isSubscribed = false;
        });
        await Platform.getApi(widget.community.platformContext, activeUser).unsubscribeFromCommunity(widget.community.name!, communityId);
      }
      else {
        setState(() {
          _isSubscribed = true;
        });
        await Platform.getApi(widget.community.platformContext, activeUser).subscribeToCommunity(widget.community.name!, communityId);
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
                              strokeWidth: 5,
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
                    valueListenable: UserManager.getActiveUser(widget.community.platformContext.platform),
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
                                              strokeWidth: 4,
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
                              onTap: () => _toggleSubscription(activeUser.id, details.id!),
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
                              platformContext: details.community.platformContext,
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
