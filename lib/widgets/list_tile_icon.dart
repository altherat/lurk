import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';

class ListTileIcon extends StatelessWidget {
  
  final Platform platform;
  final String? url;
  final double size;
  final IconData placeholderIcon;

  const ListTileIcon({
    super.key,
    required this.platform,
    required this.url,
    this.size = 40.0,
    required this.placeholderIcon
  });

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _Placeholder(
        icon: placeholderIcon,
        size: size
      );
    }
    return ExtendedImage.network(
      url!,
      width: size,
      height: size,
      cache: true,
      fit: BoxFit.cover,
      shape: BoxShape.circle,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return const CustomCircularProgressIndicator(
              alignment: Alignment.center,
              size: 24,
              strokeWidth: 2.5
            );
          case LoadState.completed:
            return null;
          case LoadState.failed:
            return _Placeholder(
              icon: placeholderIcon,
              size: size
            );
        }
      }
    );
  }

}

class _Placeholder extends StatelessWidget {

  final IconData icon;
  final double size;

  const _Placeholder({
    required this.icon,
    required this.size
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        maxWidth: 60,
        maxHeight: 60,
        child: Icon(
          icon,
          size: size * 1.2,
          color: Colors.white24,
        ),
      ),
    );
  }
  
}