import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class CustomRefreshIndicator extends StatelessWidget {

  final Platform? platform;
  final RefreshCallback onRefresh;
  final Widget child;

  const CustomRefreshIndicator({
    super.key,
    this.platform,
    required this.onRefresh,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    if (platform == null) {
      return RefreshIndicator(
        displacement: Constants.refreshIndicatorDisplacement,
        onRefresh: onRefresh,
        child: child,
      );
    }
    return ValueListenableBuilder(
      valueListenable: Settings.showMorePlatformColorAccents,
      builder: (context, showMorePlatformColorAccents, child) {
        return RefreshIndicator(
          displacement: Constants.refreshIndicatorDisplacement,
          color: showMorePlatformColorAccents ? platform!.color : null,
          onRefresh: onRefresh,
          child: this.child,
        );
      }
    );
  }
  
}