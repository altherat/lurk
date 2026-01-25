import 'dart:math';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/settings.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/community_name.dart';
import 'package:lurk/widgets/feed_option_selector.dart';
import 'package:lurk/widgets/custom_search_bar.dart';
import 'package:lurk/widgets/custom_app_bar.dart';

class MainScaffold extends StatefulWidget {

  final Platform? platform;
  final String? activeCommunityName;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? title;
  final Widget? subtitle;
  final List<Widget> iconActions;
  final Map<String, VoidCallback> popupMenuActions;
  final FeedOptionsGroup? feedOptions;
  final Map<FeedOptionType, FeedOption>? selectedFeedOptions;
  final bool useSlivers;
  final List<Widget> slivers;
  final Widget body;
  final VoidCallback? onRefresh;
  final Function(Map<FeedOptionType, FeedOption>)? onFeedOptionsSelected;

  const MainScaffold({
    super.key,
    this.platform,
    this.activeCommunityName,
    this.scaffoldKey,
    required this.title,
    this.subtitle,
    this.iconActions = const [],
    this.popupMenuActions = const {},
    this.feedOptions,
    this.selectedFeedOptions,
    this.useSlivers = false,
    this.slivers = const [],
    required this.body,
    this.onRefresh,
    this.onFeedOptionsSelected
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();

}

class _MainScaffoldState extends State<MainScaffold> {

  final ValueNotifier<bool> _isBottomBarVisible = ValueNotifier<bool>(true);
  final ScrollController _scrollController = ScrollController();
  late GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void initState() {
    super.initState();
    _scaffoldKey = widget.scaffoldKey ?? GlobalKey<ScaffoldState>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTopAndRefresh() {
    if (widget.onRefresh == null) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    }
    widget.onRefresh!.call();
  }

  void _showFeedOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SafeArea(
            child: _FeedOptionsSelector(
              platform: widget.platform!,
              optionsGroup: widget.feedOptions!,
              selected: widget.selectedFeedOptions,
              onSelected: (options) {
                widget.onFeedOptionsSelected!(options);
                Navigator.pop(context);
              }
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.useBottomBar,
      builder: (context, useBottomBar, child) {

        final List<Widget> actions = [
          ...widget.iconActions,
          PopupMenuButton(
            onSelected: (callback) => callback(),
            itemBuilder: (context) => [
              ...widget.popupMenuActions.entries.map((entry) {
                return PopupMenuItem<VoidCallback>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }),
              PopupMenuItem<VoidCallback>(
                value: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                child: const Text('Settings'),
              ),
            ]
          ),
        ];

        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null)
              DefaultTextStyle.merge(
                style: const TextStyle(height: 1),
                child: widget.title!
              ),
            if (widget.subtitle != null)
              ValueListenableBuilder(
                valueListenable: Settings.appBarColor,
                builder: (context, appBarColor, child) {
                  return Builder(
                    builder: (context) {
                      final parentAlpha = (DefaultTextStyle.of(context).style.color!.a * 255).toInt();
                      return DefaultTextStyle.merge(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: appBarColor.contrast.withAlpha(min(parentAlpha, Constants.appBarSubtitleAlpha)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: widget.subtitle!
                      );
                    },
                  );
                }
              )
          ],
        );
        final bool extendBody;
        final Drawer? drawer;
        final double drawerEdgeDragWidth;
        final Widget? appBarDrawerIcon;
        final Widget? bottomBar;
        if (useBottomBar) {
          extendBody = true;
          final paddingBottom = MediaQuery.of(context).padding.bottom;
          // paddingBottom = math.max(0.0, paddingBottom * 0.6);
          drawer = null;
          drawerEdgeDragWidth = 20;
          appBarDrawerIcon = null;
          bottomBar = ValueListenableBuilder(
            valueListenable: _isBottomBarVisible,
            builder: (context, isBottomBarVisible, child) {
              return AnimatedSlide(
                offset: isBottomBarVisible ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ValueListenableBuilder(
                    valueListenable: Settings.appBarColor,
                    builder: (context, appBarColor, child) {
                      return Material(
                        color: appBarColor,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: paddingBottom),
                          child: SizedBox(
                            height: kBottomNavigationBarHeight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.sort_rounded),
                                  tooltip: 'Sort',
                                  iconSize: 26,
                                  onPressed: _showFeedOptionsBottomSheet
                                ),
                                IconButton(
                                  icon: const Icon(Icons.groups_rounded),
                                  tooltip: 'Communities',
                                  iconSize: 26,
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        final screenHeight = MediaQuery.of(context).size.height;
                                        final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: viewInsetsBottom),
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => Navigator.of(context).pop(),
                                            child: SizedBox(
                                              height: (screenHeight - viewInsetsBottom) * 0.4,
                                              child: Material(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                                child: _CommunityList(
                                                  activeCommunityPlatform: widget.platform,
                                                  activeCommunityName: widget.activeCommunityName,
                                                  scaffoldKey: _scaffoldKey,
                                                  padding: EdgeInsets.only(
                                                    top: 16,
                                                    bottom: MediaQuery.of(context).padding.bottom
                                                  ),
                                                  onActiveCommunitySelected: _scrollToTopAndRefresh
                                                ),
                                              )
                                            )
                                          ),
                                        );
                                      },
                                    );
                                  }
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded),
                                  tooltip: 'Refresh',
                                  iconSize: 26,
                                  onPressed: _scrollToTopAndRefresh
                                ),
                              ]
                            ),
                          ),
                        )
                      );
                    }
                  ),
                ),
              );
            }
          );
        }
        else {
          final theme = Theme.of(context);
          extendBody = false;
          drawer = Drawer(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light, 
                statusBarBrightness: Brightness.dark,      
              ),
              child: Stack(
                children: [
                  _CommunityList(
                    activeCommunityPlatform: widget.platform,
                    activeCommunityName: widget.activeCommunityName,
                    scaffoldKey: _scaffoldKey,
                    onActiveCommunitySelected: _scrollToTopAndRefresh
                  ),
                  _Scrim(color: (theme.drawerTheme.backgroundColor ?? theme.canvasColor).withAlpha(Constants.scrimAlpha))
                ],
              ),
            )
          );
          drawerEdgeDragWidth = MediaQuery.of(context).size.width / 6;
          appBarDrawerIcon = IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          );
          bottomBar = null;
          if (widget.feedOptions != null) {
            actions.insert(
              0, 
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                onPressed: _showFeedOptionsBottomSheet
              )
            );
          }
        }

        PreferredSizeWidget? appBar;
        Widget body;
        if (widget.useSlivers) {
          body = ValueListenableBuilder(
            valueListenable: Settings.appBarColor,
            builder: (context, appBarColor, child) {
              return Stack(
                children: [
                  NestedScrollView(
                    controller: _scrollController,
                    headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverAppBar(
                          floating: true,
                          snap: true,
                          title: titleWidget,
                          actions: actions,
                          backgroundColor: appBarColor,
                          surfaceTintColor: appBarColor,
                          foregroundColor: appBarColor?.contrast,
                          leading: appBarDrawerIcon
                        ),
                        ...widget.slivers
                      ];
                    },
                    body: widget.body
                  ),
                  _Scrim(color: appBarColor!.withAlpha(Constants.scrimAlpha))
                ],
              );
            }
          );
        }
        else {
          appBar = ThemedAppBar(
            title: titleWidget,
            actions: actions,
            leading: appBarDrawerIcon,
          );
          body = widget.body;
        }

        if (useBottomBar) {
          body = NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              final ScrollDirection direction = notification.direction;
              if (direction == ScrollDirection.reverse && _isBottomBarVisible.value) {
                _isBottomBarVisible.value = false;
              }
              else if (direction == ScrollDirection.forward && !_isBottomBarVisible.value) {
                _isBottomBarVisible.value = true;
              }
              return true;
            },
            child: body
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          extendBody: extendBody,
          drawer: drawer,
          drawerEdgeDragWidth: drawerEdgeDragWidth,
          bottomNavigationBar: bottomBar,
          appBar: appBar,
          body: body
        );
      }
    );
  }

}

class _Scrim extends StatelessWidget {

  final Color color;

  const _Scrim({
    super.key,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top,
      child: ColoredBox(color: color),
    );
  }

}

class _CommunityList extends StatefulWidget {

  final Platform? activeCommunityPlatform;
  final String? activeCommunityName;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onActiveCommunitySelected;

  const _CommunityList({
    super.key,
    required this.activeCommunityPlatform,
    required this.activeCommunityName,
    required this.scaffoldKey,
    this.padding,
    required this.onActiveCommunitySelected
  });

  @override
  State<_CommunityList> createState() => _CommunityListState();

}

class _CommunityListState extends State<_CommunityList> {

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchBarFocusNode = FocusNode();
  late Platform _searchPlatform;
  String _searchQuery = '';
  bool _showSearchBarPlatformPrefix = false;

  @override
  void initState() {
    super.initState();
    _searchPlatform = widget.activeCommunityPlatform ?? F.appFlavor.platforms.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchBarFocusNode.dispose();
    super.dispose();
  }

  void _navigateToCommunity(Community community) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => PostsScreen(community: community)),
      (route) => route.isFirst
    );
  }

  void _onCommunityTap(Community community) {
    if (community.platform == widget.activeCommunityPlatform && community.name == (widget.activeCommunityName ?? widget.activeCommunityPlatform?.communityHome)) {
      Navigator.pop(context);
      widget.onActiveCommunitySelected?.call();
      return;
    }
    if ((widget.scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      Navigator.pop(context);
    }
    _navigateToCommunity(community);
  }

  void _sort() {
    Settings.communities.sort((c1, c2) {
      if (c1.isFavorite != c2.isFavorite) return c1.isFavorite ? -1 : 1;
      return (c1.name ?? '').toLowerCase().compareTo((c2.name ?? '').toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSearchQuery = _searchQuery.isNotEmpty;
    return ValueListenableBuilder(
      valueListenable: Settings.communities,
      builder: (context, communities, child) {
        final visibleItems = hasSearchQuery ? communities.where((community) => community.name?.toLowerCase().contains(_searchQuery) ?? false).toList() : communities;
        return ListView.builder(
          padding: widget.padding,
          itemCount: 1 + visibleItems.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              final bool isCombinedFlavor = F.appFlavor == Flavor.combined;
              final double width;
              final double rightCornerRadius;
              final Alignment? alignment;
              final Widget child;
              if (_showSearchBarPlatformPrefix) {
                width = 48;
                rightCornerRadius = 6;
                alignment = Alignment.centerRight;
                child = Transform.translate(
                  offset: const Offset(0, 0.5), // Can't get text aligned without this
                  child: Text(
                    _searchPlatform.communityPrefix,
                    style: TextStyle(
                      fontSize: Theme.of(context).searchBarTheme.textStyle?.resolve({})?.fontSize ?? 16,
                      // color: Colors.white.withAlpha(Constants.communityPrefixAlpha)
                      // fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              else {
                width = 40;
                rightCornerRadius = 20;
                alignment = null;
                child = const Icon(Icons.search_rounded, color: Colors.white);
              }
              final searchIcon = AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: width,
                height: 40,
                alignment: alignment,
                decoration: BoxDecoration(
                  color: _searchPlatform.color,
                  // color: _searchPlatform.color.withAlpha(Constants.platformColorBackgroundAlpha),
                  borderRadius: BorderRadius.horizontal(
                    left: const Radius.circular(20),
                    right: Radius.circular(rightCornerRadius),
                  ),
                ),
                child: child
              );
              final searchBar = SearchBar(
                controller: _searchController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(right: 16)),
                hintText: !_showSearchBarPlatformPrefix ? 'Search ${_searchPlatform.communityLabel}' : null,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_/]'))],
                backgroundColor: WidgetStateProperty.all(Constants.lighterBackgroundColor),
                leading: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.only(left: 8),
                  child: isCombinedFlavor
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _searchPlatform = Platform.values[(Platform.values.indexOf(_searchPlatform) + 1) % Platform.values.length];
                        }),
                        child: searchIcon
                      )
                    : searchIcon
                ),
                onChanged: (value) {
                  String cleanValue;
                  if (value.isEmpty) {
                    _showSearchBarPlatformPrefix = false;
                    cleanValue = '';
                  }
                  else {
                    cleanValue = value.toLowerCase();

                    bool removedPlatformPrefix = false;
                    for (Platform platform in Platform.values) {
                      if (cleanValue.startsWith(platform.communityPrefix)) {
                        cleanValue = cleanValue.substring(platform.communityPrefix.length);
                        _searchPlatform = platform;
                        _showSearchBarPlatformPrefix = true;
                        removedPlatformPrefix = true;
                        break;
                      }
                    }

                    cleanValue = cleanValue.replaceAll('/', '');

                    if (!removedPlatformPrefix) {
                      _showSearchBarPlatformPrefix = cleanValue.isNotEmpty;
                    }

                    if (cleanValue != value) {
                      _searchController.text = cleanValue;
                      _searchController.selection = TextSelection.fromPosition(TextPosition(offset: cleanValue.length));
                    }

                  }
              
                  setState(() {
                    _searchQuery = cleanValue;
                  });

                },
                onSubmitted: (value) async {
                  String? name = value.trim();
                  if (name.isEmpty) {
                    if (_searchPlatform.communityHome != null) {
                      return;
                    }
                    name = null;
                  }
                  final community = Community(
                    platform: _searchPlatform,
                    name: name
                  );
                  Navigator.pop(context);
                  _navigateToCommunity(community);
                  Settings.communities.add(community);
                  _sort();
                },
              );

              return ListTile(
                minVerticalPadding: 0,
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: F.appFlavor == Flavor.combined
                  ? KeyboardListener(
                      focusNode: _searchBarFocusNode,
                      onKeyEvent: (KeyEvent event) {
                        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _searchController.text.isEmpty) {
                          setState(() {
                            if (_showSearchBarPlatformPrefix) {
                              _showSearchBarPlatformPrefix = false;
                            }
                            else {
                              _searchPlatform = Platform.values[(Platform.values.indexOf(_searchPlatform) - 1) % Platform.values.length];
                            }
                          });
                        }
                      },
                      child: searchBar,
                    )
                  : searchBar
                ),
              );
            }
        
            final community = visibleItems[index - 1];

            return Stack(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  horizontalTitleGap: 8,
                  title: F.appFlavor == Flavor.combined || community.platform.communityHome == null ? CommunityName(community: community) : Text(community.name!),
                  leading: IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: Settings.showMorePlatformColorAccents,
                      builder: (context, showMorePlatformColorAccents, child) {
                        final IconData icon;
                        final Color? color;
                        if (community.isFavorite) {
                          icon = Icons.star_rounded;
                          color = showMorePlatformColorAccents ? Theme.of(context).iconTheme.color : Theme.of(context).colorScheme.primary;
                        }
                        else {
                          icon = Icons.star_border_rounded;
                          color = null;
                        }
                        return Icon(
                          icon,
                          color: color,
                          size: 24
                        );
                      }
                    ),
                    onPressed: () {
                      Settings.communities.update(community.copyWith(isFavorite: !community.isFavorite));
                      _sort();
                    }
                  ),
                  onTap: () => _onCommunityTap(community),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    showSimpleOptionsDialog(
                      context: context,
                      title: community.fullDisplayName,
                      options: {
                        'Remove': () => Settings.communities.remove(community)
                      },
                    );
                  }
                ),
                if (community.platform == widget.activeCommunityPlatform && community.name == (widget.activeCommunityName ?? widget.activeCommunityPlatform?.communityHome))
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: ValueListenableBuilder(
                      valueListenable: Settings.showMorePlatformColorAccents,
                      builder: (context, showMorePlatformColorAccents, child) {
                        return Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: showMorePlatformColorAccents ? community.platform.color : Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                          ),
                        );
                      }
                    ),
                  ),
              ],
            );
          }
        );
      }
    );
  }

}

class _FeedOptionsSelector extends StatefulWidget {

  final Platform platform;
  final FeedOptionsGroup optionsGroup;
  final Map<FeedOptionType, FeedOption>? selected;
  final Function(Map<FeedOptionType, FeedOption>) onSelected;

  const _FeedOptionsSelector({
    super.key,
    required this.platform,
    required this.optionsGroup,
    required this.selected,
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

  void _onOptionSelected(int index, FeedOptionType feedOptionType, FeedOption option) {
    if (_selected.length > index) {
      _selected.removeRange(index, _selected.length);
    }
    _selected.add((feedOptionType, option));
    if (option.subGroup != null) {
      setState(() {});
    }
    else {
      widget.onSelected({for (var item in _selected) item.$1: item.$2});
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(toShow.length, (index) {
          final group = toShow[index];
          return _AnimatedRow(
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, index == 0 ? 0 : 16, 32, 0),
              child: FeedOptionSelector(
                platform: widget.platform,
                header: group.type.label,
                options: group.options,
                selected: _selected.length > index ? _selected[index].$2 : null,
                onSelected: (option) => _onOptionSelected(index, group.type, option),
              ),
            ),
          );
        }),
      ]
    );
  }

}

class _AnimatedRow extends StatefulWidget {

  final Widget child;
  const _AnimatedRow({
    super.key, 
    required this.child
  });

  @override
  State<_AnimatedRow> createState() => _AnimatedRowState();

}

class _AnimatedRowState extends State<_AnimatedRow> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _animation,
        child: widget.child
      ),
    );
  }

}