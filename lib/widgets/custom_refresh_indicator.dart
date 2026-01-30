import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class CustomRefreshIndicator extends StatelessWidget {

  final Platform platform;
  final GlobalKey<RefreshIndicatorState>? flutterRefreshIndicatorKey;
  final double edgeOffset;
  final RefreshCallback? onRefresh;
  final Widget child;

  const CustomRefreshIndicator({
    super.key,
    required this.platform,
    this.flutterRefreshIndicatorKey,
    this.edgeOffset = 0,
    required this.onRefresh,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorAccents,
      builder: (context, showPlatformColorAccents, child) {
        return RefreshIndicator(
          key: flutterRefreshIndicatorKey,
          displacement: Constants.refreshIndicatorDisplacement,
          edgeOffset: edgeOffset,
          color: showPlatformColorAccents ? platform.color : null,
          notificationPredicate: onRefresh != null ? defaultScrollNotificationPredicate : (notification) => false,
          onRefresh: () async {
            await onRefresh?.call();
          },
          child: this.child,
        );
      }
    );
  }
  
}