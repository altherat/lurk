import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_interactive_viewer.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/media_scaffold.dart';

class ImageViewerScreen extends StatelessWidget {

  final Platform platform;
  final String url;
  final Post? post;
  final Size? size;

  const ImageViewerScreen({
    super.key,
    required this.platform,
    required this.url,
    this.post,
    this.size
  });

  void _onSave(BuildContext context) {
    saveImage(
      context: context,
      platform: platform,
      url: url,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      platform: platform,
      url: url,
      type: 'image',
      post: post,
      onSave: () => _onSave(context),
      body: Hero(
        tag: 'media_$url',
        // transitionOnUserGestures: true,
        child: SizedBox.expand(
          child: GestureDetector(
            onLongPress:() {
              HapticFeedback.mediumImpact();
              showSimpleTextOptionsBottomSheet(
                context: context,
                options: MediaScaffold.getOptions(
                  context: context,
                  type: 'image',
                  url: url,
                  onSave: () => _onSave(context)
                )
              );
            },
            child: CustomInteractiveViewer(
              child: ExtendedImage.network(
                url,
                headers: {'User-Agent': platform.api.savedOrDefaultUserAgent},
                fit: BoxFit.contain, 
                alignment: Alignment.topCenter,
                loadStateChanged: (state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      final progressIndicator = const LargeCenteredCircularProgressIndicator();
                      final size = this.size ?? post?.mediaSize;
                      if (size != null) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: AspectRatio(
                            aspectRatio: size.width / size.height,
                            child: progressIndicator,
                          ),
                        );
                      }
                      return progressIndicator;
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
          ),
        ),
      ),
    );
  }
  
}