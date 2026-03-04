import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart' hide RefreshCallback;
import 'package:lurk/widgets/feed_list.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class FeedScreen<T> extends StatefulWidget {

  final GlobalKey<MainScaffoldState>? scaffoldKey;
  final PlatformContext platformContext;
  final Community? activeCommunity;
  final bool isUserCurated;
  final FeedOptionsGroup? feedOptions;
  final Future<PagedItems<T>>? initialItems;
  final Future<PagedItems<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) fetchItems;
  final Widget? title;
  final String? subtitle;
  final bool showFeedOptionsSubtitle;
  final List<Widget>? iconActions;
  final bool Function(LoggedInUser user)? userFilter;
  final (Listenable, List<Widget> Function(BuildContext context))? iconActionsBuilder;
  final Map<Widget, Function(BuildContext context)>? popupMenuActions;
  final PreferredSizeWidget? flexibleSpaceHeader;
  final List<Widget>? slivers;
  final Widget? Function(BuildContext context)? bottomSheetBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;
  final Widget? Function(BuildContext context, int index, T item) itemBuilder;

  const FeedScreen({
    super.key,
    this.scaffoldKey,
    required this.platformContext,
    this.activeCommunity,
    this.isUserCurated = false,
    this.feedOptions,
    this.initialItems,
    required this.fetchItems,
    required this.title,
    this.subtitle,
    this.showFeedOptionsSubtitle = true,
    this.iconActions,
    this.userFilter,
    this.iconActionsBuilder,
    this.popupMenuActions,
    this.flexibleSpaceHeader,
    this.slivers,
    this.bottomSheetBuilder,
    required this.noItemsBuilder,
    required this.itemBuilder,
  });

  @override
  State<FeedScreen<T>> createState() => FeedScreenState<T>();

}

class FeedScreenState<T> extends State<FeedScreen<T>> with SingleTickerProviderStateMixin {

  late final ValueListenable<LoggedInUser?> _activeUserListenable;
  late List<GlobalKey<FeedListState<T>>> _feedListKeys;
  late List<GlobalKey<CustomRefreshIndicatorState>> _refreshIndicatorKeys;
  late List<ScrollController> _scrollControllers;
  TabController? _tabController;
  late List<Map<FeedOptionType, FeedOption>?> _selectedFeedOptions;

  @override
  void initState() {
    super.initState();
    _activeUserListenable = UserManager.getActiveUserListenable(widget.platformContext.platform);
    _activeUserListenable.addListener(_onActiveUserChanged);
    if (widget.feedOptions != null && widget.feedOptions!.type == FeedOptionType.category && widget.feedOptions!.options.length <= 3) {
      _tabController = TabController(
        length: widget.feedOptions!.options.length,
        vsync: this,
      );
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
    } else {
      _feedListKeys = [GlobalKey<FeedListState<T>>()];
      _refreshIndicatorKeys = [GlobalKey<CustomRefreshIndicatorState>()];
      _scrollControllers = [ScrollController()];
      _selectedFeedOptions = [widget.feedOptions?.defaults];
    }
  }

  @override
  void dispose() {
    _activeUserListenable.removeListener(_onActiveUserChanged);
    _tabController?.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onActiveUserChanged() {
    if (widget.isUserCurated) {
      reload();
    }
    else {
      refresh();
    }
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
    if (_tabController != null) {
      final List<Widget> tabs = [];
      final List<Widget> pages = [];
      for (var i = 0; i < widget.feedOptions!.options.length; i++) {
        final option = widget.feedOptions!.options[i];
        tabs.add(Tab(text: option.label));
        pages.add(
          _TabPage(
            controller: _scrollControllers[i],
            refreshIndicatorKey: _refreshIndicatorKeys[i],
            feedListKey: _feedListKeys[i],
            initialItems: i == 0 ? widget.initialItems : null,
            fetchItems: (pageToken) {
              return widget.fetchItems(
                {
                  FeedOptionType.category: widget.feedOptions!.options[i],
                  ...?_selectedFeedOptions[i],
                },
                pageToken
              );
            },
            noItemsBuilder: widget.noItemsBuilder,
            itemBuilder: widget.itemBuilder,
            onRefresh: () async {
              if (i == _tabController!.index) { // TODO
                await _refresh(i);
              }
            }
          )
        );
      }
      final rowChildren = [
        if (widget.subtitle != null)
          Text(widget.subtitle!),
        if (widget.showFeedOptionsSubtitle && widget.feedOptions != null)
          ValueListenableBuilder(
              valueListenable: _tabController!.animation!,
              builder: (context, value, child) {
                final index = value.round();
                final feedOptionsAtScrollIndex = widget.feedOptions!.options[index].subGroup;
                if (feedOptionsAtScrollIndex == null) {
                  return const SizedBox.shrink();
                }
                return Opacity(
                  opacity: (1.0 - ((value - index).abs() * 2)).clamp(0.0, 1.0),
                  child: Text('${widget.subtitle != null ? Constants.separator : ''}${_getSubtitle(_selectedFeedOptions[index] ?? feedOptionsAtScrollIndex.defaults)}'),
                );
              },
            ),
      ];
      return MainScaffold(
        key: widget.scaffoldKey,
        platformContext: widget.platformContext,
        activeCommunity: widget.activeCommunity,
        title: widget.title,
        subtitle: rowChildren.isNotEmpty ? Row(children: rowChildren) : null,
        userFilter: widget.userFilter,
        iconActions: widget.iconActions,
        iconActionsBuilder: (
          Listenable.merge([
            _tabController!.animation!,
            widget.iconActionsBuilder?.$1,
          ]),
          (context) {
            final visibleIndex = _tabController!.animation!.value.round();
            final subGroupOptions = widget.feedOptions!.options[visibleIndex].subGroup;
            return [
              ...?widget.iconActionsBuilder?.$2(context),
              if (subGroupOptions != null)
                _FeedFilterIconButton(
                  platformContext: widget.platformContext,
                  feedOptions: subGroupOptions,
                  selectedFeedOptions: _selectedFeedOptions[visibleIndex],
                  onFeedOptionsSelected: _onFeedOptionsSelected,
                ),
              ];
          },
        ),
        popupMenuActions: widget.popupMenuActions,
        sliverAppBarBottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: ValueListenableBuilder(
            valueListenable: Settings.appBarColor,
            builder: (context, appBarColor, child) {
              return DecoratedBox(
                decoration: BoxDecoration(color: appBarColor),
                child: TabBar(
                  controller: _tabController,
                  tabs: tabs,
                  unselectedLabelColor: appBarColor.contrast,
                ),
              );
            },
          ),
        ),
        sliverAppBarFlexibleBackground: widget.flexibleSpaceHeader,
        slivers: widget.slivers,
        bottomSheetBuilder: widget.bottomSheetBuilder,
        body: TabBarView(
          controller: _tabController,
          children: pages
        ),
        onOtherRefresh: () {
          final index = _tabController!.index;
          _refreshIndicatorKeys[index].currentState?.show();
          return _scrollControllers[index];
        },
      );
    }
    final selectedFeedOptions = _selectedFeedOptions[0];
    final List<String> subtitles = [
      ?widget.subtitle,
      if (widget.showFeedOptionsSubtitle && widget.feedOptions != null && selectedFeedOptions != null && !mapEquals(selectedFeedOptions, widget.feedOptions!.defaults))
        _getSubtitle(selectedFeedOptions)
    ];
    return MainScaffold(
      key: widget.scaffoldKey,
      refreshIndicatorKey: _refreshIndicatorKeys[0],
      platformContext: widget.platformContext,
      activeCommunity: widget.activeCommunity,
      customScrollViewController: _scrollControllers[0],
      title: widget.title,
      subtitle: subtitles.isNotEmpty ? Text(subtitles.join(Constants.separator)) : null,
      userFilter: widget.userFilter,
      iconActionsBuilder: widget.iconActionsBuilder,
      iconActions: [
        ...?widget.iconActions,
        _FeedFilterIconButton(
          platformContext: widget.platformContext,
          feedOptions: widget.feedOptions,
          selectedFeedOptions: selectedFeedOptions,
          onFeedOptionsSelected: _onFeedOptionsSelected,
        ),
      ],
      popupMenuActions: widget.popupMenuActions,
      sliverAppBarFlexibleBackground: widget.flexibleSpaceHeader,
      slivers: [
        ...?widget.slivers,
        FeedList(
          key: _feedListKeys[0],
          initialItems: widget.initialItems,
          getItems: (String? pageToken) =>
              widget.fetchItems(_selectedFeedOptions[0], pageToken),
          noItemsBuilder: widget.noItemsBuilder,
          itemBuilder: widget.itemBuilder,
        ),
      ],
      bottomSheetBuilder: widget.bottomSheetBuilder,
      onPullRefresh: () => _refresh(0),
      onOtherRefresh: () {
        _refreshIndicatorKeys[0].currentState?.show();
        return null;
      },
    );
  }

}

class _TabPage<T> extends StatefulWidget {

  final ScrollController controller;
  final GlobalKey<CustomRefreshIndicatorState> refreshIndicatorKey;
  final GlobalKey<FeedListState> feedListKey;
  final Future<PagedItems<T>>? initialItems;
  final Future<PagedItems<T>> Function(String? pageToken) fetchItems;
  final Widget Function(BuildContext context) noItemsBuilder;
  final Widget? Function(BuildContext context, int index, T item) itemBuilder;
  final RefreshCallback onRefresh;

  const _TabPage({
    required this.controller,
    required this.refreshIndicatorKey,
    required this.feedListKey,
    required this.initialItems,
    required this.fetchItems, 
    required this.noItemsBuilder,
    required this.itemBuilder,
    required this.onRefresh,  
  });

  @override
  State<_TabPage<T>> createState() => _TabPageState<T>();

}

class _TabPageState<T> extends State<_TabPage<T>> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final overlapAbsorberHandle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return CustomRefreshIndicator(
      key: widget.refreshIndicatorKey,
      edgeOffset: overlapAbsorberHandle.layoutExtent ?? 0,
      onRefresh: widget.onRefresh,
      child: Scrollbar(
        controller: widget.controller,
        interactive: false,
        child: CustomScrollView(
        // controller: widget.controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverOverlapInjector(handle: overlapAbsorberHandle),
            FeedList(
              key: widget.feedListKey,
              initialItems: widget.initialItems,
              getItems: widget.fetchItems,
              noItemsBuilder: widget.noItemsBuilder,
              itemBuilder: widget.itemBuilder,
            ),
          ],
        ),
      ),
    );
  }

}


class _FeedFilterIconButton extends StatelessWidget {

  final PlatformContext platformContext;
  final FeedOptionsGroup? feedOptions;
  final Map<FeedOptionType, FeedOption>? selectedFeedOptions;
  final Function(Map<FeedOptionType, FeedOption>) onFeedOptionsSelected;

  const _FeedFilterIconButton({
    required this.platformContext,
    required this.feedOptions,
    required this.selectedFeedOptions,
    required this.onFeedOptionsSelected
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Filter',
      iconSize: 26,
      onPressed: feedOptions != null
        ? () {
            final activeUser = UserManager.getActiveUser(platformContext.platform);
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FeedOptionsSelector(
                      optionsGroup: feedOptions!,
                      selected: selectedFeedOptions,
                      isLoggedIn: activeUser != null,
                      onSelected: (options) {
                        onFeedOptionsSelected(options);
                        context.pop();
                      }
                    ),
                  ),
                );
              }
            );
          }
        : null,
    );
  }

}

class _FeedOptionsSelector extends StatefulWidget {

  final FeedOptionsGroup optionsGroup;
  final Map<FeedOptionType, FeedOption>? selected;
  final bool isLoggedIn;
  final Function(Map<FeedOptionType, FeedOption>) onSelected;

  const _FeedOptionsSelector({
    required this.optionsGroup,
    required this.selected,
    required this.isLoggedIn,
    required this.onSelected
  });

  @override
  State<_FeedOptionsSelector> createState() => _FeedOptionsSelectorState();
  
}

class _FeedOptionsSelectorState extends State<_FeedOptionsSelector> {

  late final List<(FeedOptionType, FeedOption)> _selected;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _selected = widget.selected!.entries.map((entry) => (entry.key, entry.value)).toList();
    }
    else {
      // _selected = [(widget.optionsGroup.type, widget.optionsGroup.options.first)];
      _selected = [];
      void addDefaultSelection(FeedOptionsGroup group) {
        final firstOption = group.options.first;
        _selected.add((group.type, firstOption));
        if (firstOption.subGroup != null) {
          addDefaultSelection(firstOption.subGroup!);
        }
      }
      addDefaultSelection(widget.optionsGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FeedOptionsGroup> toShow = [widget.optionsGroup];
    for (var selection in _selected) {
      final option = selection.$2;
      if (option.subGroup != null) {
        toShow.add(option.subGroup!);
      }
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubicEmphasized,
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(toShow.length, (index) {
            final group = toShow[index];
            final List<Widget> chips = [];
            for (final option in group.options) {
              if (!option.requiresLogin || widget.isLoggedIn) {
                final isSelected = _selected.length > index && _selected[index].$2 == option;
                chips.add(
                  ChoiceChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(option.label),
                    selected: isSelected,
                    labelStyle: isSelected ? null : TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    onSelected: (selected) {
                      if (selected) {
                        if (_selected.length > index) {
                          _selected.removeRange(index, _selected.length);
                        }
                        _selected.add((group.type, option));
                        if (option.subGroup != null) {
                          setState(() {});
                        }
                        else {
                          widget.onSelected({for (var item in _selected) item.$1: item.$2});
                        }
                      }
                    },
                  )
                );
              }
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(32, index == 0 ? 0 : 16, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (group.type.label != null)
                    Padding(
                      padding: EdgeInsetsGeometry.only(bottom: 4),
                      child: Text(
                        group.type.label!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        )
                      )
                    ),
                  Wrap(
                    spacing: Constants.choiceChipGapSize,
                    runSpacing: Constants.choiceChipGapSize,
                    children: chips,
                  )
                ],
              )
            );
          }),
        ]
      ),
    );
  }

}
