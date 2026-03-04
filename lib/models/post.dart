import 'dart:ui';

import 'package:lurk/core/extensions.dart';
import 'package:lurk/models/community.dart';

class Post {

  final Community community;
  final String localId;
  final String localHost;
  final String shortLocalId;
  final String globalId;
  final String localUrlPath;
  final String? authorId;
  final String? authorHost;
  final String? authorName;
  final ContentType? contentType;
  final int score;
  final int timestampMs;
  final String title;
  final String? body;
  final String? bodyHtml;
  final int commentCount;
  final String? linkUrl;
  final String linkDomain;
  final String? thumbnailUrl;
  final Size? mediaSize;
  final List<GalleryImage>? galleryImages;
  final bool isRemoved;
  final bool isStickied;
  final bool isNsfw;
  final bool? vote;

  Post({
    required this.community,
    required this.localId,
    required this.localHost,
    required this.shortLocalId,
    required this.globalId,
    required this.localUrlPath,
    required this.authorId,
    required this.authorHost,
    required this.authorName,
    required this.contentType,
    required this.score,
    required this.timestampMs,
    required this.title,
    required this.body,
    required this.bodyHtml,
    required this.commentCount,
    required this.linkUrl,
    required this.linkDomain,
    required this.thumbnailUrl,
    required this.mediaSize,
    required this.galleryImages,
    required this.isRemoved,
    required this.isStickied,
    required this.isNsfw,
    required this.vote,
  });

  String get timeAgoCompact => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoCompact;

  String get timeAgoLong => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoLong;

  String get commentsLabel => commentCount == 1 ? '1 comment' : '${commentCount.toCommaString()} comments';

}

enum ContentType {
  local,
  image,
  video,
  imageGallery,
}

class GalleryImage {

  final String url;
  final Size size;

  const GalleryImage({
    required this.url,
    required this.size,
  });

}