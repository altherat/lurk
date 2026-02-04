import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/feed_option_selector.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class SimpleFeedScreen<T, U> extends StatefulWidget {

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Platform platform;
  final String? activeCommunityName;
  final FeedOptionsGroup? feedOptions;
  final FeedResponse<T, U> Function(Map<FeedOptionType, FeedOption>? feedOptions)? getAll;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final Widget title;
  final PreferredSizeWidget Function(BuildContext context, LoadingState loadingState, U? otherData)? persistentHeaderBuilder;
  final Widget? Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;

  const SimpleFeedScreen({
    super.key,
    this.scaffoldKey,
    required this.platform,
    this.activeCommunityName,
    this.feedOptions,
    this.getAll,
    required this.getItems,
    required this.title,
    this.persistentHeaderBuilder,
    required this.itemBuilder,
    required this.noItemsBuilder,
  });

  @override
  State<SimpleFeedScreen<T, U>> createState() => SimpleFeedScreenState<T, U>();

}

class SimpleFeedScreenState<T, U> extends State<SimpleFeedScreen<T, U>> with SingleTickerProviderStateMixin {

  late List<GlobalKey<_ContentState>> _contentKeys;
  TabController? _tabController;
  late List<Map<FeedOptionType, FeedOption>?> _selectedFeedOptions;
  LoadingState _otherDataLoadingState = LoadingState.loading;
  U? _otherData;

  @override
  void initState() {
    super.initState();
    if (widget.feedOptions?.type == FeedOptionType.category) {
       _tabController = TabController(length: widget.feedOptions!.options.length, vsync: this);
       _contentKeys = [];
       _selectedFeedOptions = [];
       for (var i = 0; i < widget.feedOptions!.options.length; i++) {
          _contentKeys.add(GlobalKey<_ContentState>());
          _selectedFeedOptions.add(null);
       }
    }
    else {
      _contentKeys = [GlobalKey<_ContentState>()];
      _selectedFeedOptions = [null];
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void reload() => _contentKeys[_tabController?.index ?? 0].currentState?._reload();

  void _onOtherDataUpdate(LoadingState loadingState, U? otherData) {
    setState(() {
      _otherDataLoadingState = loadingState;
      _otherData = otherData;
    });
  }
  
  void _onFeedOptionsSelected(Map<FeedOptionType, FeedOption>? options) {
    setState(() {
      _selectedFeedOptions[_tabController?.index ?? 0] = mapEquals(options, widget.feedOptions!.defaults) ? null : options;
    });
  }

  String _getSubtitle(Map<FeedOptionType, FeedOption> selectedOptions) => selectedOptions.values.map((o) => o.description.toLowerCase()).join(' / ');

  @override
  Widget build(BuildContext context) {
    final FeedOptionsGroup? feedOptions;
    final Map<FeedOptionType, FeedOption>? selectedFeedOptions;
    final Widget? subtitle;
    final List<Widget> iconActions;
    final (ValueListenable<double>, List<Widget> Function(BuildContext, double))? iconActionsBuilder;
    final PreferredSizeWidget? sliverAppbarBottom;
    final PreferredSizeWidget? sliverAppBarFlexibleBackground;
    final List<Widget>? slivers;
    final Widget? body;
    if (widget.feedOptions?.type == FeedOptionType.category) {
      feedOptions = widget.feedOptions!.options[_tabController!.index].subGroup;
      selectedFeedOptions = _selectedFeedOptions[_tabController!.index];
      subtitle = ValueListenableBuilder(
        valueListenable: _tabController!.animation!,
        builder: (context, value, child) {
          final index = value.round();
          final feedOptionsAtScrollIndex = widget.feedOptions!.options[index].subGroup;
          if (feedOptionsAtScrollIndex == null) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: (1.0 - ((value - index).abs() * 2)).clamp(0.0, 1.0),
            child: Text(_getSubtitle(_selectedFeedOptions[index] ?? feedOptionsAtScrollIndex.defaults))
          );
        }
      );
      iconActions = [];
      iconActionsBuilder = (_tabController!.animation!, (context, value) {
        final visibleIndex = value.round();
        final subGroupOptions = widget.feedOptions!.options[visibleIndex].subGroup;
        if (subGroupOptions == null) return [];
        return [
          FeedFilterIconButton(
            platform: widget.platform,
            feedOptions: subGroupOptions,
            selectedFeedOptions: _selectedFeedOptions[visibleIndex],
            onFeedOptionsSelected: _onFeedOptionsSelected
          )
        ];
      });
      final List<Widget> tabs = [];
      final List<Widget> pages = [];
      for (var i = 0; i < widget.feedOptions!.options.length; i++) {
        final option = widget.feedOptions!.options[i];
        tabs.add(Tab(text: option.label));
        pages.add(
          Builder(
            builder: (context) {
              final overlapAbsorberHandle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
              return CustomRefreshIndicator(
                platform: widget.platform,
                edgeOffset: overlapAbsorberHandle.layoutExtent ?? 0, 
                onRefresh: () async {

                },
                child: Scrollbar(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverOverlapInjector(handle: overlapAbsorberHandle),
                      _Content<T, U>(
                        key: _contentKeys[i],
                        platform: widget.platform,
                        feedOptions: {
                          FeedOptionType.category: widget.feedOptions!.options[i],
                          ...?_selectedFeedOptions[i]
                        },
                        getAll: widget.getAll,
                        getItems: widget.getItems,
                        itemBuilder: widget.itemBuilder,
                        noItemsBuilder: widget.noItemsBuilder,
                        onOtherData: _onOtherDataUpdate,
                      ),
                    ]
                  ),
                ),
              );
            }
          )
        );
      }
      sliverAppbarBottom = PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: ValueListenableBuilder(
          valueListenable: Settings.appBarColor,
          builder: (context, appBarColor, child) {
            return ValueListenableBuilder(
              valueListenable: Settings.showPlatformColorAccents,
              builder: (context, showPlatformColorAccents, child) {
                final color = showPlatformColorAccents ? widget.platform.color : null;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: appBarColor
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: tabs,
                    labelColor: color,
                    indicatorColor: color,
                    unselectedLabelColor: appBarColor.contrast,
                  ),
                );
              }
            );
          }
        ),
      );
      sliverAppBarFlexibleBackground = widget.persistentHeaderBuilder != null ? widget.persistentHeaderBuilder!(context, _otherDataLoadingState, _otherData) : null;
      slivers = null;
      body = TabBarView(
        controller: _tabController,
        children: pages,
      );
    }
    else {
      feedOptions = widget.feedOptions;
      selectedFeedOptions = _selectedFeedOptions[0];
      subtitle = (feedOptions != null && selectedFeedOptions != null && !mapEquals(selectedFeedOptions, feedOptions.defaults)) ? Text(_getSubtitle(selectedFeedOptions)) : null;
      // subtitle = _getFilterSubtitle(feedOptions, selectedFeedOptions);
      iconActions = [
        FeedFilterIconButton(
          platform: widget.platform,
          feedOptions: feedOptions,
          selectedFeedOptions: selectedFeedOptions,
          onFeedOptionsSelected: _onFeedOptionsSelected
        )
      ];
      iconActionsBuilder = null;
      sliverAppbarBottom = null;
      sliverAppBarFlexibleBackground = null;
      slivers = [
        _Content<T, U>(
          key: _contentKeys[0],
          platform: widget.platform,
          feedOptions: _selectedFeedOptions[0],
          getAll: widget.getAll,
          getItems: widget.getItems,
          itemBuilder: widget.itemBuilder,
          noItemsBuilder: widget.noItemsBuilder,
          onOtherData: _onOtherDataUpdate,
        )
      ];
      body = null;
    }
    return MainScaffold(
      scaffoldKey: widget.scaffoldKey,
      platform: widget.platform,
      activeCommunityName: widget.activeCommunityName,
      title: widget.title,
      subtitle: subtitle,
      iconActions: iconActions,
      iconActionsBuilder: iconActionsBuilder,
      sliverAppBarBottom: sliverAppbarBottom,
      sliverAppBarFlexibleBackground: sliverAppBarFlexibleBackground,
      slivers: slivers,
      body: body,
      onButtonRefresh: () {
        
      },
      onPullRefresh: () async {

      },
    );
  }

}

class _Content<T, U> extends StatefulWidget {

  final Platform platform;
  final Map<FeedOptionType, FeedOption>? feedOptions;
  final FeedResponse<T, U> Function(Map<FeedOptionType, FeedOption>? feedOptions)? getAll;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final Widget? Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;
  final Function(LoadingState loadingState, U? otherData) onOtherData;

  const _Content({
    super.key,
    required this.platform,
    required this.feedOptions,
    required this.getAll,
    required this.getItems,
    required this.itemBuilder,
    required this.noItemsBuilder,
    required this.onOtherData,
  });

  @override
  State<_Content<T, U>> createState() => _ContentState<T, U>();

}

class _ContentState<T, U> extends State<_Content<T, U>> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  List<T> _items = [];
  String? _pageToken;
  LoadingState _loadingState = LoadingState.loading;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: Constants.feedLoadAnimationDuration
    );
    _get();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _Content<T, U> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(widget.feedOptions, oldWidget.feedOptions)) {
      _reload();
    }
  }

  void _reload() {
    _items.clear();
    _setLoading();
    _get();
    _animationController.reset();
  }

  void _setLoading() {
    setState(() {
      _loadingState = LoadingState.loading;
    });
  }

  Future<void> _get() {
    final List<Future> futures = [];
    if (widget.getAll != null) {
      final response = widget.getAll!(widget.feedOptions);
      futures.add(
        response.items
          .then(_onResult)
          .onError(_onItemsError)
      );
      if (response.other != null) {
        futures.add(
          response.other!
            .then((other) {
              if (!mounted) return;
              widget.onOtherData(LoadingState.success, other);
            })
            .onError((exception, stackTrace) {
              if (_onError(exception, stackTrace)) {
                widget.onOtherData(LoadingState.error, null);
              }
            })
        );
      }
    }
    else {
      futures.add(
        widget.getItems(widget.feedOptions, null)
          .then(_onResult)
          .onError(_onItemsError)
      );
    }
    return Future.wait(futures);
  }

  void _getMore() {
    _loadingState = LoadingState.loading;
    widget.getItems(widget.feedOptions, _pageToken)
      .then((reuslt) {
        if (!mounted) return;
        setState(() {
          _items.addAll(reuslt.items);
          _pageToken = reuslt.pageToken;
          _loadingState = LoadingState.success;
        });
      })
      .onError(_onItemsError);
  }

  void _onResult(PagedResult<T> result) {
    if (!mounted) return;
    setState(() {
      _items = result.items;
      _pageToken = result.pageToken;
      _loadingState = LoadingState.success;
      _animationController.forward();
    });
  }

  Future<Null> _onItemsError(dynamic exception, dynamic stackTrace) {
    if (_onError(exception, stackTrace)) {
      setState(() {
        _loadingState = LoadingState.error;
      });
      if (_items.isNotEmpty) {
        context.showSnackBarMessage('Something went wrong');
      }
    }
    throw exception;
  }

  bool _onError(dynamic exception, dynamic stackTrace) {
    dev.log('Error fetching feed: $exception');
    dev.log(stackTrace.toString());
    return mounted;
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_items.isEmpty) {
      final Widget child;
      if (_loadingState == LoadingState.loading) {
        child = LargeCenteredCircularProgressIndicator(platform: widget.platform);
      }
      else if (_loadingState == LoadingState.error) {
        child = const LargeVerticalIconMessage(
          icon: Icons.feed_outlined,
          message: 'Something went wrong'
        );
      }
      else {
        child = widget.noItemsBuilder(context);
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: child
      );
    }
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: (_pageToken != null ? _items.length + 1 : _items.length),
            (context, index) {
              if (_pageToken != null && index == _items.length) {
                return CustomCircularProgressIndicator(
                  platform: widget.platform,
                  padding: EdgeInsets.all(16),
                  alignment: Alignment.center,
                  size: 24,
                  strokeWidth: 3,
                );
              }
              return FeedItemTransition(
                progress: _animationController.value,
                child: widget.itemBuilder(context, _items[index])!
              );
            }
          )
        );
      }
    );
  }

}

class FeedItemTransition extends StatelessWidget {

  final double progress;
  final Widget child;

  const FeedItemTransition({
    super.key,
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = Curves.easeIn.transform(progress);
    final double offsetY = 20 * (1.0 - Curves.easeInOutCubicEmphasized.transform(progress));
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: child,
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final double delay = (index * 0.05).clamp(0, 0.5);
  //   final CurvedAnimation staggeredAnimation = CurvedAnimation(
  //     parent: animation,
  //     curve: Interval(
  //       delay, 
  //       1, 
  //       curve: Curves.easeInOutCubicEmphasized
  //     ),
  //   );
  //   return FadeTransition(
  //     opacity: staggeredAnimation,
  //     child: SlideTransition(
  //       position: Tween<Offset>(
  //         begin: const Offset(0, 0.1),
  //         end: Offset.zero,
  //       ).animate(staggeredAnimation),
  //       child: child,
  //     ),
  //   );
  // }

}

// class FeedAnimatedSwitcher extends StatelessWidget {

//   final Widget child;

//   const FeedAnimatedSwitcher({
//     super.key,
//     required this.child
//   });

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: Constants.feedLoadAnimationDuration,
//       transitionBuilder: (Widget child, Animation<double> animation) {
//         return FadeTransition(
//           opacity: animation,
//           child: SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(0, 0.02),
//               end: Offset.zero,
//             ).animate(animation),
//             child: child,
//           ),
//         );
//       },
//       child: child
//     );
//   }

// }

enum LoadingState {
  loading,
  error,
  success
}