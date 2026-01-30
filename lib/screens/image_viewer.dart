import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/media_scaffold.dart';

class ImageViewerScreen extends StatelessWidget {

  final Platform platform;
  final String url;
  final Post? post;

  const ImageViewerScreen({
    super.key,
    required this.platform,
    required this.url,
    this.post,
  });

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      platform: platform,
      url: url,
      type: 'image',
      post: post,
      onSave: () {
        saveImage(
          context: context,
          platform: platform,
          url: url,
        );
      },
      body: SizedBox.expand(
        child: ExtendedImage.network(
          url,
          headers: {'User-Agent': platform.api.savedOrDefaultUserAgent},
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
                return LargeCenteredCircularProgressIndicator(platform: platform);
              case LoadState.completed:
                return state.completedWidget;
              case LoadState.failed:
                return const Center(
                  child: LargeVerticalIconMessage(
                    icon: Icons.broken_image_rounded,
                    message: 'Something went wrong'
                  )
                );
            }
          },
        ),
      ),
    );
  }
  
}