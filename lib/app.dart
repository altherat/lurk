
import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class App extends StatelessWidget {

  const App({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: .dark(
          primary: Constants.primaryColor,
          surface: Colors.black,
          secondaryContainer: Constants.primaryColor, 
        ),
        // splashColor: Constants.splashColor,
        // highlightColor: Constants.highlightColor,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Constants.primaryColor,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Constants.popupMenuColor
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Constants.dialogBackgroundColor
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Constants.textFieldHintColor),
          suffixIconColor: Constants.textFieldHintColor,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Constants.textFieldHintColor),
          )
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          refreshBackgroundColor: Constants.refreshIndicatorBackgroundColor
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Constants.scrollbarColor)
        ),
      ),
      home: const _Home()
    );
  }

}

class _Home extends StatefulWidget {

  const _Home({
    super.key
  });

  @override
  State<_Home> createState() => _HomeState();
  
}

class _HomeState extends State<_Home> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final Future<void> _servicesInitFuture;

  @override
  void initState() {
    super.initState();
    _servicesInitFuture = Future.wait([
      Settings.init(),
      History.init(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _servicesInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              if (didPop) {
                return;
              }
              if (!(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
            child: ValueListenableBuilder(
              valueListenable: Settings.homeCommunity,
              builder: (context, homeCommunity, child) {
                return PostsScreen(
                  community: homeCommunity,
                  scaffoldKey: _scaffoldKey
                );
              }
            )
          );
        }
        return LargeCircularProgressIndicator(platform: F.appFlavor.platforms.first);
      },
    );
  }

}