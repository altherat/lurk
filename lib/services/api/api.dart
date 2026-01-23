import 'package:flutter/foundation.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/paged_result.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/api/digg.dart';
import 'package:lurk/services/api/reddit.dart';
import 'package:lurk/services/settings.dart';

final _platformApis = {
  Platform.reddit: () => RedditApi(),
  Platform.digg: () => DiggApi()
};

abstract class Api {

  static final Map<Platform, Api> _apis = {};

  static Api of(Platform platform) => _apis.putIfAbsent(platform, _platformApis[platform]!);

  String getPostDetailsUrl(Post post);
  String getCommentUrl(Post post, Comment comment);

  Future<PagedResult<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options});
  Future<PostDetails> getPostDetailsFromId(String id, {Map<FeedOptionType, FeedOption>? options});
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? level, Map<FeedOptionType, FeedOption>? options});
  Future<PagedResult<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});

  @protected
  Map<String, String> getHeaders(Map<String, dynamic> headers) {
    return {
      'User-Agent': Settings.userAgent.value,
      ...headers
    };
  }

}
