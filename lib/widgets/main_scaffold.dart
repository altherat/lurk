import 'dart:math';

import 'package:flutter/material.dart' hide SearchBar, RefreshCallback;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lurk/app.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/search.dart';
import 'package:lurk/screens/settings.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_app_bar.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/custom_search_bar.dart';
import 'package:lurk/widgets/list_tile_icon.dart';

class MainScaffold extends StatefulWidget {

  final GlobalKey<CustomRefreshIndicatorState>? refreshIndicatorKey;
  final Platform platform;
  final Community? activeCommunity;
  final ScrollController? customScrollViewController;
  final Widget? title;
  final Widget? subtitle;
  final List<Widget> iconActions;
  final Map<String, VoidCallback>? popupMenuActions;
  final PreferredSizeWidget? sliverAppBarFlexibleBackground;
  final PreferredSizeWidget? sliverAppBarBottom;
  final List<Widget>? slivers;
  final Widget? body;
  final (Listenable, List<Widget> Function(BuildContext context))? iconActionsBuilder;
  final Widget? Function(BuildContext context)? bottomSheetBuilder;
  final RefreshCallback? onPullRefresh;
  final ScrollController? Function()? onOtherRefresh;

  const MainScaffold({
    super.key,
    this.refreshIndicatorKey,
    required this.platform,
    this.activeCommunity,
    this.customScrollViewController,
    required this.title,
    this.subtitle,
    this.iconActions = const [],
    this.popupMenuActions,
    this.sliverAppBarFlexibleBackground,
    this.sliverAppBarBottom,
    this.slivers,
    this.body,
    this.iconActionsBuilder,
    this.bottomSheetBuilder,
    this.onPullRefresh,
    this.onOtherRefresh
  });

  @override
  State<MainScaffold> createState() => MainScaffoldState();

}

class MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _isBottomBarVisible = ValueNotifier<bool>(true);
  late final ScrollController _scrollController;
  ScrollController? _managedScrollController;

  @override
  void initState() {
    super.initState();
    if (widget.customScrollViewController != null) {
      _scrollController = widget.customScrollViewController!;
    }
    else {
      _managedScrollController = ScrollController();
      _scrollController = _managedScrollController!;
    }
  }

  @override
  void dispose() {
    _managedScrollController?.dispose();
    super.dispose();
  }

  void showCommunityList() {
    if (Settings.useBottomBar.value) {
      _showCommunitiesBottomSheet(_scaffoldKey.currentContext!);
    }
    else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void _scrollToTopAndRefresh() {
    final scrollController = widget.onOtherRefresh?.call() ?? _scrollController;
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOutCubicEmphasized
      );
    }
  }

  void _showUsersBottomSheet(BuildContext context) {
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
                onTap: () => _onLoginPressed(context),
              )
            : _UserList(
                loggedInUsers: loggedInUsers,
                activeUser: activeUser!,
                onLoginPressed: () => _onLoginPressed(context),
              )
        );
      }
    );
  }

  void _showCommunitiesBottomSheet(BuildContext context) {
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
                activeCommunity: widget.activeCommunity,
                reverse: Settings.reverseCommunityList.value,
                onActiveCommunitySelected: _scrollToTopAndRefresh
              )
            )
          ),
        );
      },
    );
  }

  Future<void> _getSubscribedCommunityNames() async {
    final subscribedCommunityNames = await widget.platform.api.getSubscribedCommunityNames();
    Settings.communities.addAll(
      subscribedCommunityNames.map((name) {
        return Community(
          platform: Platform.reddit,
          name: name
        );
      })
    );
  }

  Future<void> _onLoginPressed(BuildContext context) async {
    context.pop();
    final username = await widget.platform.api.login();
    if (username != null) {
      _getSubscribedCommunityNames();
      if (context.mounted) {
        context.showSnackBarMessage('Logged in to ${widget.platform.name.toTitleCase()} as "$username"');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorAccents,
      builder: (context, showPlatformColorAccents, child) {
        final theme = Theme.of(context);
        return Theme(
          data: showPlatformColorAccents
            ? theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: widget.platform.color,
                  onPrimary: Colors.white,
                  secondaryContainer: widget.platform.color,
                  onSecondaryContainer: Colors.white,
                ),
                bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
                  selectedItemColor: widget.platform.color,
                ),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: widget.platform.color.withAlpha(200),
                  selectionColor: widget.platform.color.withAlpha(75),
                  selectionHandleColor: widget.platform.color,
                ),
                snackBarTheme: theme.snackBarTheme.copyWith(
                  actionTextColor: widget.platform.color
                ),
              )
            : theme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return ValueListenableBuilder(
                valueListenable: Settings.useBottomBar,
                builder: (context, useBottomBar, child) {
                  final List<Widget> iconActions = widget.iconActions.toList();
                  final List<PopupMenuItem> popupMenuItems = [];
                  final titleWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        DefaultTextStyle.merge(
                          style: const TextStyle(height: 1.1),
                          child: widget.title!
                        ),
                      if (widget.subtitle != null)
                        ValueListenableBuilder(
                          valueListenable: Settings.appBarColor,
                          builder: (context, appBarColor, child) {
                            return Builder(
                              builder: (context) {
                                return DefaultTextStyle.merge(
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: appBarColor.contrast.withAlpha(min((DefaultTextStyle.of(context).style.color!.a * 255).toInt(), Constants.onSurfaceVariantAlpha)),
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
                  final Widget? drawer;
                  final double drawerEdgeDragWidth;
                  final Widget? appBarDrawerIcon;
                  final Widget? bottomBar;
                  if (useBottomBar) {
                    extendBody = true;
                    final paddingBottom = MediaQuery.of(context).padding.bottom;
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
                          curve: Curves.easeInOutCubicEmphasized,
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
                                      child: ListenableBuilder(
                                        listenable: Listenable.merge([Settings.activeUser, Settings.redditClientId, Settings.redditRedirectUri]),
                                        builder: (context, child) {
                                          final activeUser = Settings.activeUser.value;
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              if (activeUser != null)
                                                  IconButton(
                                                    icon: _UserIcon(user: activeUser),
                                                    tooltip: activeUser.name,
                                                    iconSize: 26,
                                                    onPressed: () => _showUsersBottomSheet(context)
                                                  )
                                              else if (Settings.redditClientId.value != null && Settings.redditRedirectUri.value != null)
                                                IconButton(
                                                  icon: const Icon(Icons.reddit_rounded),
                                                  tooltip: 'Login',
                                                  iconSize: 26,
                                                  color: appBarColor.contrast,
                                                  onPressed: () => _showUsersBottomSheet(context)
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.groups_rounded),
                                                tooltip: 'Communities',
                                                iconSize: 26,
                                                color: appBarColor.contrast,
                                                onPressed: () => _showCommunitiesBottomSheet(context)
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.refresh_rounded),
                                                tooltip: 'Refresh',
                                                iconSize: 26,
                                                color: appBarColor.contrast,
                                                onPressed: _scrollToTopAndRefresh
                                              ),
                                            ]
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
                    final reverse = Settings.reverseCommunityList.value;
                    final divider = const Divider(height: 1, color: Constants.lighterBackgroundColor);
                    final communityList = Expanded(
                      child: _CommunityList(
                        platform: widget.platform,
                        activeCommunity: widget.activeCommunity,
                        reverse: reverse,
                        onActiveCommunitySelected: _scrollToTopAndRefresh
                      )
                    );
                    final userList = ValueListenableBuilder(
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
                                      onTap: () => _onLoginPressed(context),
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
                              loggedInUsers: loggedInUsers,
                              activeUser: activeUser!,
                              addUserTileTrailing: const _SettingsIconButton(),
                              reverse: reverse,
                              onLoginPressed: () => _onLoginPressed(context),
                            );
                          }
                        );
                      }
                    );
                    extendBody = false;
                    drawer = Drawer(
                      child: AnnotatedRegion<SystemUiOverlayStyle>(
                        value: const SystemUiOverlayStyle(
                          statusBarColor: Colors.transparent,
                          statusBarIconBrightness: Brightness.light, 
                          statusBarBrightness: Brightness.dark,      
                        ),
                        child: SafeArea(
                          top: reverse,
                          bottom: !reverse,
                          child: Stack(
                            children: [
                              Column(
                                children: reverse
                                  ? [
                                      userList,
                                      divider,
                                      communityList,
                                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom)
                                    ]
                                  : [
                                      communityList,
                                      divider,
                                      userList
                                    ]
                              ),
                              _Scrim(color: (theme.drawerTheme.backgroundColor ?? theme.canvasColor).withAlpha(Constants.scrimAlpha)),
                            ],
                          ),
                        ),
                      )
                    );
                    drawerEdgeDragWidth = MediaQuery.of(context).size.width / 6;
                    appBarDrawerIcon = IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    );
                    bottomBar = null;
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
                    iconActions.add(
                      PopupMenuButton(
                        onSelected: (callback) => callback(),
                        itemBuilder: (context) => popupMenuItems
                      )
                    );
                  }

                  PreferredSizeWidget? scaffoldAppBar;
                  Widget body;
                  if (widget.slivers != null || widget.sliverAppBarBottom != null || widget.sliverAppBarFlexibleBackground != null) {
                    scaffoldAppBar = null;
                    final paddingTop = MediaQuery.of(context).padding.top;
                    final appBarBottomHeight = widget.sliverAppBarBottom?.preferredSize.height ?? 0;
                    final appBarOffset = paddingTop + kToolbarHeight + appBarBottomHeight;
                    final double? appBarExpandedHeight;
                    final Widget? appBarFlexibleSpaceBar;
                    if (widget.sliverAppBarFlexibleBackground != null) {
                      final flexibleBackgroundWidgetHeight = widget.sliverAppBarFlexibleBackground!.preferredSize.height;
                      appBarExpandedHeight = kToolbarHeight + flexibleBackgroundWidgetHeight + appBarBottomHeight;
                      appBarFlexibleSpaceBar = FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: Container(
                          alignment: Alignment.bottomCenter,
                          padding: EdgeInsets.only(bottom: appBarBottomHeight),
                          child: SizedBox(
                            height: flexibleBackgroundWidgetHeight,
                            child: widget.sliverAppBarFlexibleBackground
                          )
                        ),
                      );
                    }
                    else {
                      appBarExpandedHeight = null;
                      appBarFlexibleSpaceBar = null;
                    }
                    final sliverAppBar = ListenableBuilder(
                      listenable: Listenable.merge([Settings.appBarColor, widget.iconActionsBuilder?.$1]),
                      builder: (context, child) {
                      final appBarColor = Settings.appBarColor.value;
                        return SliverAppBar(
                          pinned: widget.sliverAppBarBottom != null,
                          floating: true,
                          snap: true,
                          title: titleWidget,
                          bottom: widget.sliverAppBarBottom,
                          expandedHeight: appBarExpandedHeight,
                          actions: widget.iconActionsBuilder != null ? [...widget.iconActionsBuilder!.$2(context), ...iconActions] : iconActions,
                          backgroundColor: appBarColor,
                          surfaceTintColor: appBarColor,
                          foregroundColor: appBarColor.contrast,
                          leading: appBarDrawerIcon,
                          flexibleSpace: appBarFlexibleSpaceBar
                        );
                      }
                    );

                    if (widget.body != null) {
                      body = NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                          return [
                            SliverOverlapAbsorber(
                              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                              sliver: sliverAppBar,
                            ),
                            ...?widget.slivers
                          ];
                        },
                        body: widget.body!
                      );
                    }
                    else {
                      body = CustomRefreshIndicator(
                        key: widget.refreshIndicatorKey,
                        edgeOffset: appBarOffset,
                        onRefresh: () async {
                          await widget.onPullRefresh?.call();
                        },
                        child: RawScrollbar(
                      // body = RawScrollbar(
                          controller: _scrollController,
                          interactive: false,
                          radius: const Radius.circular(8),
                          padding: EdgeInsets.only(top: appBarOffset),
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              sliverAppBar,
                              // if (widget.onPullRefresh != null)
                              //   MaterialSliverRefreshControl(
                              //     platform: widget.platform,
                              //     onRefresh: widget.onPullRefresh!,
                              //   ),
                              ...widget.slivers!,
                            ]
                          ),
                        )
                      );
                    }
                    body = Stack(
                      children: [
                        body,
                        ValueListenableBuilder(
                          valueListenable: Settings.appBarColor,
                          builder: (context, appBarColor, child) {
                            return _Scrim(color: appBarColor.withAlpha(Constants.scrimAlpha));
                          }
                        )
                      ],
                    );
                  }
                  else {
                    scaffoldAppBar = CustomAppBar(
                      title: titleWidget,
                      leading: appBarDrawerIcon,
                      actions: iconActions,
                    );
                    body = widget.body!;
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
                    appBar: scaffoldAppBar,
                    body: body,
                    bottomSheet: widget.bottomSheetBuilder?.call(context)
                  );
                }
              );
            },
          )
        );
      },
    );
  }

}

// class StiffBouncingScrollPhysics extends BouncingScrollPhysics {

//   const StiffBouncingScrollPhysics({super.parent});

//   @override
//   StiffBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
//     return StiffBouncingScrollPhysics(parent: buildParent(ancestor));
//   }

//   @override
//   double frictionFactor(double overscrollFraction) {
//     return super.frictionFactor(overscrollFraction) * 0.25;
//   }

// }

class _Scrim extends StatelessWidget {

  final Color color;

  const _Scrim({
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

  final List<LoggedInUser> loggedInUsers;
  final LoggedInUser activeUser;
  final bool reverse;
  final Widget? addUserTileTrailing;
  final VoidCallback onLoginPressed;

  const _UserList({
    required this.loggedInUsers,
    required this.activeUser,
    this.reverse = false,
    this.addUserTileTrailing,
    required this.onLoginPressed,
  });

  @override
  State<_UserList> createState() => _UserListState();

}

class _UserListState extends State<_UserList> {

  bool _isExpanded = false;

  void _onTileLongPress(LoggedInUser user, bool isActiveUser) {
    showSimpleOptionsDialog(
      context: context,
      title: user.platform.getPrefixedUsername(user.name),
      options: {
        'View profile': (){
          context.pop();
          context.push(() {
            return UserDetailsScreen(
              platform: user.platform,
              username: user.name
            );
          });
        },
        'Logout': () async {
          Settings.loggedInUsers.remove(user);
          if (isActiveUser) {
            Settings.activeUser.value = Settings.loggedInUsers.value.firstOrNull;
          }
         await user.platform.api.logout(user.id);
         if (mounted) {
          context.showSnackBarMessage('Logged out of ${user.name}');
         }
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final inactiveUsers = widget.loggedInUsers.where((user) => user != widget.activeUser);
    final children = [
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
              platform: user.platform,
              user: user,
              onTap: () async {
                Settings.activeUser.value = user;
                await Future.delayed(const Duration(milliseconds: 300));
                setState(() => _isExpanded = false);
              },
              onLongPress: () => _onTileLongPress(user, false)
            ))
          ],
        ),
        crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 500),
        sizeCurve: Curves.easeInOutCubicEmphasized, 
      ),
      _UserListTile(
        platform: widget.activeUser.platform,
        user: widget.activeUser,
        trailing: IconButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: (_isExpanded ^ widget.reverse) ? pi : 0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutCubicEmphasized,
            builder: (context, rotation, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateX(rotation),
                  // ..rotateY(rotation),
                child: const Icon(Icons.expand_less_rounded),
              );
            },
          ),
        ),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        onLongPress: () => _onTileLongPress(widget.activeUser, true)
      )
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.reverse ? children.reversed.toList() : children
    );
  }

}

class _SettingsIconButton extends StatelessWidget {

  const _SettingsIconButton();

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
  final Community? activeCommunity;
  final bool reverse;
  final VoidCallback? onActiveCommunitySelected;

  const _CommunityList({
    required this.platform,
    required this.activeCommunity,
    required this.reverse,
    required this.onActiveCommunitySelected
  });

  @override
  State<_CommunityList> createState() => _CommunityListState();

}

class _CommunityListState extends State<_CommunityList> {

  static final RegExp _searchNameAllowedRegex = RegExp(
    '[a-zA-Z0-9${
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
    final savedSearchType = Settings.searchType.value;
    _searchType = savedSearchType == null || (savedSearchType == SearchType.withinCommunity && (widget.activeCommunity == null || !_searchPlatform.canSearchWithinCommunities || _searchPlatform.aggregateCommunityNames.contains(widget.activeCommunity))) ? SearchType.community : savedSearchType;
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
      if (_searchType == SearchType.community || _searchType == SearchType.user) {
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchBarHint.toLowerCase() : _searchBarHint.toTitleCase();
      }
    });
  }

  void _navigateToCommunity(Community community) {
    context.pop();
    if (community == widget.activeCommunity) {
      widget.onActiveCommunitySelected?.call();
      return;
    }
    if (community.platform == Settings.homeCommunityPlatform.value && community.name == Settings.homeCommunityName.value) {
      routeObserver.staleRoutes.add(routeObserver.routes.first);
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    final routeName = '${community.platform.name}/community/${community.name}';
    final existingRoute = routeObserver.routes.where((route) => route.settings.name == routeName).firstOrNull;
    if (existingRoute != null) {
      routeObserver.staleRoutes.add(existingRoute);
      Navigator.of(context).popUntil((route) => route.settings.name == routeName);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: routeName, arguments: <String, dynamic>{}),
        builder: (context) => CommunityScreen(community: community)
      ),
      (route) => route.isFirst
    );
  }

  // void _navigateToCommunity(Community community) {
  //   context.pop();
  //   if (community.platform == Settings.homeCommunityPlatform.value && community.name == Settings.homeCommunityName.value) {
  //     Navigator.popUntil(context, (route) => route.isFirst);
  //     return;
  //   }
  //   if (community == widget.activeCommunity) {
  //     widget.onActiveCommunitySelected?.call();
  //     return;
  //   }
  //   Navigator.pushAndRemoveUntil(
  //     context,
  //     MaterialPageRoute(builder: (context) => CommunityScreen(community: community)),
  //     (route) => route.isFirst
  //   );
  // }

  void _cyclePlatform() {
    setState(() {
      _searchPlatform = Platform.values[(Platform.values.indexOf(_searchPlatform) + 1) % Platform.values.length];
      if (_searchType == SearchType.withinCommunity && !_searchPlatform.canSearchWithinCommunities) {
        _updateSearchType(SearchType.all);
      }
      _updateSearchBarTexts();
      _updateIsSearchValid();
    });
  }

  void _cycleSearchType() {
    setState(() {
      final searchTypes = widget.activeCommunity == null || !_searchPlatform.canSearchWithinCommunities || _searchPlatform.aggregateCommunityNames.contains(widget.activeCommunity) ? SearchType.values.where((type) => type != SearchType.withinCommunity).toList() : SearchType.values;
      _updateSearchType(searchTypes[(searchTypes.indexOf(_searchType) + 1) % searchTypes.length]);
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
        _searchController.text = _cleanName(_searchController.text, _searchPlatform.communityNameAllowedChars);
        _searchBarPrefixText = _searchPlatform.communityPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchPlatform.communityLabel : _searchPlatform.communityLabel.toTitleCase();
      case SearchType.user:
        _searchController.text = _cleanName(_searchController.text, _searchPlatform.userNameAllowedChars);
        _searchBarPrefixText = _searchPlatform.userPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? 'username' : 'Username';
      case SearchType.withinCommunity:
        _searchBarPrefixText = null;
        _searchBarHint = 'Search ${widget.activeCommunity!.prefixedName}';
      case SearchType.all:
        _searchBarPrefixText = null;
        _searchBarHint = 'Search ${_searchPlatform.name.toTitleCase()}';
    }
  }

  String _cleanName(String value, String allowedChars) {
    final escaped = hexEscape(allowedChars).join();
    return value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9$escaped]'), '')
      .replaceAllMapped(RegExp('[$escaped]{2,}'), (m) => m.group(0)![0])
      .replaceFirst(RegExp('^[$escaped]'), '');
  }

  void _updateIsSearchValid() {
    _isSearchValid = switch (_searchType) {
      SearchType.community => RegExp(_searchPlatform.communityNameValidation).hasMatch(_searchQuery),
      SearchType.user => RegExp(_searchPlatform.userNameValidation).hasMatch(_searchQuery),
      SearchType.withinCommunity => _searchQuery.isNotEmpty,
      SearchType.all => _searchQuery.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final leadingForegroundColor = ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark ? Colors.white : Colors.black;
    return ValueListenableBuilder(
      valueListenable: Settings.activeUser,
      builder: (context, activeUser, child) {
        final showRootPage = _searchQuery.isEmpty && activeUser?.platform.api.hasLogin == true;
        final headerCount = showRootPage ? 2 : 1;
        return ValueListenableBuilder(
          valueListenable: Settings.showPlatformColorAccents,
          builder: (context, showPlatformColorAccents, child) {
            final listView = ListView.builder(
              reverse: widget.reverse,
              itemCount: headerCount + _visibleCommunities.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isCombinedFlavor = F.appFlavor == Flavor.combined;
                  final double leadingWidth;
                  final double leadingRightCornerRadius;
                  final Alignment? leadingAlignment;
                  final Widget leadingChild;
                  if (_searchBarPrefixText != null && _isSearchBarFocused) {
                    leadingWidth = 52;
                    leadingRightCornerRadius = 6;
                    leadingAlignment = Alignment.centerRight;
                    leadingChild = Transform.translate(
                      offset: const Offset(0, 0.5), // Can't get text aligned without this
                      child: Text(
                        _searchBarPrefixText!,
                        style: TextStyle(
                          fontSize: Theme.of(context).searchBarTheme.textStyle?.resolve({})?.fontSize ?? 16,
                          color: leadingForegroundColor.withAlpha(200),
                        ),
                      ),
                    );
                  }
                  else {
                    leadingWidth = 40;
                    leadingRightCornerRadius = 20;
                    leadingAlignment = null;
                    leadingChild = Icon(
                      Icons.search_rounded,
                      color: leadingForegroundColor
                    );
                  }
                  final leadingIcon = AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: leadingWidth,
                    height: 40,
                    alignment: leadingAlignment,
                    decoration: BoxDecoration(
                      color: _searchPlatform.color,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(20),
                        right: Radius.circular(leadingRightCornerRadius),
                      ),
                    ),
                    child: leadingChild
                  );
                  final searchBar = Theme(
                    data: theme.copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: _searchPlatform.color.withAlpha(200),
                        selectionColor: _searchPlatform.color.withAlpha(75),
                        selectionHandleColor: _searchPlatform.color,
                      )
                    ),
                    child: SearchBar(
                      controller: _searchController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(right: 8)),
                      hintText: _searchBarHint,
                      hintStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white60)),
                      inputFormatters: _searchType != SearchType.all && _searchType != SearchType.withinCommunity ? [FilteringTextInputFormatter.allow(_searchNameAllowedRegex)] : null,
                      backgroundColor: WidgetStateProperty.all(Constants.lighterBackgroundColor),
                      side: _isSearchValid && _isSearchBarFocused ? WidgetStatePropertyAll(BorderSide(color: _searchPlatform.color),) : null,
                      leading: Container(
                        width: 52,
                        height: 40,
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
                          if (_searchType == SearchType.community) {
                            cleanValue = _cleanName(cleanValue, _searchPlatform.communityNameAllowedChars);
                          }
                          else if (_searchType == SearchType.user) {
                            cleanValue = _cleanName(cleanValue, _searchPlatform.userNameAllowedChars);
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
                            if (cleanValue.isEmpty) {
                              _sortVisibleCommunities();
                            }
                            else {
                              _visibleCommunities.sort((c1, c2) {
                                if (c1.isFavorite != c2.isFavorite) {
                                  return c1.isFavorite ? -1 : 1;
                                }
                                final name1 = (c1.name ?? '').toLowerCase();
                                final name2 = (c2.name ?? '').toLowerCase();
                                final startsWith1 = name1.startsWith(cleanValue);
                                final startsWith2 = name2.startsWith(cleanValue);
                                if (startsWith1 != startsWith2) {
                                  return startsWith1 ? -1 : 1;
                                }
                                return (c1.name ?? '').compareTo((c2.name ?? ''));
                              });
                            }
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
                              if (_searchPlatform.homeCommunityName != null) {
                                return;
                              }
                              query = null;
                            }
                            final community = Community(
                              platform: _searchPlatform,
                              name: query
                            );
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
                          case SearchType.withinCommunity:
                            final query = value.trim();
                            if (query.isEmpty) return;
                            context.pop();
                            context.push(() {
                              return SearchScreen(
                                platform: _searchPlatform,
                                query: query,
                                communityName: widget.activeCommunity?.name,
                              );
                            });
                            return;
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
                    ),
                  );
            
                  return ListTile(
                    minVerticalPadding: 0,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                
                if (index == 1 && showRootPage) {
                  return _CommunityNameListTile(
                    platform: widget.platform,
                    community: Community(platform: activeUser!.platform),
                    activeCommunity: widget.activeCommunity,
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
                            Icons.reddit_rounded, //TODO?
                            size: 32,
                            color: activeUser.platform.color
                          ),
                        ],
                      )
                    ),
                    title: Text(activeUser.platform.rootCommunityName),
                    onTap: _navigateToCommunity
                  );
                }
            
                final community = _visibleCommunities[index - headerCount];
                final IconData icon;
                final Color? color;
                final Color communityPrefixColor;
                final Color communityNameColor;
                if (community.isFavorite) {
                  icon = Icons.star_rounded;
                  color = theme.colorScheme.onSurface;
                  communityPrefixColor  = theme.colorScheme.onSurfaceVariant;
                  communityNameColor = theme.colorScheme.onSurface;
                }
                else {
                  icon = Icons.star_border_rounded;
                  color = theme.colorScheme.onSurfaceVariant;
                  communityPrefixColor  = theme.colorScheme.onSurfaceVariant;
                  communityNameColor = theme.colorScheme.onSurfaceVariant;
                }
                return _CommunityNameListTile(
                  platform: widget.platform,
                  community: community,
                  activeCommunity: widget.activeCommunity,
                  leading: IconButton(
                    icon: Icon(
                      icon,
                      color: color,
                      size: 24
                    ),
                    onPressed: () {
                      Settings.communities.update(community.copyWith(isFavorite: !community.isFavorite));
                    }
                  ),
                  title: ValueListenableBuilder(
                    valueListenable: Settings.showPlatformColorTextAccents,
                    builder: (context, showPlatformColorTextAccents, child) {
                      return Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: community.platform.communityPrefix,
                              style: TextStyle(color: showPlatformColorTextAccents ? community.platform.color : communityPrefixColor),
                            ),
                            TextSpan(
                              text: community.name,
                              style: TextStyle(color: communityNameColor),
                            ),
                          ],
                        )
                      );
                    }
                  ),
                  onTap: _navigateToCommunity
                );
              }
            );
            if (activeUser == null) {
              return listView;
            }
            return CustomRefreshIndicator(
              edgeOffset: MediaQuery.of(context).padding.top + 56,
              onRefresh: () async {
                final List<Community> subcscribedCommunities = [];
                for (final platform in F.appFlavor.platforms) {
                  if (platform.api.hasLogin) {
                    for (final communityName in (await widget.platform.api.getSubscribedCommunityNames())) {
                      subcscribedCommunities.add(
                        Community(
                          platform: platform,
                          name: communityName
                        )
                      );
                    }
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

class _CommunityNameListTile extends StatelessWidget {
  
  final Platform platform;
  final Community community;
  final Community? activeCommunity;
  final Widget? leading;
  final Widget title;
  final void Function(Community community) onTap;

  const _CommunityNameListTile({
    required this.platform,
    required this.community,
    required this.activeCommunity,
    required this.leading,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListTile(
          horizontalTitleGap: 8,
          leading: leading,
          title: title,
          onTap: () => onTap(community),
          onLongPress: community.name != null
            ? () {
                // final activeUser = Settings.activeUser.value;
                showSimpleOptionsDialog(
                  context: context,
                  title: community.prefixedName,
                  options: {
                    // if (community.name != null && activeUser != null)
                    //   'Unsubscribe': () => activeUser.platform.api.unsubscribe(community.name!),
                    'Remove': () => Settings.communities.remove(community)
                  },
                );
              }
            : null
        ),
        if (community == activeCommunity)
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            )
          )
      ]
    );
  }
}