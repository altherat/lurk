import 'package:lurk/core/utils.dart';
import 'package:lurk/core/utils.dart' as utils;
import 'package:lurk/models/community.dart';

class Post {

  final Community community;
  final String id;
  final String shortId;
  final String permalink;
  final int score;
  final int timestampMs;
  final String title;
  final String? textHtml;
  final String? author;
  final int commentCount;
  final String url;
  final String domain;
  final String? thumbnailUrl;
  final bool isDeleted;
  final bool isStickied;
  final bool isSelf;
  final bool isNsfw;
  final bool isGallery;
  final List<String> galleryImageUrls;

  Post({
    required this.community,
    required this.id,
    String? shortId,
    required this.permalink,
    required this.score,
    required this.timestampMs,
    required this.title,
    required this.textHtml,
    required this.author,
    required this.commentCount,
    required this.url,
    required this.domain,
    this.thumbnailUrl,
    this.isStickied = false,
    required this.isDeleted,
    required this.isSelf,
    required this.isNsfw,
    required this.isGallery,
    this.galleryImageUrls = const [],
  }) : shortId = shortId ?? id;

  String get compactScore {
    if (score < 1000) {
      return score.toString();
    }
    final double reduced = score / 1000;
    String formatted = reduced.toStringAsFixed(1);
    if (reduced >= 9.95) {
      formatted = reduced.toStringAsFixed(0);
    }
    return '${formatted.replaceAll(RegExp(r'\.0$'), '')}K';
  }

  String get timeAgoCompact => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoCompact;

  String get timeAgoLong => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoLong;

  String get commentsLabel => commentCount == 1 ? '1 comment' : '${commentCount.toCommaString()} comments';

}