import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/screens/home.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class App extends StatefulWidget {

  const App({
    super.key
  });

  @override
  State<App> createState() => _AppState();

}

class _AppState extends State<App> {

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
    return MaterialApp(
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        // pageTransitionsTheme: const PageTransitionsTheme(
        //   builders: {
        //     TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        //   },
        // ),
        colorScheme: .dark(
          primary: Constants.primaryColor,
          surface: Colors.black,
          onSurfaceVariant: Constants.secondaryTextColor,
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
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          actionTextColor: Constants.primaryColor,
          actionBackgroundColor: Constants.lighterBackgroundColor,
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
        tabBarTheme: const TabBarThemeData(
          dividerColor: Colors.transparent,
        )
      ),
      home: FutureBuilder(
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
              child: HomeScreen(scaffoldKey: _scaffoldKey)
            );
          }
          return const LargeCenteredCircularProgressIndicator();
        },
      )
    );
  }

}