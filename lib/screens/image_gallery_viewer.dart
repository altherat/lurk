import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:lurk/widgets/centered_large_circular_progress_indicator.dart';

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

  @override
  State<ImageGalleryViewerScreen> createState() => _ImageGalleryViewerScreenState();

}

class _ImageGalleryViewerScreenState extends State<ImageGalleryViewerScreen> {
  
  late bool _isLoading;
  late final Post _post;

  @override
  void initState() {
    super.initState();
    if (widget.post == null) {
      _isLoading = true;
      _getGallery();
    }
    else {
      _isLoading = false;
      _post = widget.post!;
    }
  }

  Future<void> _getGallery() async {
    final postDetails = await widget.platform.api.getPostDetailsFromUrl(widget.url);
    if (mounted) {
      setState(() {
        _post = postDetails.post;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      url: widget.url,
      type: 'images',
      post: widget.post,
      body: _isLoading
        ? CenteredLargeCircularProgressIndicator(platform: widget.platform)
        : ListView.separated(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            cacheExtent: MediaQuery.of(context).size.height,
            itemCount: 1 + _post.galleryImageUrls.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_post.title),
                      Text(
                        'by ${_post.author ?? '[deleted]'} • ${_post.timeAgoLong}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Constants.secondaryTextColor
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_post.galleryImageUrls.length.toPluralString('image'))
                    ],
                  ),
                );
              }
              final url = _post.galleryImageUrls[index - 1];
              return Stack(
                children: [
                  ExtendedImage.network(
                    url,
                    headers: {'User-Agent': Settings.userAgent.value},
                    fit: BoxFit.fitWidth,
                    mode: ExtendedImageMode.gesture,
                    cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt(),
                    loadStateChanged: (state) {
                      switch (state.extendedImageLoadState) {
                        case LoadState.loading:
                          return Padding(
                            padding: EdgeInsets.all(16),
                            child: CenteredLargeCircularProgressIndicator(platform: widget.platform)
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
                              url: url,
                              post: widget.post,
                            )
                          );
                        }
                      ),
                    ),
                  )
                ],
              );
            },
          )
    );
  }

}