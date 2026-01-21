import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/widgets/media_error.dart';
import 'package:lurk/widgets/media_scaffold.dart';
import 'package:lurk/widgets/large_circular_progress_indicator.dart';
import 'package:lurk/widgets/one_finger_zoom.dart';

class ImageViewerScreen extends StatefulWidget {

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
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaScaffold(
      url: widget.url,
      type: 'image',
      community: widget.community,
      post: widget.post,
      body: OneFingerZoomGestureRecognizer(
        transformationController: _transformationController,
        child: InteractiveViewer(
          transformationController: _transformationController,
          child: Align(
            alignment: AlignmentGeometry.topCenter,
            child: Image.network(
              widget.url,
              headers: Constants.userAgentHeader,
              width: double.infinity, 
              fit: BoxFit.fitWidth,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                return loadingProgress == null ? child : const LargeCircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) => const MediaError()
            ),
          ),
        ),
      )
    );
  }
  
}