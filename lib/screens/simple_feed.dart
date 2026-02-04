import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/feed_list.dart';
import 'package:lurk/widgets/feed_option_selector.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class SimpleFeedScreen<T> extends StatefulWidget {

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Platform platform;
  final String? activeCommunityName;
  final FeedOptionsGroup? feedOptions;
  final Future<PagedItems<T>>? initialItems;
  final Future<PagedItems<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final Widget title;
  final PreferredSizeWidget? flexibleSpaceHeader;
  final List<Widget>? slivers;
  final Widget? Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;

  const SimpleFeedScreen({
    super.key,
    this.scaffoldKey,
    required this.platform,
    this.activeCommunityName,
    this.feedOptions,
    this.flexibleSpaceHeader,
    this.slivers,
    this.initialItems,
    required this.getItems,
    required this.title,
    required this.itemBuilder,
    required this.noItemsBuilder,
  });

  @override
  State<SimpleFeedScreen<T>> createState() => SimpleFeedScreenState<T>();

}

class SimpleFeedScreenState<T> extends State<SimpleFeedScreen<T>> with SingleTickerProviderStateMixin {

  late List<GlobalKey<FeedListState>> _feedListKeys;
  late List<GlobalKey<RefreshIndicatorState>> _refreshIndicatorKeys;
  late List<ScrollController> _scrollControllers;
  TabController? _tabController;
  late List<Map<FeedOptionType, FeedOption>?> _selectedFeedOptions;

  @override
  void initState() {
    super.initState();
    if (widget.feedOptions?.type == FeedOptionType.category) {
       _tabController = TabController(length: widget.feedOptions!.options.length, vsync: this);
       _feedListKeys = [];
       _refreshIndicatorKeys = [];
       _scrollControllers = [];
       _selectedFeedOptions = [];
       for (var i = 0; i < widget.feedOptions!.options.length; i++) {
          _feedListKeys.add(GlobalKey<FeedListState>());
          _refreshIndicatorKeys.add(GlobalKey<RefreshIndicatorState>());
          _scrollControllers.add(ScrollController());
          _selectedFeedOptions.add(null);
       }
    }
    else {
      _feedListKeys = [GlobalKey<FeedListState>()];
      _refreshIndicatorKeys = [GlobalKey<RefreshIndicatorState>()];
      _scrollControllers = [ScrollController()];
      _selectedFeedOptions = [null];
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> reload() => _callOnFeedListState((state) => state.reload());

  Future<void> _refresh() => _callOnFeedListState((state) => state.refresh());

  Future<void> _callOnFeedListState(Function(FeedListState state) fn) async {
    final feedListState = _feedListKeys[_tabController?.index ?? 0].currentState;
    if (feedListState != null) {
      await fn(feedListState);
    }
  }

  void _onOtherRefresh() {
    _scrollControllers[_tabController!.index].animateTo(
      0, 
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeInOutCubicEmphasized
    );
    _refresh();
  }
  
  void _onFeedOptionsSelected(Map<FeedOptionType, FeedOption>? options) {
    setState(() {
      _selectedFeedOptions[_tabController?.index ?? 0] = mapEquals(options, widget.feedOptions!.defaults) ? null : options;
    });
    reload();
  }

  String _getSubtitle(Map<FeedOptionType, FeedOption> selectedOptions) => selectedOptions.values.map((o) => o.description.toLowerCase()).join(' / ');

  @override
  Widget build(BuildContext context) {
    if (widget.feedOptions?.type == FeedOptionType.category) {
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
                onRefresh: _refresh,
                child: Scrollbar(
                  controller: _scrollControllers[i],
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollControllers[i],
                    primary: false,
                    slivers: [
                      SliverOverlapInjector(handle: overlapAbsorberHandle),
                      FeedList(
                        key: _feedListKeys[i],
                        platform: widget.platform,
                        initialItems: i == 0 ? widget.initialItems : null,
                        getItems: (String? pageToken) async {
                          return widget.getItems(
                            {
                              FeedOptionType.category: widget.feedOptions!.options[i],
                              ...?_selectedFeedOptions[i]
                            },
                            pageToken
                          );
                        },
                        noItemsBuilder: widget.noItemsBuilder,
                        itemBuilder: (context, index, T item) => widget.itemBuilder(context, item)
                      )
                    ]
                  ),
                ),
              );
            }
          )
        );
      }
      return MainScaffold(
        scaffoldKey: widget.scaffoldKey,
        platform: widget.platform,
        activeCommunityName: widget.activeCommunityName,
        title: widget.title,
        subtitle: ValueListenableBuilder(
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
        ),
        iconActionsBuilder: (_tabController!.animation!, (context) {
          final visibleIndex = _tabController!.animation!.value.round();
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
        }),
        sliverAppBarBottom: PreferredSize(
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
        ),
        sliverAppBarFlexibleBackground: widget.flexibleSpaceHeader,
        slivers: widget.slivers,
        body: TabBarView(
          controller: _tabController,
          children: pages,
        ),
        onOtherRefresh: _onOtherRefresh,
      );
    }
    final feedOptions = widget.feedOptions;
    final selectedFeedOptions = _selectedFeedOptions[0];
    return MainScaffold(
      scaffoldKey: widget.scaffoldKey,
      refreshIndicatorKey: _refreshIndicatorKeys[0],
      platform: widget.platform,
      activeCommunityName: widget.activeCommunityName,
      customScrollViewController: _scrollControllers[0],
      title: widget.title,
      subtitle: (feedOptions != null && selectedFeedOptions != null && !mapEquals(selectedFeedOptions, feedOptions.defaults)) ? Text(_getSubtitle(selectedFeedOptions)) : null,
      iconActions: [
        FeedFilterIconButton(
          platform: widget.platform,
          feedOptions: feedOptions,
          selectedFeedOptions: selectedFeedOptions,
          onFeedOptionsSelected: _onFeedOptionsSelected
        )
      ],
      sliverAppBarFlexibleBackground: widget.flexibleSpaceHeader,
      slivers: [
        ...?widget.slivers,
        FeedList(
          key: _feedListKeys[0],
          platform: widget.platform,
          initialItems: widget.initialItems,
          getItems: (String? pageToken) => widget.getItems(_selectedFeedOptions[0], pageToken),
          noItemsBuilder: widget.noItemsBuilder,
          itemBuilder: (context, index, T item) => widget.itemBuilder(context, item)
        )
      ],
      onPullRefresh: _refresh,
      onOtherRefresh: _onOtherRefresh
    );
  }

}