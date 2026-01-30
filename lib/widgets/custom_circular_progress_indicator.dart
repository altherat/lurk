import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

const _largeSize = 64.0;
const _largeStrokeWidth = 6.0;

class CustomCircularProgressIndicator extends StatelessWidget {

  final Platform? platform;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;
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
    Widget child = PlatformCircularProgressIndicator(
      platform: platform,
      strokeWidth: strokeWidth,
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
    return Align(
      alignment: alignment,
      child: child,
    );
  }

}

class PlatformCircularProgressIndicator extends StatelessWidget {

  final Platform? platform;
  final double? strokeWidth;

  const PlatformCircularProgressIndicator({
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

class LargeCenteredCircularProgressIndicator extends StatelessWidget {

  final Platform? platform;
  
  const LargeCenteredCircularProgressIndicator({
    super.key,
    this.platform
  });

  @override
  Widget build(BuildContext context) {
    return CustomCircularProgressIndicator(
      platform: platform,
      size: _largeSize,
      strokeWidth: _largeStrokeWidth,
    );
  }

}