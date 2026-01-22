import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';

class ImageViewerScreen extends StatelessWidget {

  final String url;
  final Community? community;
  final Post? post;

  const ImageViewerScreen({
    super.key,
    required this.url,
    this.community,
    this.post,
  });

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      url: url,
      type: 'image',
      community: community,
      post: post,
      body: SizedBox.expand(
        child: ExtendedImage.network(
          url,
          headers: {'User-Agent': Settings.userAgent.value},
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          mode: ExtendedImageMode.gesture,
          initGestureConfigHandler: (state) {
            return GestureConfig(
              minScale: 1,
            );
          },
          onDoubleTap: (ExtendedImageGestureState state) {
            state.handleDoubleTap(
              scale: state.gestureDetails?.totalScale == 1 ? 3 : 1,
              doubleTapPosition: state.pointerDownPosition,
            );
          },
          loadStateChanged: (state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                return const LargeCircularProgressIndicator();
              case LoadState.completed:
                return state.completedWidget;
              case LoadState.failed:
                final color = Theme.of(context).disabledColor;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_rounded, size: 80, color: color),
                      Text('Something went wrong', style: TextStyle(color: color)),
                    ],
                  ),
              );
            }
          },
        ),
      ),
    );
  }
  
}