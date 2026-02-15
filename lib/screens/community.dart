import 'dart:developer' as dev;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/app.dart' as App;
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/simple_feed.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_html.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:lurk/widgets/prefixed_name.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/post_tile.dart';
import 'package:lurk/widgets/stat.dart';

class CommunityScreen extends StatefulWidget {

  final Community community;
  final GlobalKey<MainScaffoldState>? scaffoldKey;

  const CommunityScreen({super.key, required this.community, this.scaffoldKey});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();

}

class _CommunityScreenState extends State<CommunityScreen> with RouteAware {

  final _feedKey = GlobalKey<SimpleFeedScreenState>();
  bool _isSingleCommunity = false;

  @override
  initState() {
    super.initState();
    Settings.activeUser.addListener(_onActiveUserChanged);
  }

  @override
  void dispose() {
    Settings.activeUser.removeListener(_onActiveUserChanged);
    App.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    App.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    if (App.routeObserver.staleRoutes.remove(ModalRoute.of(context))) {
      _feedKey.currentState?.reload();
    }
  }

  void _onActiveUserChanged() {
    if (widget.community.platform == Settings.activeUser.value?.platform && widget.community.name == null) {
      _feedKey.currentState?.reload();
    } else {
      _feedKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleFeedScreen(
      key: _feedKey,
      scaffoldKey: widget.scaffoldKey,
      platform: widget.community.platform,
      getItems: (options, pageToken) async {
        final result = await widget.community.platform.api.getPosts(
          widget.community.name,
          options: options,
          pageToken: pageToken,
        );
        if (mounted) {
          setState(() {
            _isSingleCommunity = result.items.every(
              (post) => post.community.name == widget.community.name,
            );
          });
        }
        return result;
      },
      title: widget.community.name == null && widget.community.platform.rootCommunityName.isNotEmpty
        ? Text(widget.community.platform.rootCommunityName)
        : ValueListenableBuilder(
            valueListenable: Settings.showPlatformColorTextAccents,
            builder: (context, showPlatformColorTextAccents, child) {
              return PrefixedName(
                prefix: widget.community.platform.communityPrefix,
                name: widget.community.name,
                prefixColor: showPlatformColorTextAccents
                    ? widget.community.platform.color
                    : null,
                applyAppBarAlpha: true,
              );
            },
          ),
      iconActions: !widget.community.platform.aggregateCommunityNames.contains(widget.community.name)
        ? [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (context) => _CommunityInfoBottomSheet(community: widget.community)
                    );
                  },
                );
              }
            ),
          ]
        : null,
      activeCommunity: widget.community,
      feedOptions:(widget.community.name == null ? widget.community.platform.rootPostsFeedOptions : null) ?? widget.community.platform.postsFeedOptions,
      itemBuilder: (context, index, post) {
        return PostTile(
          post: post,
          showViewCommunityOption: post.community != widget.community,
          subtitle: PostTileCommentHistorySubtitle(
            post: post,
            extraTexts: [
              post.timeAgoCompact,
              if (!_isSingleCommunity) post.community.name!,
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
    required this.community
  });

  @override
  State<_CommunityInfoBottomSheet> createState() => _CommunityInfoBottomSheetState();

}

class _CommunityInfoBottomSheetState extends State<_CommunityInfoBottomSheet> {

  late Future<Community> _detailsFuture;
  bool? _isSubscribed;

  @override
  void initState() {
    super.initState();
    _detailsFuture = widget.community.platform.api.getCommunityDetails(widget.community.name!);
    _detailsFuture.then((community) {
      if (mounted) {
        setState(() {
          _isSubscribed = community.isSubscribed;
        });
      }
    });
  }

  Future<void> _toggleSubscription() async {
    try {
      if (_isSubscribed == true) {
        await widget.community.platform.api.unsubscribe(widget.community.id!);
        setState(() {
          _isSubscribed = false;
        });
      }
      else {
        await widget.community.platform.api.subscribe(widget.community.id!);
        setState(() {
          _isSubscribed = true;
        });
      }
    }
    catch (e) {
      dev.log('Error toggling subscription: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: FutureBuilder<Community>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 200,
              child: const LargeCenteredCircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: LargeVerticalIconMessage(
                icon: Icons.feed_outlined,
                message: 'Something went wrong',
              ),
            );
          }
      
          final community = snapshot.data!;
          final theme = Theme.of(context);
      
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (community.bannerUrl != null)
                ExtendedImage.network(
                  community.bannerUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (community.iconUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundImage: NetworkImage(
                                community.iconUrl!,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.title!,
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              PrefixedName(
                                prefix: community.platform.communityPrefix,
                                name: community.name,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (Settings.activeUser.value != null && community.platform.api.hasLogin) ...[
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: _toggleSubscription,
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
                          value: community.subscriberCount!.toCommaString(),
                          label: 'Subscribers',
                        ),
                        if (community.postCount != null) ...[
                          const SizedBox(width: 24),
                          Stat(
                            value: community.postCount!.toCommaString(),
                            label: 'Posts',
                          ),
                        ],
                        const SizedBox(width: 24),
                        Stat(
                          value: community.createdDate!.timeAgoLong,
                          label: 'Created',
                        ),
                      ],
                    ),
                    if (community.description != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'About',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        community.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (community.descriptionHtml != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      CustomHtml(
                        platform: community.platform,
                        html: community.descriptionHtml!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
