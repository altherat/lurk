import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class CustomRefreshIndicator extends StatelessWidget {

  final GlobalKey<RefreshIndicatorState>? flutterRefreshIndicatorKey;
  final Platform? platform;
  final RefreshCallback? onRefresh;
  final Widget child;

  const CustomRefreshIndicator({
    super.key,
    this.flutterRefreshIndicatorKey,
    this.platform,
    required this.onRefresh,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.showMorePlatformColorAccents,
      builder: (context, showMorePlatformColorAccents, child) {
        return RefreshIndicator(
          key: flutterRefreshIndicatorKey,
          displacement: Constants.refreshIndicatorDisplacement,
          color: showMorePlatformColorAccents ? platform?.color : null,
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