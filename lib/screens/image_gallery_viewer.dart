import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/media_scaffold.dart';

class ImageGalleryViewerScreen extends StatefulWidget {

  final Platform platform;
  final String url;
  final Post? post;

  const ImageGalleryViewerScreen({
    super.key,
    required this.platform,
    required this.url,
    this.post
  });

  factory ImageGalleryViewerScreen.fromPost({
    Key? key,
    required Post post
  }) {
    return ImageGalleryViewerScreen(
      key: key,
      platform: post.community.platform,
      url: post.url,
      post: post,
    );
  }

  factory ImageGalleryViewerScreen.fromUrl({
    Key? key,
    required Platform platform,
    required String url
  }) {
    return ImageGalleryViewerScreen(
      key: key,
      platform: platform,
      url: url,
    );
  }

  @override
  State<ImageGalleryViewerScreen> createState() => _ImageGalleryViewerScreenState();

}

class _ImageGalleryViewerScreenState extends State<ImageGalleryViewerScreen> {

  late bool _isLoadingPost;
  late final Post _post;

  @override
  void initState() {
    super.initState();
    if (widget.post == null) {
      _isLoadingPost = true;
      widget.platform.getApi(Uri.parse(widget.url).host, Settings.activeUser.value?.id).fetchPostDetailsFromUrl(widget.url).then((postDetails) {
        if (mounted) {
          setState(() {
            _post = postDetails.post!;
            _isLoadingPost = false;
          });
        }
      });
    }
    else {
      _isLoadingPost = false;
      _post = widget.post!;
    }
  }
  @override
  Widget build(BuildContext context) {
    final void Function(BuildContext context)? onSave;
    final Widget body;
    if (_isLoadingPost) {
      onSave = null;
      body = const LargeCenteredCircularProgressIndicator();
    }
    else {
      onSave = (context) {
        final count = _post.galleryImages.length;
        saveMedia(
          context: context,
          platform: widget.platform,
          snackbarMediaTypeMessage: '$count images',
          save: () async {
            for (final image in _post.galleryImages) {
              final filePath = await downloadMediaToTemp(image.url, widget.platform.savedOrDefaultUserAgent);
              await Gal.putImage(filePath);
            }
          },
        );
      };
      body = ListView.separated(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        cacheExtent: MediaQuery.of(context).size.height,
        itemCount: 1 + _post.galleryImages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(13, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_post.title),
                  Text(
                    'by ${_post.author ?? '[deleted]'}${Constants.separator}${_post.timeAgoLong}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_post.galleryImages.length.toPluralString('image'))
                ],
              ),
            );
          }
          final image = _post.galleryImages[index - 1];
          return Hero(
            tag: 'media_${image.url}',
            child: Stack(
              children: [
                ExtendedImage.network(
                  image.url,
                  headers: {'User-Agent': widget.platform.savedOrDefaultUserAgent},
                  fit: BoxFit.fitWidth,
                  mode: ExtendedImageMode.gesture,
                  cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt(),
                  loadStateChanged: (state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                        return Container(
                          decoration: BoxDecoration(border: Border.all(color: Constants.lighterBackgroundColor)),
                          alignment: Alignment.topCenter,
                          child: AspectRatio(
                            aspectRatio: image.size.width / image.size.height,
                            child: const LargeCenteredCircularProgressIndicator(),
                          ),
                        );
                      case LoadState.completed:
                        return state.completedWidget;
                      case LoadState.failed:
                        final color = Theme.of(context).disabledColor;
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 80,
                                color: color
                              )
                            ],
                          ),
                      );
                    }
                  },
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.push(
                          () => ImageViewerScreen(
                            platform: widget.platform,
                            url: image.url,
                            post: widget.post,
                          )
                        );
                      },
                      onLongPress: () {
                        showSimpleOptionsBottomSheet(
                          context: context,
                          options: MediaScaffold.getOptions(
                            context: context,
                            type: 'image',
                            url: image.url,
                            onSave: onSave
                          )
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
          );
        },
      );
    }
    return MediaScaffold(
      platform: widget.platform,
      url: widget.url,
      type: 'images',
      post: widget.post,
      onSave: onSave,
      body: body
    );
  }

}