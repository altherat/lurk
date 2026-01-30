import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/settings.dart';

abstract class Api {

  const Api();

  String get savedOrDefaultUserAgent => Settings.customUserAgent.value ?? defaultUserAgent;

  @protected
  String get defaultUserAgent;

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

  Future<PagedResult<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options});
  Future<PostDetails> getPostDetailsFromId(String id, {String? commentId, Map<FeedOptionType, FeedOption>? options});
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options});
  FeedResponse<dynamic, List<UserStat>> getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options});
  Future<PagedResult<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});
  Future<PagedResult<dynamic>> search(String query, {Map<FeedOptionType, FeedOption>? options, String? pageToken});

  Future<String?> login();
  Future<String> logout();
  Future<LoggedInUser> getLoggedInUser();
  Future<List<String>> getSubscribedCommunityNames();
  Future<void> vote(String id, bool? up);
  Future<void> postComment(String id, String text);
  Future<void> deleteComment(String id);

}

class PagedResult<T> {

  final List<T> items;
  final String? pageToken;

  PagedResult({
    required this.items,
    this.pageToken,
  });
  
}

class FeedResponse<T, U> {

  final Future<PagedResult<T>> items;
  final Future<U>? other;

  const FeedResponse({
    required this.items,
    this.other
  });

}

class UserDetailsResponse extends FeedResponse {

  final Future<List<UserStat>> stats;

  const UserDetailsResponse({
    required this.stats,
    required super.items
  });

}
