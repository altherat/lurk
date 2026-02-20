import 'package:flutter/foundation.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/login.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/client_helpers.dart';

abstract class Api<T extends ClientHelper> {
  
  const Api();

  String get savedOrDefaultUserAgent => savedUserAgent ?? defaultUnauthenticatedUserAgent;

  List<LoginField>? get loginFields => null;

  @protected
  String get defaultUnauthenticatedUserAgent;

  @protected
  String? get savedUserAgent;

  String getBaseUrl(String host);

  ClientHelper getClientHelper(String host, String? userId);

  String getPostDetailsUrl(Post post) => '${getBaseUrl(post.community.host)}${post.permalink}';

  String getCommentUrl(Comment comment) => '${getBaseUrl(comment.community.host)}${comment.permalink}';

  Future<CommunityDetails> getCommunityDetails(T clientHelper, String name);

  Future<PagedItems<Post>> getCommunityPosts(T clientHelper, String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});

  Future<PostDetails> getPostDetailsFromUrl(T clientHelper, String url, {Map<FeedOptionType, FeedOption>? options});

  Future<PostDetails> getPostDetailsFromId(T clientHelper, String id, {String? shortCommentId, Map<FeedOptionType, FeedOption>? options});

  Future<List<CommentItem>> getMoreComments(T clientHelper, String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options});

  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(T clientHelper, String id, {Map<FeedOptionType, FeedOption>? options});

  Future<PagedItems<dynamic>> getUserItems(T clientHelper, String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken});

  Future<PagedItems<dynamic>> getSearchResults(T clientHelper, String query, String? communityName, {Map<FeedOptionType, FeedOption>? options, String? pageToken});

  Future<LoggedInUser> getLoggedInUser(T clientHelper);

  Future<List<Community>> getSubscribedCommunities(T clientHelper);

  Future<void> subscribeToCommunity(T clientHelper, String communityId);

  Future<void> unsubscribeFromCommunity(T clientHelper, String communityId);

  Future<void> votePost(T clientHelper, String commentId, bool? vote);

  Future<void> voteComment(T clientHelper, String commentId, bool? vote);

  Future<Comment> postComment(T clientHelper, String parentId, String text);

  Future<void> deleteComment(T clientHelper, String commentId);

}

class MultiPartFeedResponse<T, U> {

  final Future<PagedItems<T>> items;
  final Future<U>? other;

  const MultiPartFeedResponse({
    required this.items,
    this.other
  });

}