import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart' hide SearchBar, RefreshCallback;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/name_input_formatter.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/login.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/communities.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/search.dart';
import 'package:lurk/screens/settings.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/custom_app_bar.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/custom_search_bar.dart';
import 'package:lurk/widgets/expansion_icon.dart';
import 'package:lurk/widgets/list_tile_icon.dart';
import 'package:lurk/widgets/name_text.dart';

class MainScaffold extends StatefulWidget {

  final GlobalKey<CustomRefreshIndicatorState>? refreshIndicatorKey;
  final PlatformContext platformContext;
  final Community? activeCommunity;
  final ScrollController? customScrollViewController;
  final Widget? title;
  final Widget? subtitle;
  final List<Widget>? iconActions;
  final Map<Widget, Function(BuildContext context)>? popupMenuActions;
  final PreferredSizeWidget? sliverAppBarFlexibleBackground;
  final PreferredSizeWidget? sliverAppBarBottom;
  final List<Widget>? slivers;
  final Widget? body;
  final bool Function(LoggedInUser user)? userFilter;
  final (Listenable, List<Widget> Function(BuildContext context))? iconActionsBuilder;
  final Widget? Function(BuildContext context)? bottomSheetBuilder;
  final RefreshCallback? onPullRefresh;
  final ScrollController? Function()? onOtherRefresh;

  const MainScaffold({
    super.key,
    this.refreshIndicatorKey,
    required this.platformContext,
    this.activeCommunity,
    this.customScrollViewController,
    required this.title,
    this.subtitle,
    this.iconActions,
    this.popupMenuActions,
    this.sliverAppBarFlexibleBackground,
    this.sliverAppBarBottom,
    this.slivers,
    this.body,
    this.userFilter,
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

  bool get isDrawerOpen => _scaffoldKey.currentState?.isDrawerOpen ?? false;
  
  void closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  String? get platformNameOrHost => widget.platformContext.platform.supportsMultipleHosts ? widget.platformContext.host : widget.platformContext.platform.name.toTitleCase();

  List<LoggedInUser> filterLoggedInUsers(List<LoggedInUser> loggedInUsers) => widget.userFilter != null ? loggedInUsers.where(widget.userFilter!).toList() : loggedInUsers;

  void _showUsersBottomSheet(BuildContext context, LoggedInUser? activeUser) {
    final loggedInUsers = filterLoggedInUsers(UserManager.getLoggedInUsersListenable(widget.platformContext.platform).value);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: loggedInUsers.isEmpty
            ? ListTile(
                title: Text('Login to $platformNameOrHost'),
                onTap: () => _onLoginPressed(context),
              )
            : _UserList(
                platformContext: widget.platformContext,
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
                scaffoldKey: _scaffoldKey,
                platformContext: widget.platformContext,
                activeCommunity: widget.activeCommunity,
                reverse: Settings.reverseCommunityList.value,
              )
            )
          ),
        );
      },
    );
  }

  void _showSnackbarMessage(String message) {
    if (context.mounted) {
      context.showSnackBarMessage(message);
    }
  }

  void _onLoginPressed(BuildContext context) async {

    void onUserLoggedIn(LoggedInUser user) {
      if (UserManager.addLoggedInUser(user)) {
        _showSnackbarMessage('Logged in to $platformNameOrHost as ${user.name}');
        getApi(widget.platformContext, user).fetchSubscribedCommunities();
      }
      else {
        _showSnackbarMessage('Already logged in to $platformNameOrHost as ${user.name}');
      }
    }

    _scaffoldKey.currentState?.closeDrawer();
    if (widget.platformContext.platform.loginFields?.isNotEmpty ?? false) {
      final user = await showDialog(
        context: context,
        builder: (context) {
          return _LoginDialog(
            platform: widget.platformContext.platform,
            title: 'Login to $platformNameOrHost',
            loginFields: widget.platformContext.platform.loginFields!,
            performLogin: (credentials) => getApi(widget.platformContext, null).login(credentials),
          );
        }
      );
      if (user != null) {
        onUserLoggedIn(user);
      }
    }
    else {
      final result = await getApi(widget.platformContext, null).login();
      switch (result) {
        case LoginSuccess():
          onUserLoggedIn(result.user);
          break;
        case LoginError(:final message):
          _showSnackbarMessage('Failed to login${message != null ? ': $message' : ''}');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorAccents,
      builder: (context, showPlatformColorAccents, child) {
        return Theme(
          data: showPlatformColorAccents
            ? theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: widget.platformContext.platform.color,
                  onPrimary: Colors.white,
                  secondaryContainer: widget.platformContext.platform.color,
                  onSecondaryContainer: Colors.white,
                ),
                bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
                  selectedItemColor: widget.platformContext.platform.color,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: widget.platformContext.platform.color,
                  ),
                ),
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: widget.platformContext.platform.color.withAlpha(200),
                  selectionColor: widget.platformContext.platform.color.withAlpha(75),
                  selectionHandleColor: widget.platformContext.platform.color,
                ),
                snackBarTheme: theme.snackBarTheme.copyWith(
                  actionTextColor: widget.platformContext.platform.color
                ),
              )
            : theme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return ValueListenableBuilder(
                valueListenable: Settings.useBottomBar,
                builder: (context, useBottomBar, child) {
                  final List<Widget> iconActions = widget.iconActions?.toList() ?? [];
                  final List<PopupMenuItem<void Function(BuildContext context)>> popupMenuItems = [];
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
                                  style: theme.textTheme.bodySmall!.copyWith(
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
                      PopupMenuItem<void Function(BuildContext context)>(
                        value: (context) => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                        child: const Text('Settings'),
                      )
                    );
                    final activeUserListenable = UserManager.getActiveUserListenable(widget.platformContext.platform);
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
                                        listenable: Listenable.merge([activeUserListenable, Settings.redditClientId, Settings.redditRedirectUri]),
                                        builder: (context, child) {
                                          final activeUser = activeUserListenable.value;
                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              if (activeUser != null)
                                                  IconButton(
                                                    icon: _UserIcon(user: activeUser),
                                                    tooltip: activeUser.name,
                                                    iconSize: 26,
                                                    onPressed: () => _showUsersBottomSheet(context, activeUser)
                                                  )
                                              else if (Settings.redditClientId.value != null && Settings.redditRedirectUri.value != null)
                                                IconButton(
                                                  icon: const Icon(Icons.reddit_rounded),
                                                  tooltip: 'Login',
                                                  iconSize: 26,
                                                  color: appBarColor.contrast,
                                                  onPressed: () => _showUsersBottomSheet(context, null)
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
                                                onPressed: () {
                                                  final scrollController = widget.onOtherRefresh?.call() ?? _scrollController;
                                                    if (scrollController.hasClients) {
                                                      scrollController.animateTo(
                                                        0, 
                                                        duration: const Duration(milliseconds: 300), 
                                                        curve: Curves.easeInOutCubicEmphasized
                                                      );
                                                    }
                                                }
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
                        scaffoldKey: _scaffoldKey,
                        platformContext: widget.platformContext,
                        activeCommunity: widget.activeCommunity,
                        reverse: reverse,
                      )
                    );
                    final loggedInUsersListenable = UserManager.getLoggedInUsersListenable(widget.platformContext.platform);
                    final activeUserListenable = UserManager.getActiveUserListenable(widget.platformContext.platform);
                    final footer = Material(
                      child: ListenableBuilder(
                        listenable: Listenable.merge([loggedInUsersListenable, activeUserListenable]),
                        builder: (context, child) {
                          final filteredLoggedInUsers = filterLoggedInUsers(loggedInUsersListenable.value);
                          LoggedInUser? activeUser = activeUserListenable.value;
                          if (activeUser != null && widget.userFilter?.call(activeUser) == false) {
                            activeUser = filteredLoggedInUsers.firstOrNull;
                          }
                          if (activeUser != null) {
                            return _UserList(
                              platformContext: widget.platformContext,
                              loggedInUsers: filteredLoggedInUsers,
                              activeUser: activeUser,
                              addUserTileTrailing: const _SettingsIconButton(),
                              reverse: reverse,
                              onLoginPressed: () {
                                context.pop();
                                _onLoginPressed(context);
                              }
                            );
                          }
                          else if (widget.platformContext.platform.hasLogin) {
                            final bool hasLoginRequiredSettings = widget.platformContext.platform.loginRequiredSettingKeys != null;
                            return StreamBuilder(
                              stream: hasLoginRequiredSettings ? Database.instance.watchSettings(widget.platformContext.platform.loginRequiredSettingKeys!) : null,
                              builder: (context, snapshot) {
                                if (hasLoginRequiredSettings && (!snapshot.hasData || (snapshot.data?.values.any((value) => value == null) ?? true))) {
                                  return const ListTile(leading: _SettingsIconButton());
                                }
                                return ListTile(
                                  title: Text('Login to $platformNameOrHost'),
                                  onTap: () => _onLoginPressed(context),
                                  trailing: const _SettingsIconButton(),
                                );
                              }
                            );
                          }
                          return const ListTile(leading: _SettingsIconButton());
                        }
                      ),
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
                                      footer,
                                      divider,
                                      communityList,
                                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom)
                                    ]
                                  : [
                                      communityList,
                                      divider,
                                      footer
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
                        return PopupMenuItem(
                          value: entry.value,
                          child: entry.key
                        );
                      })
                    );
                  }
                  if (popupMenuItems.isNotEmpty) {
                    iconActions.add(
                      PopupMenuButton(
                        onSelected: (callback) => callback(context),
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
                      if (widget.onPullRefresh != null) {
                        body = CustomRefreshIndicator(
                          key: widget.refreshIndicatorKey,
                          edgeOffset: appBarOffset,
                          onRefresh: () async {
                            await widget.onPullRefresh!();
                          },
                          child: body
                        );
                      }
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

class _LoginDialog extends StatefulWidget {

  final Platform platform;
  final String title;
  final List<LoginField> loginFields;
  final Future<LoginResult> Function(Map<String, String> credentials) performLogin;

  const _LoginDialog({
    required this.platform,
    required this.title,
    required this.loginFields,
    required this.performLogin
  });

  @override
  State<_LoginDialog> createState() => _LoginDialogState();

}

class _LoginDialogState extends State<_LoginDialog> {

  late final List<TextEditingController> _textEditingControllers;
  bool _canLogin = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textEditingControllers = [];
    for (var _ in widget.loginFields) {
      final controller = TextEditingController();
      controller.addListener(_onTextUpdate);
      _textEditingControllers.add(controller);
    }
  }

  @override
  void dispose() {
    for (final controller in _textEditingControllers) {
      controller.removeListener(_onTextUpdate);
      controller.dispose();
    }
    super.dispose();
  }

  void _onTextUpdate() {
    final bool canLogin = _textEditingControllers.every((controller) => controller.text.isNotEmpty);
    if (canLogin != _canLogin) {
      setState(() {
        _canLogin = canLogin;
      });
    }
  }

  void _onError(String message) {
    setState(() {
      _errorMessage = 'Error: $message';
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = List.generate(
      widget.loginFields.length,
      (index) {
        final field = widget.loginFields[index];
        return TextField(
          enabled: !_isLoading,
          controller: _textEditingControllers[index],
          obscureText: field.type == LoginFieldType.secret,
          inputFormatters: field.type == LoginFieldType.identity ? [NameInputFormatter(replacements: widget.platform.userNameCleaningRegexReplacements)] : null,
          decoration: InputDecoration(labelText: field.label)
        );
      }
    );
    if (_errorMessage != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error)
          ),
        )
      );
    }
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('Cancel'),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: _isLoading ? 0 : 1,
              child: TextButton(
                onPressed: _canLogin && !_isLoading
                  ? () async {
                      setState(() {
                        _isLoading = true;
                      });
                      final result = await widget.performLogin({
                        for (var i = 0; i < widget.loginFields.length; i++)
                          widget.loginFields[i].label: _textEditingControllers[i].text
                      });
                      setState(() {
                        _isLoading = false;
                      });
                      switch (result) {
                        case LoginSuccess success:
                          if (context.mounted) {
                            context.pop(success.user);
                          }
                          return;
                        case LoginError error:
                          _onError(error.message ?? 'something went wrong');
                          return;
                      }
                    }
                  : null,
                child: const Text('Login'),
              ),
            ),
            if (_isLoading)
              const CustomCircularProgressIndicator(size: 16)
          ],
        )
      ],
    );
  }

}

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

  final PlatformContext platformContext;
  final Iterable<LoggedInUser> loggedInUsers;
  final LoggedInUser activeUser;
  final bool reverse;
  final Widget? addUserTileTrailing;
  final VoidCallback onLoginPressed;

  const _UserList({
    required this.platformContext,
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

  void _onTileLongPress(LoggedInUser user) {
    showSimpleOptionsDialog(
      context: context,
      title: user.prefixedNameAndMaybeHost,
      options: {
        'View profile': () {
          context.pop();
          context.push(() {
            return UserDetailsScreen(
              platformContext: widget.platformContext,
              user: user
            );
          });
        },
        'Logout': () {
          UserManager.removeLoggedInUser(user);
          context.showSnackBarMessage('Logged out of ${user.name}');
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      AnimatedCrossFade(
        crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 500),
        sizeCurve: Curves.easeInOutCubicEmphasized, 
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
            ...widget.loggedInUsers.where((user) => user != widget.activeUser).map((user) {
              return _UserListTile(
                platform: user.platform,
                user: user,
                onTap: () async {
                  UserManager.setActiveUser(user.platform, user);
                  setState(() => _isExpanded = false);
                },
                onLongPress: () => _onTileLongPress(user)
              );
            })
          ],
        ),
      ),
      _UserListTile(
        platform: widget.activeUser.platform,
        user: widget.activeUser,
        trailing: IconButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          icon: ExpansionIcon(
            up: _isExpanded,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubicEmphasized,
          ),
        ),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        onLongPress: () => _onTileLongPress(widget.activeUser)
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
    return Material(
      child: ListTile(
        horizontalTitleGap: 8,
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _UserIcon(
            key: ValueKey('${user.host}-${user.id}'),
            user: user
          )
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Easing.emphasizedDecelerate,
          switchOutCurve: Easing.emphasizedAccelerate,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Align(
            key: ValueKey('${user.host}-${user.id}'),
            alignment: Alignment.centerLeft,
            child: Text(user.name),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
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
        url: user.iconUrl,
        size: 34,
        placeholderIcon: Icons.no_accounts_rounded,
      ),
    );
  }
}

class _CommunityList extends StatefulWidget {

  final GlobalKey<ScaffoldState> scaffoldKey;
  final PlatformContext platformContext;
  final Community? activeCommunity;
  final bool reverse;

  const _CommunityList({
    required this.scaffoldKey,
    required this.platformContext,
    required this.activeCommunity,
    required this.reverse,
  });

  @override
  State<_CommunityList> createState() => _CommunityListState();

}

class _CommunityListState extends State<_CommunityList> {

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
    _visibleCommunities = Communities.saved.value.toList();
    _searchPlatform = widget.platformContext.platform;
    final savedSearchType = Settings.searchType.value;
    _searchType = savedSearchType == null || (savedSearchType == SearchType.all && !_canSearchPlatform) || (savedSearchType == SearchType.withinCommunity && !_canSearchWithinCommunity) ? SearchType.community : savedSearchType;
    _updateSearchBarTexts();
    _searchBarFocusNode.addListener(_onSearchBarFocusChanged);
    Communities.saved.addListener(_onSavedCommunitiesChanged);
    _sortVisibleCommunities();
  }

  @override
  void dispose() {
    Communities.saved.removeListener(_onSavedCommunitiesChanged);
    _searchBarFocusNode.removeListener(_onSearchBarFocusChanged);
    _searchController.dispose();
    _searchBarFocusNode.dispose();
    super.dispose();
  }

  void _onSavedCommunitiesChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _updateVisibleCommunities();
      _sortVisibleCommunities();
    });
  }

  void _updateVisibleCommunities() {
    _visibleCommunities = (_searchQuery.isEmpty ? Communities.saved.value : Communities.saved.value.where((community) => community.prefixedNameAndMaybeHost.contains(_searchQuery))).toList();
  }

  void _sortVisibleCommunities() {
    _visibleCommunities.sort((c1, c2) {
      if (c1.isFavorite != c2.isFavorite) {
        return c1.isFavorite ? -1 : 1;
      }
      return (c1.name ?? '').compareTo((c2.name ?? ''));
    });
  }

  void _onSearchBarFocusChanged() {
    setState(() {
      _isSearchBarFocused = _searchBarFocusNode.hasFocus;
      if (_searchType == SearchType.community || _searchType == SearchType.user) {
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchBarHint.toLowerCase() : _searchBarHint.toTitleCase();
      }
      _updateIsSearchValid();
    });
  }

  void _navigateToCommunity(Community community) {
    widget.scaffoldKey.currentState?.closeDrawer();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => CommunityScreen(community: community)),
      (route) => route.isFirst
    );
  }

  // void _navigateToCommunity(Community community) {
  //   if (community.platform == Settings.homeCommunityPlatform.value && community.host == Settings.homeCommunityHost.value && community.name == Settings.homeCommunityName.value) {
  //     routeObserver.staleRoutes.add(routeObserver.routes.first);
  //     Navigator.popUntil(context, (route) => route.isFirst);
  //     return;
  //   }
  //   final routeName = '${community.platform.name}/${community.host}/community/${community.name}';
  //   final existingRoute = routeObserver.routes.where((route) => route.settings.name == routeName).firstOrNull;
  //   if (existingRoute != null) {
  //     routeObserver.staleRoutes.add(existingRoute);
  //     Navigator.of(context).popUntil((route) => route.settings.name == routeName);
  //     return;
  //   }
  //   Navigator.pushAndRemoveUntil(
  //     context,
  //     MaterialPageRoute(
  //       settings: RouteSettings(name: routeName),
  //       builder: (context) => CommunityScreen(activeCommunity: community, community: community)
  //     ),
  //     (route) => route.isFirst
  //   );
  // }

  bool get _canSearchPlatform => _searchPlatform.preferredHost != null || _searchPlatform == widget.platformContext.platform;

  bool get _canSearchWithinCommunity => widget.platformContext.platform == _searchPlatform && widget.activeCommunity?.name != null && _searchPlatform.canSearchWithinCommunities && !(_searchPlatform.aggregateCommunityNames?.contains(widget.activeCommunity!.name) ?? false);

  void _cyclePlatform() {
    setState(() {
      _searchPlatform = Platform.values[(Platform.values.indexOf(_searchPlatform) + 1) % Platform.values.length];
      if (_searchType == SearchType.all) {
        if (_searchPlatform.preferredHost == null && _searchPlatform != widget.platformContext.platform) {
          _updateSearchType(SearchType.community);
        }
      }
      else if (_searchType == SearchType.withinCommunity) {
        if (!_searchPlatform.canSearchWithinCommunities) {
          _updateSearchType(SearchType.all);
        }
      }
      _updateSearchBarTexts();
      _updateIsSearchValid();
    });
  }

  void _cycleSearchType() {
    setState(() {
      final searchTypes = SearchType.values.toList();
      if (!_canSearchPlatform) {
        searchTypes.remove(SearchType.all);
      } 
      if (!_canSearchWithinCommunity) {
        searchTypes.remove(SearchType.withinCommunity);
      }
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
        _searchController.text = _cleanName(_searchController.text, _searchPlatform.communityNameCleaningRegexReplacements);
        _searchBarPrefixText = _searchPlatform.preferredCommunityPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchPlatform.communityLabel : _searchPlatform.communityLabel.toTitleCase();
      case SearchType.user:
        _searchController.text = _cleanName(_searchController.text, _searchPlatform.userNameCleaningRegexReplacements);
        _searchBarPrefixText = _searchPlatform.userPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? 'username' : 'Username';
      case SearchType.withinCommunity:
        _searchBarPrefixText = null;
        _searchBarHint = 'Search ${_searchPlatform.getPrefixedCommunityName(widget.activeCommunity!.nameAndMaybeHost)}';
      case SearchType.all:
        _searchBarPrefixText = null;
        _searchBarHint = 'Search ${_searchPlatform.supportsMultipleHosts ? widget.platformContext.host : _searchPlatform.name.toTitleCase()}';
    }
  }

  String _cleanName(String value, List<(String, String)> regexes) {
    if (value.isEmpty) {
      return '';
    }
    String cleaned = value;
    for (final (regex, replacement) in regexes) {
      cleaned = cleaned.replaceAll(RegExp(regex), replacement);
    }
    return cleaned;
  }

  void _updateIsSearchValid() {
    _isSearchValid = switch (_searchType) {
      SearchType.community => RegExp(_searchPlatform.communityNameValidationRegex).hasMatch(_searchQuery),
      SearchType.user => RegExp(_searchPlatform.userNameValidationRegex).hasMatch(_searchQuery),
      SearchType.withinCommunity => _searchQuery.isNotEmpty,
      SearchType.all => _searchQuery.isNotEmpty,
    };
  }

  (String, String?)? _getHostAndNameFromSearchQuery(String value) {
    if (_searchPlatform.preferredHost != null) {
      return (_searchPlatform.preferredHost!, value.isNotEmpty ? value : null);
    }
    final match = RegExp(_searchPlatform.hostAndNameFromSearchQueryRegex!).firstMatch(value);
    if (match != null) {
      final communityName = match.group(1);
      return (match.group(2)!, communityName!.isNotEmpty ? communityName : null);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final leadingForegroundColor = ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark ? Colors.white : Colors.black;
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorAccents,
      builder: (context, showPlatformColorAccents, child) {
        return ValueListenableBuilder(
          valueListenable: UserManager.loggedInUsersListenable,
          builder: (context, allLoggedInUsers, child) {
            final List<(Platform, String, String?)> loggedInUsersCuratedCommunities = _searchQuery.isEmpty ? allLoggedInUsers.map((user) => (user.platform, user.host, user.hostIconUrl)).toSet().toList() : [];
            return ValueListenableBuilder(
              valueListenable: UserManager.getActiveUserListenable(widget.platformContext.platform),
              builder: (context, activeUser, child) {
                final headerCount = loggedInUsersCuratedCommunities.length + 1;
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
                          color: showPlatformColorAccents ? _searchPlatform.color : primaryColor,
                          borderRadius: BorderRadius.horizontal(
                            left: const Radius.circular(20),
                            right: Radius.circular(leadingRightCornerRadius),
                          ),
                        ),
                        child: leadingChild
                      );
                      Widget searchBar = SearchBar(
                        controller: _searchController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(right: 8)),
                        hintText: _searchBarHint,
                        hintStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white60)),
                        inputFormatters: [_InputFormatter(searchPlatform: _searchPlatform, searchType: _searchType)],
                        // inputFormatters: _searchType != SearchType.all && _searchType != SearchType.withinCommunity ? [FilteringTextInputFormatter.allow(_searchNameAllowedRegex)] : null,
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
                          if (lowerCase.isNotEmpty && !RegExp(_searchPlatform.communityNameTypingRegex).hasMatch(lowerCase) && !RegExp(_searchPlatform.userNameTypingRegex).hasMatch(lowerCase)) {
                            outerLoop:
                            for (final platform in {_searchPlatform, ...F.appFlavor.platforms}) {
                              for (final prefix in platform.communityPrefixes) {
                                if (lowerCase.startsWith(prefix)) {
                                  cleanValue = cleanValue.substring(prefix.length);
                                  _updateSearchType(SearchType.community);
                                  _searchPlatform = platform;
                                  _searchBarPrefixText = platform.preferredCommunityPrefix;
                                  _searchBarHint = platform.communityLabel;
                                  handledPrefix = true;
                                  break outerLoop;
                                }
                              }
                              if (lowerCase.startsWith(platform.userPrefix)) {
                                cleanValue = cleanValue.substring(platform.userPrefix.length);
                                _updateSearchType(SearchType.user);
                                _searchPlatform = platform;
                                _searchBarPrefixText = platform.userPrefix;
                                _searchBarHint = 'username';
                                handledPrefix = true;
                                break;
                              }
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
                                  final startsWith1 = c1.prefixedNameAndMaybeHost.startsWith(cleanValue);
                                  final startsWith2 = c2.prefixedNameAndMaybeHost.startsWith(cleanValue);
                                  if (startsWith1 != startsWith2) {
                                    return startsWith1 ? -1 : 1;
                                  }
                                  return c1.prefixedNameAndMaybeHost.compareTo(c2.prefixedNameAndMaybeHost);
                                });
                              }
                              _updateIsSearchValid();
                            });
                          }
                        },
                        onSubmitted: (value) {
                          switch (_searchType) {
                            case SearchType.community:
                              if (!RegExp(_searchPlatform.communityNameValidationRegex).hasMatch(value)) {
                                return;
                              }
                              final (host, communityName) = _getHostAndNameFromSearchQuery(value)!;
                              final community = Community(
                                platform: _searchPlatform,
                                host: host,
                                name: communityName
                              );
                              _navigateToCommunity(community);
                              Communities.saved.add(community);
                            case SearchType.user:
                              if (!RegExp(_searchPlatform.userNameValidationRegex).hasMatch(value)) {
                                return;
                              }
                              context.pop();
                              context.push(() {
                                final (host, userName) = _getHostAndNameFromSearchQuery(value)!;
                                return UserDetailsScreen(
                                  platformContext: widget.platformContext,
                                  user: User(
                                    platform: _searchPlatform,
                                    host: host,
                                    name: userName!
                                  )
                                );
                              });
                            case SearchType.withinCommunity:
                              final query = value.trim();
                              if (query.isEmpty) {
                                return;
                              }
                              context.pop();
                              context.push(() {
                                return SearchScreen(
                                  platformContext: widget.platformContext,
                                  searchWithinCommunityName: widget.activeCommunity!.nameAndMaybeHost,
                                  query: query,
                                );
                              });
                              return;
                            case SearchType.all:
                              final query = value.trim();
                              if (query.isEmpty) {
                                return;
                              }
                              context.pop();
                              context.push(() {
                                return SearchScreen(
                                  platformContext: PlatformContext(platform: _searchPlatform, host: _searchPlatform.preferredHost ?? widget.platformContext.host),
                                  searchWithinCommunityName: null,
                                  query: query
                                );
                              });
                          }
                        },
                      );
                      if (showPlatformColorAccents) {
                        searchBar = Theme(
                          data: theme.copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: _searchPlatform.color.withAlpha(200),
                              selectionColor: _searchPlatform.color.withAlpha(75),
                              selectionHandleColor: _searchPlatform.color,
                            )
                          ),
                          child: searchBar
                        );
                      }
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
                    
                    if (index <= loggedInUsersCuratedCommunities.length) {
                      final loggedInUserCuratedCommunity = loggedInUsersCuratedCommunities[index - 1];
                      final loggedInCommunity = Community(
                        platform: loggedInUserCuratedCommunity.$1,
                        host: loggedInUserCuratedCommunity.$2,
                        name: null
                      );
                      return _CommunityNameListTile(
                        platformContext: widget.platformContext,
                        activeCommunity: widget.activeCommunity,
                        community: loggedInCommunity,
                        isFixed: true,
                        leading: IconButton(
                          onPressed: () {},
                          icon: loggedInUserCuratedCommunity.$3 != null
                            ? ExtendedImage.network(
                                loggedInUserCuratedCommunity.$3!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              )
                            : Stack(
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
                                    Icons.reddit_rounded, //TODO
                                    size: 32,
                                    color: loggedInUserCuratedCommunity.$1.color
                                  ),
                              ],
                          )
                        ),
                        title: loggedInUserCuratedCommunity.$1.supportsMultipleHosts ? CommunityNameText(community: loggedInCommunity) : Text(loggedInUserCuratedCommunity.$1.rootCommunityName ?? ''),
                        onTap: _navigateToCommunity
                      );
                    }
                
                    final community = _visibleCommunities[index - headerCount];
                    final IconData icon;
                    final Color? color;
                    if (community.isFavorite) {
                      icon = Icons.star_rounded;
                      color = theme.colorScheme.onSurface;
                    }
                    else {
                      icon = Icons.star_border_rounded;
                      color = theme.colorScheme.onSurfaceVariant;
                    }
                    return _CommunityNameListTile(
                      platformContext: widget.platformContext,
                      activeCommunity: widget.activeCommunity,
                      community: community,
                      isFixed: false,
                      leading: IconButton(
                        icon: Icon(
                          icon,
                          color: color,
                          size: 24
                        ),
                        onPressed: () => Communities.saved.update(community.copyWith(isFavorite: !community.isFavorite))
                      ),
                      title: ValueListenableBuilder(
                        valueListenable: Settings.showPlatformColorTextAccents,
                        builder: (context, showPlatformColorTextAccents, child) {
                          return CommunityNameText(
                            community: community,
                            prefixColor: showPlatformColorTextAccents ? community.platform.color : null,
                            nameColor: color,
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
                    final List<Future> futures = [];
                    for (final user in UserManager.loggedInUsersListenable.value) {
                      futures.add(getApi(widget.platformContext, user).fetchSubscribedCommunities());
                    }
                    await Future.wait(futures);
                  },
                  child: listView
                );
              }
            );
          }
        );
      }
    );
  }

}

class _InputFormatter extends TextInputFormatter {

  final Platform searchPlatform;
  final SearchType searchType;

  const _InputFormatter({
    required this.searchPlatform,
    required this.searchType,
  });

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (searchType == SearchType.all || searchType == SearchType.withinCommunity) {
      return newValue;
    }
    final text = newValue.text.toLowerCase().trim();
    final List<String> prefixes;
    final List<(String, String)> regexReplacements;
    final String typingRegexString;
    if (searchType == SearchType.community) {
      prefixes = searchPlatform.communityPrefixes;
      regexReplacements = searchPlatform.communityNameCleaningRegexReplacements;
      typingRegexString = searchPlatform.communityNameTypingRegex;
    }
    else {
      prefixes = [searchPlatform.userPrefix];
      regexReplacements = searchPlatform.userNameCleaningRegexReplacements;
      typingRegexString = searchPlatform.userNameTypingRegex;
    }
    String foundPrefix = '';
    String body = text;
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        foundPrefix = prefix;
        body = body.substring(prefix.length);
      }
    }
    if (newValue.text.length > oldValue.text.length + 1) {
      for (final (regex, replacement) in regexReplacements) {
        body = body.replaceAll(RegExp(regex), replacement);
      }
    }
    if (F.appFlavor.platforms.any((platform) => platform.communityPrefixes.any((prefix) => prefix.startsWith(text)) || platform.userPrefix.startsWith(text))) {
      body = foundPrefix + body;
      return newValue.copyWith(
        text: body,
        selection: TextSelection.collapsed(offset: body.length)
      );
    }
    if (body.isEmpty || RegExp(typingRegexString).hasMatch(body)) {
      return newValue.copyWith(
        text: body,
        selection: TextSelection.collapsed(offset: body.length)
      );
    }
    return oldValue;
  }

}

class _CommunityNameListTile extends StatelessWidget {
  
  final PlatformContext platformContext;
  final Community? activeCommunity;
  final Community community;
  final Widget? leading;
  final Widget title;
  final bool isFixed;
  final void Function(Community community) onTap;

  const _CommunityNameListTile({
    required this.platformContext,
    required this.activeCommunity,
    required this.community,
    required this.leading,
    required this.title,
    required this.isFixed,
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
          onLongPress: !isFixed
            ? () {
                final Map<String, void Function()> options = {};
                if (community.id != null) {
                  final activeUser = UserManager.getActiveUser(platformContext.platform);
                  if (activeUser?.platform == community.platform) {
                    if (Communities.isSubscribed(activeUser!, community.id!)) {
                      options['Unsubscribe'] = () => getApi(platformContext, activeUser).unsubscribeFromCommunity(community.id!);
                    }
                    else {
                      options['Subscribe'] = () => getApi(platformContext, activeUser).subscribeToCommunity(community.id!);
                    }
                  }
                }
                showSimpleOptionsDialog(
                  context: context,
                  title: community.prefixedNameAndMaybeHost,
                  options: options..['Remove'] = () => Communities.saved.remove(community)
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