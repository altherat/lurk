import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

const _largeSize = 64.0;
const _largeStrokeWidth = 6.0;

class CustomCircularProgressIndicator extends StatelessWidget {

  final Platform? platform;
  final EdgeInsetsGeometry? padding;
  final Alignment? alignment;
  final double? size;
  final double? strokeWidth;

  const CustomCircularProgressIndicator({
    super.key,
    this.platform,
    this.padding,
    this.alignment = Alignment.center,
    this.size,
    this.strokeWidth
  });

  @override
  Widget build(BuildContext context) {
    Widget child = platform != null
      ? ValueListenableBuilder(
          valueListenable: Settings.showPlatformColorAccents,
          builder: (context, showPlatformColorAccents, child) {
            return CircularProgressIndicator.adaptive(
              valueColor: showPlatformColorAccents ? AlwaysStoppedAnimation(platform!.color) : null,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round
            );
          }
        )
      : CircularProgressIndicator.adaptive(
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round
        );
    if (size != null) {
      child = SizedBox(
        width: size,
        height: size,
        child: child,
      );
    }
    if (padding != null) {
      child = Padding(
        padding: padding!,
        child: child,
      );
    }
    if (alignment != null) {
      child = Align(
        alignment: alignment!,
        child: child,
      );
    }
    return child;
  }

}

class LargeCenteredCircularProgressIndicator extends StatelessWidget {

  final Platform? platform;
  final EdgeInsetsGeometry padding;
  
  const LargeCenteredCircularProgressIndicator({
    super.key,
    this.platform,
    this.padding = const EdgeInsetsGeometry.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return CustomCircularProgressIndicator(
      platform: platform,
      alignment: Alignment.center,
      padding: padding,
      size: _largeSize,
      strokeWidth: _largeStrokeWidth,
    );
  }

}