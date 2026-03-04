

import 'dart:ui';

import 'package:lurk/core/extensions.dart';
import 'package:lurk/models/community.dart';

abstract class CommentItem {

  final int depth;

  const CommentItem({
    required this.depth
  });
  
}

class Comment extends CommentItem {
  
  final Community community;
  final String localId;
  final String? shortLocalId;
  final String urlPath;
  final String? authorId;
  final String? authorName;
  final String? authorHost;
  final bool isDeleted;
  final bool isModerator;
  final bool isSubmitter;
  final int? score;
  final int timestampMs;
  final String? text;
  final String? textHtml;
  final Map<String, Size>? imageSizes;
  final bool? vote;

  final String? postTitle;
  final String? postId;

  const Comment({
    required super.depth,
    required this.community,
    required this.localId,
    required this.shortLocalId,
    required this.urlPath,
    required this.authorId,
    required this.authorName,
    required this.authorHost,
    required this.isDeleted,
    required this.isModerator,
    required this.isSubmitter,
    required this.score,
    required this.timestampMs,
    required this.text,
    required this.textHtml, 
    required this.imageSizes,
    required this.vote,
    this.postTitle,
    this.postId,
  });

  Comment copyWith({
    int? depth,
    Community? community,
    String? localId,
    String? shortLocalId,
    String? urlPath,
    String? authorId,
    String? authorName,
    String? authorHost,
    bool? isDeleted,
    bool? isModerator,
    bool? isSubmitter,
    int? score,
    int? timestampMs,
    String? text,
    String? textHtml,
    Map<String, Size>? imageSizes,
    bool? vote,
    String? postTitle,
    String? postId,
    String? communityName,
  }) {
    return Comment(
      depth: depth ?? this.depth,
      community: community ?? this.community,
      localId: localId ?? this.localId,
      shortLocalId: shortLocalId ?? this.shortLocalId,
      urlPath: urlPath ?? this.urlPath,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorHost: authorHost ?? this.authorHost,
      isDeleted: isDeleted ?? this.isDeleted,
      isModerator: isModerator ?? this.isModerator,
      isSubmitter: isSubmitter ?? this.isSubmitter,
      score: score ?? this.score,
      timestampMs: timestampMs ?? this.timestampMs,
      text: text ?? this.text,
      textHtml: textHtml ?? this.textHtml,
      imageSizes: imageSizes ?? this.imageSizes,
      vote: vote ?? this.vote,
      postTitle: postTitle ?? this.postTitle,
      postId: postId ?? this.postId,
    );
  }

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