

import 'dart:ui';

import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart' as utils;

abstract class CommentItem {

  final Platform platform;
  final int depth;

  const CommentItem({
    required this.platform,
    required this.depth
  });
  
}

class Comment extends CommentItem {
  
  final String id;
  final String shortId;
  final String permalink;
  final bool isDeleted;
  final String? authorId;
  final String? authorName;
  final bool isModerator;
  final bool isSubmitter;
  final int? score;
  final int timestampMs;
  final String? text;
  final String? textHtml;
  final Map<String, Size> images;
  final bool? vote;

  final String? postTitle;
  final String? communityName;

  const Comment({
    required super.platform,
    required super.depth,
    required this.id,
    required this.shortId,
    required this.permalink,
    required this.isDeleted,
    required this.authorId,
    required this.authorName,
    required this.isModerator,
    required this.isSubmitter,
    required this.score,
    required this.timestampMs,
    required this.text,
    required this.textHtml, 
    required this.images,
    required this.vote,
    this.postTitle,
    this.communityName,
  });

  Comment copyWith({
    Platform? platform,
    int? depth,
    String? id,
    String? shortId,
    String? permalink,
    bool? isDeleted,
    String? authorId,
    String? authorName,
    bool? isModerator,
    bool? isSubmitter,
    int? score,
    int? timestampMs,
    String? text,
    String? textHtml,
    Map<String, Size>? images,
    bool? vote,
    String? postTitle,
    String? communityName,
  }) {
    return Comment(
      platform: platform ?? this.platform,
      depth: depth ?? this.depth,
      id: id ?? this.id,
      shortId: shortId ?? this.shortId,
      permalink: permalink ?? this.permalink,
      isDeleted: isDeleted ?? this.isDeleted,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isModerator: isModerator ?? this.isModerator,
      isSubmitter: isSubmitter ?? this.isSubmitter,
      score: score ?? this.score,
      timestampMs: timestampMs ?? this.timestampMs,
      text: text ?? this.text,
      textHtml: textHtml ?? this.textHtml,
      images: images ?? this.images,
      vote: vote ?? this.vote,
      postTitle: postTitle ?? this.postTitle,
      communityName: communityName ?? this.communityName,
    );
  }

  String get timeAgoCompact => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoCompact;

  String get timeAgoLong => DateTime.fromMillisecondsSinceEpoch(timestampMs).timeAgoLong;

}

class LoadMoreComment extends CommentItem {

  final int count;
  final String? pageToken;

  const LoadMoreComment({
    required super.platform,
    required super.depth,
    required this.count,
    required this.pageToken
  });

}