import 'package:http/http.dart';
import 'package:lurk/core/collection_listenable/interaction_state.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/interaction_state.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/repositories/comments.dart';
import 'package:lurk/repositories/communities.dart';
import 'package:lurk/repositories/posts.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/client_helpers.dart';

class ApiService {

  final Api _api;
  final String? _userId;
  final ClientHelper _clientHelper;

  ApiService(
    this._api, 
    this._userId
  ) : _clientHelper = _api.getClientHelper(_userId);

  bool get isValid => _clientHelper.isValid;

  void dispose() => _clientHelper.dispose();

  Future<CommunityDetails> fetchCommunityDetails(String name) async {
    final details = await _api.getCommunityDetails(_clientHelper, name);
    if (_userId != null && details.isSubscribed != null) {
      Communities.updateSubscribedCommunity(_api.platform, _userId, name, details.isSubscribed!);
    }
    return details;
  }

  Future<PagedItems<Post>> fetchCommunityPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final pagedItems = await _api.getCommunityPosts(_clientHelper, id, options: options, pageToken: pageToken);
    Communities.saved.updateAll(pagedItems.items.map((post) => post.community).toSet());
    _updateDynamicInteractionStates(pagedItems.items);
    return pagedItems;
  }

  Future<PostDetails> fetchPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options}) async {
    final details = await _api.getPostDetailsFromUrl(_clientHelper, url, options: options);
    _updateDynamicInteractionStates([details.post, ...details.comments]);
    return details;
  }

  Future<PostDetails> fetchPostDetailsFromId(String id, {String? shortCommentId, Map<FeedOptionType, FeedOption>? options}) async {
    final details = await _api.getPostDetailsFromId(_clientHelper,id, shortCommentId: shortCommentId, options: options);
    _updateDynamicInteractionStates([details.post, ...details.comments]);
    return details;
  }

  Future<List<CommentItem>> fetchMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) async {
    final comments = await _api.getMoreComments(_clientHelper, id, pageToken, depth: depth, options: options);
    _updateDynamicInteractionStates(comments);
    return comments;
  }

  MultiPartFeedResponse<dynamic, List<UserStat>> fetchUserDetails(String id, {Map<FeedOptionType, FeedOption>? options}) {
    final result = _api.getUserDetails(_clientHelper, id, options: options);
    result.items.then((pagedItems) => _updateDynamicInteractionStates(pagedItems.items));
    return result;
  }

  Future<PagedItems<dynamic>> fetchUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final pagedItems = await _api.getUserItems(_clientHelper, id, options: options, pageToken: pageToken);
    _updateDynamicInteractionStates(pagedItems.items);
    return pagedItems;
  }

  Future<PagedItems<dynamic>> fetchSearchResults(String query, String? communityName, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final pagedItems = await _api.getSearchResults(_clientHelper, query, communityName, options: options, pageToken: pageToken);
    _updateDynamicInteractionStates(pagedItems.items);
    return pagedItems;
  }

  Future<LoggedInUser> fetchLoggedInUser() => _api.getLoggedInUser(_clientHelper);

  Future<LoggedInUser?> login() async {
    if (_clientHelper is AuthClientHelper && await _clientHelper.fetchToken()) {
      final user = await fetchLoggedInUser();
      await _clientHelper.saveToken(user.id);
      return user;
    }
    return null;
  }

  Future<void> votePost(String postId, bool up) => _vote(Posts.interactionStates, postId, up);
  
  Future<void> voteComment(String commentId, bool up) => _vote(Comments.interactionStates, commentId, up);

  Future<Comment> postComment(String parentId, String text) => _api.postComment(_clientHelper, parentId, text);

  Future<void> deleteComment(String commentId) => _api.deleteComment(_clientHelper, commentId);

  Future<List<Community>> fetchSubscribedCommunities() async {
    final communities = await _api.getSubscribedCommunities(_clientHelper);
    Communities.saved.addOrUpdateAll(communities);
    Communities.addAllSubscribedCommunities(_api.platform, _userId!, communities);
    return communities;
  }

  Future<void> subscribeToCommunity(String communityName, String communityId) async {
    Communities.addSubscribedCommunity(_api.platform, _userId!, communityName);
    return _api.subscribeToCommunity(_clientHelper, communityId);
  }

  Future<void> unsubscribeFromCommunity(String communityName, String communityId) async {
    Communities.removeSubscribedCommunity(_api.platform, _userId!, communityName);
    return _api.unsubscribeFromCommunity(_clientHelper, communityId);
  }

  Future<void> _vote(InteractionStateCollectionListenable listenable, String id, bool up) {
    final vote = up == listenable.value((_userId!, id))?.vote ? null : up;
    listenable.updateVote(_userId, id, vote);
    return _api.votePost(_clientHelper, id, vote);
  }

  void _updateDynamicInteractionStates(List<dynamic> items) {
    if (_userId == null) {
      return;
    }
    for (final item in items) {
      if (item is Post) {
        Posts.interactionStates.set(_userId, item.id, InteractionState(score: item.score, vote: item.vote));
      }
      else if (item is Comment) {
        Comments.interactionStates.set(_userId, item.id, InteractionState(score: item.score, vote: item.vote));
      }
    }
  }

}