import 'dart:math';

import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/search.dart';
import 'package:lurk/screens/settings.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/prefixed_community_name.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/feed_option_selector.dart';
import 'package:lurk/widgets/custom_search_bar.dart';
import 'package:lurk/widgets/list_tile_icon.dart';

class MainScaffold extends StatefulWidget {

  final Platform platform;
  final String? activeCommunityName;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? title;
  final Widget? subtitle;
  final List<Widget> iconActions;
  final Map<String, VoidCallback>? popupMenuActions;
  final FeedOptionsGroup? feedOptions;
  final Map<FeedOptionType, FeedOption>? selectedFeedOptions;
  final Widget body;
  final VoidCallback? onRefresh;
  final Function(Map<FeedOptionType, FeedOption>)? onFeedOptionsSelected;

  const MainScaffold({
    super.key,
    required this.platform,
    this.activeCommunityName,
    this.scaffoldKey,
    required this.title,
    this.subtitle,
    this.iconActions = const [],
    this.popupMenuActions,
    this.feedOptions,
    this.selectedFeedOptions,
    required this.body,
    this.onRefresh,
    this.onFeedOptionsSelected
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();

}

class _MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {

  final ValueNotifier<bool> _isBottomBarVisible = ValueNotifier<bool>(true);
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;
  late GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void initState() {
    super.initState();
    _scaffoldKey = widget.scaffoldKey ?? GlobalKey<ScaffoldState>();
    if (widget.feedOptions != null && widget.feedOptions!.type.label == null) {
      _tabController = TabController(length: widget.feedOptions!.options.length, vsync: this);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController?.dispose();
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

  void _showUsersBottomSheet() {
    final loggedInUsers = Settings.loggedInUsers.value;
    final activeUser = Settings.activeUser.value;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: loggedInUsers.isEmpty
            ? ListTile(
                title: Text('Login to Reddit'),
                onTap: _onLoginPressed
              )
            : _UserList(
                platform: widget.platform,
                loggedInUsers: loggedInUsers,
                activeUser: activeUser!,
                onLoginPressed: _onLoginPressed,
              )
        );
      }
    );
  }

  void _showFeedOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _FeedOptionsSelector(
              platform: widget.platform,
              optionsGroup: widget.feedOptions!,
              selected: widget.selectedFeedOptions,
              onSelected: (options) {
                widget.onFeedOptionsSelected!(options);
                context.pop();
              }
            ),
          ),
        );
      }
    );
  }

  Future<void> _onLoginPressed() async {
    context.pop();
    final username = await widget.platform.api.login();
    if (mounted && username != null) {
      context.showSnackBar(
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Logged in to ${widget.platform.name.toTitleCase()} as '
              ),
              TextSpan(
                text: username,
                style: TextStyle(
                  color: widget.platform.color,
                  fontWeight: FontWeight.bold
                )
              )
            ]
          )
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.useBottomBar,
      builder: (context, useBottomBar, child) {
        final List<Widget> actions = widget.iconActions.toList();
        final List<PopupMenuItem> popupMenuItems = [];
        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(height: 1),
                  child: widget.title!
                ),
              ),
            if (widget.subtitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ValueListenableBuilder(
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
                ),
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
          popupMenuItems.add(
            PopupMenuItem<VoidCallback>(
              value: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
              child: const Text('Settings'),
            )
          );
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
                            child: ValueListenableBuilder(
                              valueListenable: Settings.activeUser,
                              builder: (context, activeUser, child) {
                                return ValueListenableBuilder(
                                  valueListenable: Settings.redditClientId,
                                  builder: (context, redditClientId, child) {
                                    return ValueListenableBuilder(
                                      valueListenable: Settings.redditRedirectUri,
                                      builder: (context, redditRedirectUri, child) {
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            if (activeUser != null)
                                                IconButton(
                                                  icon: _UserIcon(user: activeUser),
                                                  tooltip: activeUser.name,
                                                  iconSize: 26,
                                                  onPressed: _showUsersBottomSheet
                                                )
                                            else if (redditClientId != null && redditRedirectUri != null)
                                              IconButton(
                                                icon: const Icon(Icons.reddit_rounded),
                                                tooltip: 'Login',
                                                iconSize: 26,
                                                onPressed: _showUsersBottomSheet
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.sort_rounded),
                                              tooltip: 'Filter',
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
                                                  showDragHandle: true,
                                                  isScrollControlled: true,
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
                                                          child: _CommunityList(
                                                            platform: widget.platform,
                                                            activeCommunityName: widget.activeCommunityName,
                                                            scaffoldKey: _scaffoldKey,
                                                            onActiveCommunitySelected: _scrollToTopAndRefresh
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
                                        );
                                      }
                                    );
                                  }
                                );
                              }
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
                  Column(children: [
                    Expanded(
                      child: _CommunityList(
                        platform: widget.platform,
                        activeCommunityName: widget.activeCommunityName,
                        scaffoldKey: _scaffoldKey,
                        onActiveCommunitySelected: _scrollToTopAndRefresh
                      )
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Constants.lighterBackgroundColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: ValueListenableBuilder(
                          valueListenable: Settings.loggedInUsers,
                          builder: (context, loggedInUsers, child) {
                            if (loggedInUsers.isEmpty) {
                              if (widget.platform.api.hasLogin) {
                                return ValueListenableBuilder(
                                  valueListenable: Settings.redditClientId,
                                  builder: (context, redditClientId, child) {
                                    return ValueListenableBuilder(
                                      valueListenable: Settings.redditRedirectUri,
                                      builder: (context, redditRedirectUri, child) {
                                        if (redditClientId == null || redditRedirectUri == null) {
                                          return const ListTile(leading: _SettingsIconButton());
                                        }
                                        return ListTile(
                                          title: Text('Login to Reddit'),
                                          onTap: _onLoginPressed,
                                          trailing: const _SettingsIconButton(),
                                        );
                                      }
                                    );
                                  }
                                );
                              }
                              return const ListTile(leading: _SettingsIconButton());
                            }
                            return ValueListenableBuilder(
                              valueListenable: Settings.activeUser,
                              builder: (context, activeUser, child) {
                                return _UserList(
                                  platform: widget.platform,
                                  loggedInUsers: loggedInUsers,
                                  activeUser: activeUser!,
                                  addUserTileTrailing: const _SettingsIconButton(),
                                  onLoginPressed: _onLoginPressed,
                                );
                              }
                            );
                          }
                        ),
                      ),
                    )
                  ]),
                  _Scrim(color: (theme.drawerTheme.backgroundColor ?? theme.canvasColor).withAlpha(Constants.scrimAlpha)),
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
            actions.add(
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Filter',
                onPressed: _showFeedOptionsBottomSheet
              )
            );
          }
        }
        if (widget.popupMenuActions != null) {
          popupMenuItems.insertAll(
            0,
            widget.popupMenuActions!.entries.map((entry) {
              return PopupMenuItem<VoidCallback>(
                value: entry.value,
                child: Text(entry.key),
              );
            })
          );
        }
        if (popupMenuItems.isNotEmpty) {
          actions.add(
            PopupMenuButton(
              onSelected: (callback) => callback(),
              itemBuilder: (context) => popupMenuItems
            )
          );
        }

        Widget body = ValueListenableBuilder(
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
                        foregroundColor: appBarColor.contrast,
                        leading: appBarDrawerIcon,
                      ),
                    ];
                  },
                  body: widget.body
                ),
                _Scrim(color: appBarColor!.withAlpha(Constants.scrimAlpha))
              ],
            );
          }
        );

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

class _UserList extends StatefulWidget {

  final Platform platform;
  final List<LoggedInUser> loggedInUsers;
  final LoggedInUser activeUser;
  final Widget? addUserTileTrailing;
  final VoidCallback onLoginPressed;

  const _UserList({
    super.key,
    required this.platform,
    required this.loggedInUsers,
    required this.activeUser,
    this.addUserTileTrailing,
    required this.onLoginPressed,
  });

  @override
  State<_UserList> createState() => _UserListState();

}

class _UserListState extends State<_UserList> {

  bool _isExpanded = false;

  void _onTileLongPress(String userName) {
    showSimpleOptionsDialog(
      context: context,
      title: widget.platform.getPrefixedUsername(userName),
      options: {
        'View profile': (){
          context.pop();
          context.push(() {
            return UserDetailsScreen(
              platform: widget.platform,
              username: userName
            );
          });
        },
        'Logout': widget.platform.api.logout
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final inactiveUsers = widget.loggedInUsers.where((user) => user != widget.activeUser);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                horizontalTitleGap: 8,
                leading: IconButton(
                  icon: Icon(Icons.add_rounded),
                  onPressed: widget.onLoginPressed
                ),
                title: Text('Add user'),
                trailing: widget.addUserTileTrailing,
                onTap: widget.onLoginPressed,
              ),
              ...inactiveUsers.map((user) => _UserListTile(
                platform: widget.platform,
                user: user,
                onTap: () async {
                  Settings.activeUser.value = user;
                  await Future.delayed(const Duration(milliseconds: 300));
                  setState(() => _isExpanded = false);
                },
                onLongPress: () => _onTileLongPress(user.name)
              ))
            ],
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 500),
          sizeCurve: Curves.fastOutSlowIn, 
        ),
        _UserListTile(
          platform: widget.platform,
          user: widget.activeUser,
          trailing: IconButton(
            icon: Icon(_isExpanded ? Icons.expand_more_rounded : Icons.expand_less_rounded),
            onPressed: () => setState(() => _isExpanded = !_isExpanded)
          ),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          onLongPress: () => _onTileLongPress(widget.activeUser.name)
        )
      ],
    );
  }

}

class _SettingsIconButton extends StatelessWidget {

  const _SettingsIconButton({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.settings_rounded),
      onPressed: () {
        context.pop();
        context.push(() => const SettingsScreen());
      }
    );
  }
}

class _UserListTile extends StatelessWidget {

  final Platform platform;
  final LoggedInUser user;
  final Widget? trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _UserListTile({
    super.key,
    required this.platform,
    required this.user,
    this.trailing,
    required this.onTap,
    this.onLongPress
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 8,
      leading: _UserIcon(user: user),
      title: Text(user.name),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

}

class _UserIcon extends StatelessWidget {

  final LoggedInUser user;

  const _UserIcon({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6), 
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: user.platform.color, width: 1), 
      ),
      child: ListTileIcon(
        platform: user.platform,
        url: user.iconUrl,
        size: 34,
        placeholderIcon: Icons.no_accounts_rounded,
      ),
    );
  }
}

class _CommunityList extends StatefulWidget {

  final Platform platform;
  final String? activeCommunityName;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onActiveCommunitySelected;

  const _CommunityList({
    super.key,
    required this.platform,
    required this.activeCommunityName,
    required this.scaffoldKey,
    this.padding,
    required this.onActiveCommunitySelected
  });

  @override
  State<_CommunityList> createState() => _CommunityListState();

}

class _CommunityListState extends State<_CommunityList> {

  static final RegExp _searchNameAllowedRegex = RegExp(
    '[a-z0-9${
      F.appFlavor.platforms
      .expand((platform) => hexEscape('${platform.communityPrefix}${platform.userPrefix}${platform.communityNameAllowedChars}${platform.userNameAllowedChars}'))
      .toSet()
      .join()
    }]'
  );

  final TextEditingController _searchController = TextEditingController();
  late List<Community> _visibleCommunities;
  final FocusNode _searchBarFocusNode = FocusNode();
  late Platform _searchPlatform;
  late SearchType _searchType;
  String _searchQuery = '';
  String? _searchBarPrefixText;
  late String _searchBarHint;
  bool _isSearchBarFocused = false;
  bool _isSearchValid = false;

  @override
  void initState() {
    super.initState();
    _visibleCommunities = Settings.communities.value.toList();
    _searchPlatform = widget.platform;
    _searchType = Settings.searchType.value ?? SearchType.community;
    _updateSearchBarTexts();
    _searchBarFocusNode.addListener(_onSearchBarFocusChanged);
    Settings.communities.addListener(_onCommunitiesSettingChanged);
    _sortVisibleCommunities();
  }

  @override
  void dispose() {
    _searchBarFocusNode.removeListener(_onSearchBarFocusChanged);
    _searchController.dispose();
    _searchBarFocusNode.dispose();
    super.dispose();
  }

  void _onCommunitiesSettingChanged() {
    if (!mounted) return;
    setState(() {
      _updateVisibleCommunities();
      _sortVisibleCommunities();
    });
  }

  void _updateVisibleCommunities() {
    _visibleCommunities = (_searchQuery.isEmpty ? Settings.communities.value : Settings.communities.value.where((community) => community.name?.contains(_searchQuery) ?? false)).toList();
  }

  void _sortVisibleCommunities() {
    _visibleCommunities.sort((c1, c2) {
      if (c1.isFavorite != c2.isFavorite) return c1.isFavorite ? -1 : 1;
      return (c1.name ?? '').compareTo((c2.name ?? ''));
    });
  }

  void _onSearchBarFocusChanged() {
    setState(() {
      _isSearchBarFocused = _searchBarFocusNode.hasFocus;
      if (_searchType != SearchType.all) {
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchBarHint.toLowerCase() : _searchBarHint.toTitleCase();
      }
    });
  }

  void _navigateToCommunity(Community community) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => PostsScreen(community: community)),
      (route) => route.isFirst
    );
  }

  void _onCommunityTap(Community community) {
    if (community.platform == widget.platform && community.name == (widget.activeCommunityName ?? widget.platform.homeCommunity)) {
      context.pop();
      widget.onActiveCommunitySelected?.call();
      return;
    }
    if ((widget.scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      context.pop();
    }
    _navigateToCommunity(community);
  }

  void _cyclePlatform() {

    setState(() {
      _searchPlatform = Platform.values[(Platform.values.indexOf(_searchPlatform) + 1) % Platform.values.length];
      _updateSearchBarTexts();
      _updateIsSearchValid();
    });
  }

  void _cycleSearchType() {
    setState(() {
      _updateSearchType(SearchType.values[(SearchType.values.indexOf(_searchType) + 1) % SearchType.values.length]);
      _updateSearchBarTexts();
      _updateIsSearchValid();
    });
  }

  void _updateSearchType(SearchType searchType) {
    _searchType = searchType;
    Settings.searchType.value = searchType;
  }

  void _updateSearchBarTexts() {
    switch (_searchType) {
      case SearchType.community:
        _searchBarPrefixText = _searchPlatform.communityPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchPlatform.communityLabel : _searchPlatform.communityLabel.toTitleCase();
      case SearchType.user:
        _searchBarPrefixText = _searchPlatform.userPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? 'username' : 'Username';
      case SearchType.all:
        _searchBarPrefixText = null;
        _searchBarHint = 'Search ${_searchPlatform.name.toTitleCase()}';
    }
  }

  void _updateIsSearchValid() {
    _isSearchValid = switch (_searchType) {
      SearchType.community => RegExp(_searchPlatform.communityNameValidation).hasMatch(_searchQuery),
      SearchType.user => RegExp(_searchPlatform.userNameValidation).hasMatch(_searchQuery),
      SearchType.all => _searchQuery.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.activeUser,
      builder: (context, activeUser, child) {
        final int headerCount = activeUser == null ? 1 : 2;
        return ValueListenableBuilder(
          valueListenable: Settings.showPlatformColorAccents,
          builder: (context, showPlatformColorAccents, child) {
            final Color accentColor;
            final Color leadingForegroundColor;
            if (showPlatformColorAccents) {
              accentColor = _searchPlatform.color;
              leadingForegroundColor = Colors.white;
            }
            else {
              accentColor = Theme.of(context).colorScheme.primary;
              leadingForegroundColor = Colors.black;
            }
            final listView = ListView.builder(
              padding: widget.padding,
              itemCount: headerCount + _visibleCommunities.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final bool isCombinedFlavor = F.appFlavor == Flavor.combined;
                  final double width;
                  final double rightCornerRadius;
                  final Alignment? alignment;
                  final Widget child;
                  if (_searchBarPrefixText != null && _isSearchBarFocused) {
                    width = 48;
                    rightCornerRadius = 6;
                    alignment = Alignment.centerRight;
                    child = Transform.translate(
                      offset: const Offset(0, 0.5), // Can't get text aligned without this
                      child: Text(
                        _searchBarPrefixText!,
                        style: TextStyle(
                          fontSize: Theme.of(context).searchBarTheme.textStyle?.resolve({})?.fontSize ?? 16,
                          color: leadingForegroundColor.withAlpha(200),
                          // color: Colors.black
                          // fontWeight: FontWeight.bold
                        ),
                      ),
                    );
                  }
                  else {
                    width = 40;
                    rightCornerRadius = 20;
                    alignment = null;
                    child = Icon(
                      Icons.search_rounded,
                      color: leadingForegroundColor
                    );
                  }
                  final leadingIcon = AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: width,
                    height: 40,
                    alignment: alignment,
                    decoration: BoxDecoration(
                      color: accentColor,
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
                    padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(right: 8)),
                    hintText: _searchBarHint,
                    hintStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white60)),
                    inputFormatters: _searchType != SearchType.all ? [FilteringTextInputFormatter.allow(_searchNameAllowedRegex)] : null,
                    backgroundColor: WidgetStateProperty.all(Constants.lighterBackgroundColor),
                    side: _isSearchValid && _isSearchBarFocused ? WidgetStatePropertyAll(BorderSide(color: accentColor),) : null,
                    leading: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.only(left: 8),
                      child: isCombinedFlavor
                        ? GestureDetector(
                            onTap: _cyclePlatform,
                            child: leadingIcon
                          )
                        : leadingIcon
                    ),
                    trailing: _isSearchBarFocused
                      ? [
                          IconButton(
                            icon: Icon(
                              _searchType.icon,
                              color: Colors.white54
                            ),
                            onPressed: _cycleSearchType,
                          )
                        ]
                      : null,
                    onChanged: (value) {
            
                      var cleanValue = value;
                      var lowerCase = value.toLowerCase();
            
                      bool handledPrefix = false;
                      for (Platform platform in F.appFlavor.platforms) {
                        if (lowerCase.startsWith(platform.communityPrefix)) {
                          cleanValue = cleanValue.substring(platform.communityPrefix.length);
                          _updateSearchType(SearchType.community);
                          _searchPlatform = platform;
                          _searchBarPrefixText = platform.communityPrefix;
                          _searchBarHint = platform.communityLabel;
                          handledPrefix = true;
                          break;
                        }
                        else if (lowerCase.startsWith(platform.userPrefix)) {
                          cleanValue = cleanValue.substring(platform.userPrefix.length);
                          _updateSearchType(SearchType.user);
                          _searchPlatform = platform;
                          _searchBarPrefixText = platform.userPrefix;
                          _searchBarHint = 'username';
                          handledPrefix = true;
                          break;
                        }
                      }
            
                      if (cleanValue.isNotEmpty) {
            
                        void clean(String allowedChars) {
                          final escaped = hexEscape(allowedChars).join();
                          cleanValue = cleanValue
                            .replaceAll(RegExp('[^a-zA-Z0-9$escaped]'), '')
                            .replaceAllMapped(RegExp('[$escaped]{2,}'), (m) => m.group(0)![0])
                            .replaceFirst(RegExp('^[$escaped]'), '');
            
                        }
            
                        if (_searchType == SearchType.community) {
                          clean(_searchPlatform.communityNameAllowedChars);
                        }
                        else if (_searchType == SearchType.user) {
                          clean(_searchPlatform.userNameAllowedChars);
                        }
                      }
            
                      if (cleanValue != value) {
                        _searchController.text = cleanValue;
                        _searchController.selection = TextSelection.fromPosition(TextPosition(offset: cleanValue.length));
                      }
                      
                      if (handledPrefix || cleanValue != _searchQuery) {
                        setState(() {
                          _searchQuery = cleanValue;
                          _updateVisibleCommunities();
                          _updateIsSearchValid();
                        });
                      }
                    },
                    onSubmitted: (value) {
                      switch (_searchType) {
                        case SearchType.community:
                          if (!RegExp(_searchPlatform.communityNameValidation).hasMatch(value)) {
                            return;
                          }
                          String? query = value;
                          if (query.isEmpty) {
                            if (_searchPlatform.homeCommunity != null) {
                              return;
                            }
                            query = null;
                          }
                          final community = Community(
                            platform: _searchPlatform,
                            name: query
                          );
                          context.pop();
                          _navigateToCommunity(community);
                          Settings.communities.add(community);
                        case SearchType.user:
                          if (!RegExp(_searchPlatform.userNameValidation).hasMatch(value)) {
                            return;
                          }
                          context.pop();
                          context.push(() {
                            return UserDetailsScreen(
                              platform: _searchPlatform,
                              username: value
                            );
                          });
                        case SearchType.all:
                          final query = value.trim();
                          if (query.isEmpty) return;
                          context.pop();
                          context.push(() {
                            return SearchScreen(
                              platform: _searchPlatform,
                              query: query
                            );
                          });
                      }
                    },
                  );
            
                  return ListTile(
                    minVerticalPadding: 0,
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KeyboardListener(
                        focusNode: _searchBarFocusNode,
                        onKeyEvent: (KeyEvent event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _searchController.text.isEmpty) {
                            if (isCombinedFlavor) {
                              _cyclePlatform();
                            }
                            else {
                              _cycleSearchType();
                            }
                          }
                        },
                        child: searchBar,
                      )
                    ),
                  );
                }
        
                if (index == 1 && activeUser != null) {
                  return ListTile(
                    horizontalTitleGap: 8,
                    leading: IconButton(
                      onPressed: () {},
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            )
                          ),
                          Icon(
                            Icons.reddit_rounded,
                            size: 32,
                            color: Platform.reddit.color,
                          ),
                        ],
                      )
                    ),
                    title: Text(Platform.reddit.rootCommunityName),
                    onTap: () {
                      _navigateToCommunity(
                        Community(
                          platform: widget.platform,
                          name: null
                        )
                      );
                    }
                  );
                }
            
                final community = _visibleCommunities[index - headerCount];
                return Stack(
                  children: [
                    ListTile(
                      horizontalTitleGap: 8,
                      title: F.appFlavor == Flavor.combined || community.platform.homeCommunity == null ? PrefixedCommunityName(community: community) : Text(community.name!),
                      leading: IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: Settings.showPlatformColorAccents,
                          builder: (context, showPlatformColorAccents, child) {
                            final IconData icon;
                            final Color? color;
                            if (community.isFavorite) {
                              icon = Icons.star_rounded;
                              color = showPlatformColorAccents ? null : Theme.of(context).colorScheme.primary;
                              // color = showPlatformColorAccents ? community.platform.color : Theme.of(context).colorScheme.primary;
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
                        }
                      ),
                      onTap: () => _onCommunityTap(community),
                      onLongPress: () {
                        final activeUser = Settings.activeUser.value;
                        showSimpleOptionsDialog(
                          context: context,
                          title: community.prefixedName,
                          options: {
                            if (community.name != null && activeUser != null)
                              'Unsubscribe': () => activeUser.platform.api.unsubscribe(community.name!),
                            'Remove': () => Settings.communities.remove(community)
                          },
                        );
                      }
                    ),
                    if (community.platform == widget.platform && community.name == (widget.activeCommunityName ?? widget.platform.homeCommunity))
                      Positioned(
                        left: 0,
                        top: 8,
                        bottom: 8,
                        child: ValueListenableBuilder(
                          valueListenable: Settings.showPlatformColorAccents,
                          builder: (context, showPlatformColorAccents, child) {
                            return Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: showPlatformColorAccents ? community.platform.color : Theme.of(context).colorScheme.primary,
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
            if (activeUser == null) {
              return listView;
            }
            return CustomRefreshIndicator(
              platform: widget.platform,
              edgeOffset: MediaQuery.of(context).padding.top + 56,
              onRefresh: () async {
                final List<Community> subcscribedCommunities = [];
                for (var platform in F.appFlavor.platforms) {
                  if (platform.api.hasLogin) {
                    final subscribedCommunityNames = await widget.platform.api.getSubscribedCommunityNames();
                    subscribedCommunityNames.map((name) {
                      return Community(
                        platform: Platform.reddit,
                        name: name
                      );
                    });
                  }
                }
                Settings.communities.addAll(subcscribedCommunities);
              },
              child: listView
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