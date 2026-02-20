import 'package:flutter/material.dart';

const _largeSize = 64.0;
const _largeStrokeWidth = 6.0;

class CustomCircularProgressIndicator extends StatelessWidget {

  final EdgeInsetsGeometry? padding;
  final Alignment? alignment;
  final double? size;
  final double? strokeWidth;
  final double? value;
  final Color? color;

  const CustomCircularProgressIndicator({
    super.key,
    this.padding,
    this.alignment,
    this.size,
    this.strokeWidth,
    this.value,
    this.color
  });

  @override
  Widget build(BuildContext context) {
    Widget child = CircularProgressIndicator.adaptive(
      strokeWidth: strokeWidth,
      strokeCap: StrokeCap.round,
      value: value,
      valueColor: color != null ? AlwaysStoppedAnimation(color) : null,
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

  final EdgeInsetsGeometry padding;
  
  const LargeCenteredCircularProgressIndicator({
    super.key,
    this.padding = const EdgeInsetsGeometry.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return CustomCircularProgressIndicator(
      alignment: Alignment.center,
      padding: padding,
      size: _largeSize,
      strokeWidth: _largeStrokeWidth,
    );
  }

}