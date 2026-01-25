

import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart' as utils;

abstract class CommentItem {

  final int depth;

  const CommentItem({
    required this.depth
  });
  
}

class Comment extends CommentItem {
  
  final Platform platform;
  final String id;
  final String permalink;
  final bool isDeleted;
  final String? author;
  final bool isModerator;
  final bool isSubmitter;
  final int? score;
  final int timestampMs;
  final String? text;
  final String? textHtml;

  final String? postTitle;
  final String? communityName;

  const Comment({
    required super.depth,
    required this.platform,
    required this.id,
    required this.permalink,
    required this.isDeleted,
    required this.author,
    required this.isModerator,
    required this.isSubmitter,
    required this.score,
    required this.timestampMs,
    required this.text,
    required this.textHtml,
    this.postTitle,
    this.communityName,
  });

  String get timeAgoCompact => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoCompact;

  String get timeAgoLong => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoLong;

}

class LoadMoreComment extends CommentItem {

  final int count;
  final String? pageToken;

  const LoadMoreComment({
    required super.depth,
    required this.count,
    required this.pageToken
  });

}