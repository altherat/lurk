import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class CustomRefreshIndicator extends StatelessWidget {

  final Platform platform;
  final GlobalKey<RefreshIndicatorState>? flutterRefreshIndicatorKey;
  final RefreshCallback? onRefresh;
  final Widget child;

  const CustomRefreshIndicator({
    super.key,
    required this.platform,
    this.flutterRefreshIndicatorKey,
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
          color: showPlatformColorAccents ? platform.color : null,
          notificationPredicate: onRefresh != null ? defaultScrollNotificationPredicate : (notification) => false,
          onRefresh: () async {
            onRefresh?.call();
          },
          child: this.child,
        );
      }
    );
  }
  
}