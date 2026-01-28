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

  String get userAgent => Settings.customUserAgent.value ?? defaultUserAgent;

  @protected
  String get defaultUserAgent;

  @protected
  Map<String, String> get defaultHeaders;

  @protected
  String get baseUrl;

  String getPostDetailsUrl(Post post) => '$baseUrl${post.permalink}';

  String getCommentUrl(Comment comment) => '$baseUrl${comment.permalink}';

  Future<String?> resolveUrl(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = false; 
      request.headers.set('User-Agent', userAgent);
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      if (response.statusCode == 301) {
        return response.headers.value('location');
      }
    }
    catch (e) {
      debugPrint('Error resolving url: $url');
    }
    finally {
      client.close();
    }
    return null;
  }

  @protected
  Map<String, String> get headers {
    return {
      'User-Agent': userAgent,
      ...defaultHeaders
    };
  }

  Future<PagedResult<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options});
  Future<PostDetails> getPostDetailsFromId(String id, {String? commentId, Map<FeedOptionType, FeedOption>? options});
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options});
  UserDetailsResponse getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options});
  Future<PagedResult<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});
  Future<PagedResult<dynamic>> search(String query, {Map<FeedOptionType, FeedOption>? options, String? pageToken});

  Future<void> vote(String id, bool? up);

}

class PagedResult<T> {

  final List<T> items;
  final String? pageToken;

  PagedResult({
    required this.items,
    this.pageToken,
  });
  
}

abstract class FeedResponse<T> {

  final Future<PagedResult<T>> items;

  const FeedResponse({required this.items});

}

class UserDetailsResponse extends FeedResponse {

  final Future<List<UserStat>> stats;

  const UserDetailsResponse({
    required this.stats,
    required super.items
  });

}
