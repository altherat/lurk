import 'package:flutter/material.dart';
import 'package:lurk/app.dart' as App;
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/posts.dart';

class HomeScreen extends StatefulWidget {

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Community community;

  const HomeScreen({
    super.key,
    required this.scaffoldKey,
    required this.community
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {

  late Community _homeCommunity;

  @override
  void initState() {
    super.initState();
    _homeCommunity = widget.community;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    App.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    App.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (widget.community != _homeCommunity) {
      setState(() {
        _homeCommunity = widget.community;
      });
    }
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