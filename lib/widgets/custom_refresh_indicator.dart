import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class CustomRefreshIndicator extends StatefulWidget {

  final Platform platform;
  final double edgeOffset;
  final Widget child;
  final bool Function(ScrollNotification)? notificationPredicate;
  final RefreshCallback? onRefresh;

  const CustomRefreshIndicator({
    super.key,
    required this.platform,
    this.edgeOffset = 0,
    required this.child,
    this.notificationPredicate,
    required this.onRefresh,
  });

  @override
  State<CustomRefreshIndicator> createState() => CustomRefreshIndicatorState();
}

class CustomRefreshIndicatorState extends State<CustomRefreshIndicator> {

  final _key = GlobalKey<RefreshIndicatorState>();

  Future<void> show() => _key.currentState?.show() ?? Future.value();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorAccents,
      builder: (context, showPlatformColorAccents, child) {
        return RefreshIndicator(
          key: _key,
          displacement: Constants.refreshIndicatorDisplacement,
          edgeOffset: widget.edgeOffset,
          color: showPlatformColorAccents ? widget.platform.color : null,
          notificationPredicate: widget.notificationPredicate ?? (widget.onRefresh != null ? defaultScrollNotificationPredicate : (notification) => false),
          onRefresh: () async {
            await widget.onRefresh?.call();
          },
          child: this.widget.child,
        );
      }
    );
  }

}