import 'package:flutter/material.dart';
import 'package:lurk/app.dart' as App;
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/services/settings.dart';

class HomeScreen extends StatefulWidget {

  final GlobalKey<ScaffoldState> scaffoldKey;

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
    _updateHomeCommunity();
    Settings.homeCommunityPlatform.addListener(_updateHomeCommunity);
    Settings.homeCommunityName.addListener(_updateHomeCommunity);
  }

  @override
  void dispose() { 
    Settings.homeCommunityPlatform.removeListener(_updateHomeCommunity);
    Settings.homeCommunityName.removeListener(_updateHomeCommunity);
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

  void _updateHomeCommunity() {
    if (!_isActive) return;
    setState(() {
      _homeCommunity = _getHomeCommunity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PostsScreen(
      key: ValueKey('home-${_homeCommunity.platform.name}-${_homeCommunity.name}'),
      community: _homeCommunity,
      scaffoldKey: widget.scaffoldKey
    );
  }

}