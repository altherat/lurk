import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class CustomCircularProgressIndicator extends StatelessWidget {

  final Platform? platform;
  final double? strokeWidth;

  const CustomCircularProgressIndicator({
    super.key,
    this.platform,
    this.strokeWidth
  });

  @override
  Widget build(BuildContext context) {
    if (platform == null) {
      return CircularProgressIndicator.adaptive(strokeWidth: strokeWidth);
    }
    return ValueListenableBuilder(
      valueListenable: Settings.showPlatformColorAccents,
      builder: (context, showPlatformColorAccents, child) {
        return CircularProgressIndicator.adaptive(
          valueColor: showPlatformColorAccents ? AlwaysStoppedAnimation(platform!.color) : null,
          strokeWidth: strokeWidth
        );
      }
    );
  }

}