import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/screens/home.dart';
import 'package:lurk/services/history.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';

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
          color: Constants.popupMenuColor
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
          backgroundColor: Colors.black,
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: Constants.primaryColor,
          actionBackgroundColor: Constants.lighterBackgroundColor,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Constants.dialogBackgroundColor
        ),
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