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

  final Platform platform;
  final Api _api;
  final String? _userId;
  final ClientHelper _clientHelper;

  ApiService(
    this.platform,
    String host,
    this._api,
    this._userId
  ) : _clientHelper = _api.getClientHelper(host, _userId);

  bool get isValid => _clientHelper.isValid;

  void dispose() => _clientHelper.dispose();

  Future<LoggedInUser?> login() async {
    if (_clientHelper is AuthClientHelper && await _clientHelper.fetchToken()) {
      final user = await fetchLoggedInUser();
      await _clientHelper.saveToken(user.id);
      return user;
    }
    return null;
  }

  Future<CommunityDetails> fetchCommunityDetails(String name) async {
    final details = await _api.getCommunityDetails(_clientHelper, name);
    if (_userId != null && details.isSubscribed != null) {
      Communities.updateSubscribedCommunity(platform, _userId, name, details.isSubscribed!);
    }
    return details;
  }

  Future<PagedItems<Post>> fetchCommunityPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final pagedItems = await _api.getCommunityPosts(_clientHelper, id, options: options, pageToken: pageToken);
    Communities.saved.updateAll((savedCommunities) {
      bool changed = false;
      final savedCommunitiesIndexes = {
        for (int i = 0; i < savedCommunities.length; i++) 
          savedCommunities[i]: i
      };
      for (final post in pagedItems.items) {
        final index = savedCommunitiesIndexes[post.community];
        if (index != null) {
          final savedCommunity = savedCommunities[index];
          if (savedCommunity.id != post.community.id) {
            savedCommunities[index] = savedCommunity.copyWith(id: post.community.id);
            changed = true;
          }
        } 
      }
      return changed;
    });
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

  Future<List<Community>> fetchSubscribedCommunities() async {
    final communities = await _api.getSubscribedCommunities(_clientHelper);
    Communities.saved.updateAll((savedCommunities) {
      final savedCommunitiesIndexes = {
        for (int i = 0; i < savedCommunities.length; i++) 
          savedCommunities[i]: i
      };
      bool changed = false;
      for (final community in communities) {
        final index = savedCommunitiesIndexes[community];
        if (index != null) {
          final savedCommunity = savedCommunities[index];
          if (savedCommunity.id != community.id) {
            savedCommunities[index] = savedCommunity.copyWith(id: community.id);
            changed = true;
          }
        }
        else {
          savedCommunities.add(community);
          changed = true;
        }
      }
      return changed;
    });
    Communities.addAllSubscribedCommunities(platform, _userId!, communities);
    return communities;
  }

  Future<void> subscribeToCommunity(String communityName, String communityId) async {
    Communities.addSubscribedCommunity(platform, _userId!, communityName);
    return _api.subscribeToCommunity(_clientHelper, communityId);
  }

  Future<void> unsubscribeFromCommunity(String communityName, String communityId) async {
    Communities.removeSubscribedCommunity(platform, _userId!, communityName);
    return _api.unsubscribeFromCommunity(_clientHelper, communityId);
  }

  Future<void> votePost(String postId, bool up) => _vote(Posts.interactionStates, postId, up);
  
  Future<void> voteComment(String commentId, bool up) => _vote(Comments.interactionStates, commentId, up);

  Future<Comment> postComment(String parentId, String text) => _api.postComment(_clientHelper, parentId, text);

  Future<void> deleteComment(String commentId) => _api.deleteComment(_clientHelper, commentId);

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
        Posts.interactionStates.update(_userId, item.id, InteractionState(score: item.score, vote: item.vote));
      }
      else if (item is Comment) {
        Comments.interactionStates.update(_userId, item.id, InteractionState(score: item.score, vote: item.vote));
      }
    }
  }

}