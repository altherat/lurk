import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/settings.dart';

abstract class Api {

  const Api();

  String get savedOrDefaultUserAgent => Settings.customUserAgent.value ?? defaultUnauthenticatedUserAgent;

  @protected
  String get defaultUnauthenticatedUserAgent;

  @protected
  String get baseUrl;

  bool get hasLogin;

  String getPostDetailsUrl(Post post) => '$baseUrl${post.permalink}';

  String getCommentUrl(Comment comment) => '$baseUrl${comment.permalink}';

  Future<String?> resolveUrl(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = false; 
      request.headers.set('User-Agent', savedOrDefaultUserAgent);
      final response = await request.close();
      if (response.statusCode == 301) {
        return response.headers.value('location');
      }
    }
    catch (e) {
      dev.log('Error resolving url: $url');
    }
    finally {
      client.close();
    }
    return null;
  }

  Future<PagedItems<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options});
  Future<PostDetails> getPostDetailsFromId(String id, {String? shortCommentId, Map<FeedOptionType, FeedOption>? options});
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options});
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options});
  Future<PagedItems<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});
  Future<PagedItems<dynamic>> search(String query, String? communityName, {Map<FeedOptionType, FeedOption>? options, String? pageToken});

  Future<String?> login();
  Future<void> logout(String id);
  Future<LoggedInUser> getLoggedInUser();
  Future<List<String>> getSubscribedCommunityNames();
  Future<void> vote(String id, bool? up);
  Future<Comment> postComment(String id, String text);
  Future<void> deleteComment(String id);
  Future<void> unsubscribe(String communityName);

}

class MultiPartFeedResponse<T, U> {

  final Future<PagedItems<T>> items;
  final Future<U>? other;

  const MultiPartFeedResponse({
    required this.items,
    this.other
  });

}
