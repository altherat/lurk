

import 'package:lurk/core/utils.dart' as utils;

abstract class CommentItem {

  final int level;

  const CommentItem({required this.level});
  
}

class Comment extends CommentItem {
  
  final String id;
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
    required super.level,
    required this.id,
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

  String get timeAgo => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgo;

  String get timeAgoCompact => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoCompact;

}

class LoadMoreComment extends CommentItem {

  final int count;
  final String? pageToken;

  const LoadMoreComment({
    required super.level,
    required this.count,
    required this.pageToken
  });

}