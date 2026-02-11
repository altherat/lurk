import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/feed_list.dart';
import 'package:lurk/widgets/feed_option_selector.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class SimpleFeedScreen<T> extends StatefulWidget {

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Platform platform;
  final Community? activeCommunity;
  final FeedOptionsGroup? feedOptions;
  final Future<PagedItems<T>>? initialItems;
  final Future<PagedItems<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final Widget? title;
  final Widget? subtitle;
  final bool showFeedOptionsSubtitle;
  final (Listenable, List<Widget> Function(BuildContext context))? iconActionsBuilder;
  final Map<String, void Function()>? popupMenuActions;
  final PreferredSizeWidget? flexibleSpaceHeader;
  final List<Widget>? slivers;
  final Widget? Function(BuildContext context)? bottomSheetBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;
  final Widget? Function(BuildContext context, int index, T item) itemBuilder;

  const SimpleFeedScreen({
    super.key,
    this.scaffoldKey,
    required this.platform,
    this.activeCommunity,
    this.feedOptions,
    this.initialItems,
    required this.getItems,
    required this.title,
    this.subtitle,
    this.showFeedOptionsSubtitle = true,
    this.iconActionsBuilder,
    this.popupMenuActions,
    this.flexibleSpaceHeader,
    this.slivers,
    this.bottomSheetBuilder,
    required this.noItemsBuilder,
    required this.itemBuilder,
  });

  @override
  State<SimpleFeedScreen<T>> createState() => SimpleFeedScreenState<T>();

}

class SimpleFeedScreenState<T> extends State<SimpleFeedScreen<T>> with SingleTickerProviderStateMixin {

  late List<GlobalKey<FeedListState<T>>> _feedListKeys;
  late List<GlobalKey<CustomRefreshIndicatorState>> _refreshIndicatorKeys;
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
          _feedListKeys.add(GlobalKey<FeedListState<T>>());
          _refreshIndicatorKeys.add(GlobalKey<CustomRefreshIndicatorState>());
          _scrollControllers.add(ScrollController());
          _selectedFeedOptions.add(widget.feedOptions?.options[i].subGroup?.defaults);
       }
    }
    else {
      _feedListKeys = [GlobalKey<FeedListState<T>>()];
      _refreshIndicatorKeys = [GlobalKey<CustomRefreshIndicatorState>()];
      _scrollControllers = [ScrollController()];
      _selectedFeedOptions = [widget.feedOptions?.defaults];
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

  FeedListState<T>? get feedList => _feedListKeys[_tabController?.index ?? 0].currentState;

  void reload() => _callOnFeedListState(_tabController?.index ?? 0, (state) => state.reload());

  void refresh() => _refreshIndicatorKeys[_tabController?.index ?? 0].currentState?.show();

  Future<void> _refresh(int index) => _callOnFeedListState(index, (state) => state.refresh());

  Future<void> _callOnFeedListState(int index, Function(FeedListState state) fn) async {
    final feedListState = feedList;
    if (feedListState != null) {
      await fn(feedListState);
    }
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
                key: _refreshIndicatorKeys[i],
                edgeOffset: overlapAbsorberHandle.layoutExtent ?? 0, 
                onRefresh: () => _refresh(i),
                child: Scrollbar(
                  controller: _scrollControllers[i],
                  interactive: false,
                  child: CustomScrollView(
                    controller: _scrollControllers[i],
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        itemBuilder: widget.itemBuilder
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
        activeCommunity: widget.activeCommunity,
        title: widget.title,
        subtitle: widget.subtitle ?? (
          widget.showFeedOptionsSubtitle
            ? ValueListenableBuilder(
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
              )
            : null
        ),
        iconActionsBuilder: (Listenable.merge([_tabController!.animation!, widget.iconActionsBuilder?.$1]), (context) {
          final visibleIndex = _tabController!.animation!.value.round();
          final subGroupOptions = widget.feedOptions!.options[visibleIndex].subGroup;
          if (subGroupOptions == null) return [];
          return [
            ...?widget.iconActionsBuilder?.$2(context),
            FeedFilterIconButton(
              platform: widget.platform,
              feedOptions: subGroupOptions,
              selectedFeedOptions: _selectedFeedOptions[visibleIndex],
              onFeedOptionsSelected: _onFeedOptionsSelected
            )
          ];
        }),
        popupMenuActions: widget.popupMenuActions,
        sliverAppBarBottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: ValueListenableBuilder(
            valueListenable: Settings.appBarColor,
            builder: (context, appBarColor, child) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: appBarColor
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: tabs,
                  unselectedLabelColor: appBarColor.contrast,
                ),
              );
            }
          ),
        ),
        sliverAppBarFlexibleBackground: widget.flexibleSpaceHeader,
        slivers: widget.slivers,
        bottomSheetBuilder: widget.bottomSheetBuilder,
        body: TabBarView(
          controller: _tabController,
          children: pages,
        ),
        onOtherRefresh: () {
          final index = _tabController!.index;
          _refreshIndicatorKeys[index].currentState?.show();
          return _scrollControllers[index];
        }
      );
    }
    final feedOptions = widget.feedOptions;
    final selectedFeedOptions = _selectedFeedOptions[0];
    return MainScaffold(
      scaffoldKey: widget.scaffoldKey,
      refreshIndicatorKey: _refreshIndicatorKeys[0],
      platform: widget.platform,
      activeCommunity: widget.activeCommunity,
      customScrollViewController: _scrollControllers[0],
      title: widget.title,
      subtitle: widget.subtitle ?? (widget.showFeedOptionsSubtitle && feedOptions != null && selectedFeedOptions != null && !mapEquals(selectedFeedOptions, feedOptions.defaults) ? Text(_getSubtitle(selectedFeedOptions)) : null),
      iconActionsBuilder: widget.iconActionsBuilder,
      iconActions: [
        FeedFilterIconButton(
          platform: widget.platform,
          feedOptions: feedOptions,
          selectedFeedOptions: selectedFeedOptions,
          onFeedOptionsSelected: _onFeedOptionsSelected
        )
      ],
      popupMenuActions: widget.popupMenuActions,
      sliverAppBarFlexibleBackground: widget.flexibleSpaceHeader,
      slivers: [
        ...?widget.slivers,
        FeedList(
          key: _feedListKeys[0],
          platform: widget.platform,
          initialItems: widget.initialItems,
          getItems: (String? pageToken) => widget.getItems(_selectedFeedOptions[0], pageToken),
          noItemsBuilder: widget.noItemsBuilder,
          itemBuilder: widget.itemBuilder
        )
      ],
      bottomSheetBuilder: widget.bottomSheetBuilder,
      onPullRefresh: () => _refresh(0),
      onOtherRefresh: () {
        _refreshIndicatorKeys[0].currentState?.show();
        return null;
      }
    );
  }

}