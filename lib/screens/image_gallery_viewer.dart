import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/widgets/media_error.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';

class ImageGalleryViewerScreen extends StatefulWidget {

  final String url;
  final Platform platform;
  final Community? community;
  final Post? post;

  const ImageGalleryViewerScreen({
    super.key,
    required this.url,
    required this.platform,
    this.community,
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
    final postDetails = await Api.of(widget.platform).getPostDetailsFromUrl(widget.url);
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
      community: widget.community,
      post: widget.post,
      body: _isLoading
        ? const LargeCircularProgressIndicator()
        : ListView.builder(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          cacheExtent: 1000,
          itemCount: 1 + _post.galleryImageUrls.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_post.title),
                    Text(
                      'by ${_post.author ?? '[deleted]'} • ${_post.timeAgo}',
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
                Image.network(
                  url,
                  headers: Constants.userAgentHeader,
                  width: double.infinity, 
                  fit: BoxFit.fitWidth,
                  cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt(),
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    return loadingProgress == null ? child : const Padding(
                      padding: EdgeInsets.all(16),
                      child: LargeCircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const MediaError(),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              return ImageViewerScreen(
                                url: widget.url,
                                community: widget.community,
                                post: widget.post,
                              );
                            }
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