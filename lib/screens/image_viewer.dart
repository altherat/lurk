import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/custom_interactive_viewer.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/media_scaffold.dart';

class ImageViewerScreen extends StatelessWidget {

  final Community activeCommunity;
  final String url;
  final Post? post;
  final Size? size;

  const ImageViewerScreen({
    super.key,
    required this.activeCommunity,
    required this.url,
    this.post,
    this.size
  });

  void _onSave(BuildContext context) {
    saveImage(
      context: context,
      platform: activeCommunity.platform,
      url: url,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      activeCommunity: activeCommunity,
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
                  context: context,
                  activeCommunity: activeCommunity,
                  type: 'image',
                  url: url,
                  onSave: _onSave
                )
              );
            },
            child: CustomInteractiveViewer(
              child: ExtendedImage.network(
                url,
                headers: {'User-Agent': activeCommunity.platform.savedOrDefaultUserAgent},
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