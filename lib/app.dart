import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/services/communities.dart';
import 'package:lurk/services/posts.dart';
import 'package:lurk/screens/home.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/user_manager.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/main_scaffold.dart';

final routeObserver = _RouteObserver();

class App extends StatefulWidget {

  const App({
    super.key
  });

  @override
  State<App> createState() => _AppState();

}

class _AppState extends State<App> {

  final _scaffoldKey = GlobalKey<MainScaffoldState>();
  late final Future<void> _servicesInitFuture;

  @override
  void initState() {
    super.initState();
    final db = Database.instance;
    _servicesInitFuture = Future.wait([
      Settings.init(db),
      UserManager.init(db),
      Communities.init(db),
      Posts.init(db),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: .dark(
          primary: Constants.primaryColor,
          surface: Colors.black,
          onSurfaceVariant: Constants.secondaryTextColor,
          secondaryContainer: Constants.primaryColor,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          refreshBackgroundColor: Constants.refreshIndicatorBackgroundColor
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Constants.primaryColor,
        ),
        tabBarTheme: const TabBarThemeData(
          dividerColor: Colors.transparent,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Constants.lighterBackgroundColor,
        ),
        chipTheme: const ChipThemeData(
          showCheckmark: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Constants.textFieldHintColor),
          suffixIconColor: Constants.textFieldHintColor,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Constants.textFieldHintColor),
          )
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Constants.scrollbarColor)
        ),
        tooltipTheme: const TooltipThemeData(
          decoration: BoxDecoration(color: Constants.lighterBackgroundColor),
          textStyle: TextStyle(color: Colors.white)
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Constants.lighterBackgroundColor,
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          actionTextColor: Constants.primaryColor,
          actionBackgroundColor: Constants.lighterBackgroundColor,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Constants.lighterBackgroundColor
        ),
      ),
      home: FutureBuilder(
        future: _servicesInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ValueListenableBuilder(
              valueListenable: Settings.backOnHomeScreenShowCommunityList,
              builder: (context, backOnHomeScreenShowCommunityList, child) {
                return PopScope(
                  canPop: !backOnHomeScreenShowCommunityList,
                  onPopInvokedWithResult: (bool didPop, dynamic result) {
                    if (didPop) {
                      return;
                    }
                    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                      _scaffoldKey.currentState?.closeDrawer();
                    }
                    else {
                      _scaffoldKey.currentState?.showCommunityList();
                    }
                  },
                  child: HomeScreen(scaffoldKey: _scaffoldKey)
                );
              }
            );
          }
          return const LargeCenteredCircularProgressIndicator();
        },
      )
    );
  }

}

class _RouteObserver extends RouteObserver {

  final List<Route> routes = [];
  final Set<Route> staleRoutes = {};

  @override
  void didPush(Route route, Route? previousRoute) {
    routes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    routes.remove(route);
    staleRoutes.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    routes.remove(route);
    staleRoutes.remove(route);
    super.didRemove(route, previousRoute);
  }

}