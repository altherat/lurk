import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/platform_context.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_interactive_viewer.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/media_scaffold.dart';

class ImageViewerScreen extends StatelessWidget {

  final PlatformContext platformContext;
  final String url;
  final Post? post;
  final Size? size;

  const ImageViewerScreen({
    super.key,
    required this.platformContext,
    required this.url,
    this.post,
    this.size
  });

  ImageViewerScreen.fromPost({
    Key? key,
    required PlatformContext platformContext,
    required Post post,
  }) : this(
    key: key,
    platformContext: platformContext,
    url: post.linkUrl!,
    post: post,
    size: post.mediaSize,
  );

  void _onSave(BuildContext context) {
    saveImage(
      context: context,
      platform: platformContext.platform,
      url: url,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      platformContext: platformContext,
      url: url,
      type: 'image',
      post: post,
      onSave: _onSave,
      body: Hero(
        tag: 'media_$url',
        // transitionOnUserGestures: true,
        child: SizedBox.expand(
          child: GestureDetector(
            onLongPress:() {
              HapticFeedback.mediumImpact();
              showSimpleOptionsBottomSheet(
                context: context,
                options: MediaScaffold.getOptions(
                  platformContext: platformContext,
                  type: 'image',
                  url: url,
                  post: post,
                  onSave: _onSave,
                )
              );
            },
            child: CustomInteractiveViewer(
              child: ExtendedImage.network(
                url,
                headers: {'User-Agent': platformContext.platform.savedOrDefaultUserAgent},
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