import 'package:flutter/material.dart';
import 'package:lurk/app.dart' as App;
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class HomeScreen extends StatefulWidget {

  final GlobalKey<MainScaffoldState> scaffoldKey;

  const HomeScreen({
    super.key,
    required this.scaffoldKey,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {

  bool _isActive = true;
  late Community _homeCommunity;

  @override
  void initState() {
    super.initState();
    _homeCommunity =_getHomeCommunity();
    Settings.homeCommunityPlatform.addListener(_onCommunityChanged);
    Settings.homeCommunityName.addListener(_onCommunityChanged);
  }

  @override
  void dispose() { 
    Settings.onSessionsInvalidated = null;
    Settings.homeCommunityPlatform.removeListener(_onCommunityChanged);
    Settings.homeCommunityName.removeListener(_onCommunityChanged);
    App.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    App.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    _isActive = false;
  }

  @override
  void didPopNext() {
    _isActive = true;
    if (Settings.homeCommunityPlatform.value != _homeCommunity.platform || Settings.homeCommunityName.value != _homeCommunity.name) {
      setState(() {
        _homeCommunity = _getHomeCommunity();
      });
    }
  }

  Community _getHomeCommunity() {
    return Community(
      platform: Settings.homeCommunityPlatform.value,
      name: Settings.homeCommunityName.value
    );
  }

  void _onCommunityChanged() {
    if (!_isActive) return;
    setState(() {
      _homeCommunity = _getHomeCommunity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommunityScreen(
      key: ValueKey('home-${_homeCommunity.platform.name}-${_homeCommunity.name}'),
      community: _homeCommunity,
      scaffoldKey: widget.scaffoldKey
    );
  }

}