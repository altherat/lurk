import 'package:lurk/core/collection_listenable/interaction_state.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/interaction_state.dart';
import 'package:lurk/models/login.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/comments.dart';
import 'package:lurk/services/communities.dart';
import 'package:lurk/services/posts.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/client_helpers.dart';

class ApiService {

  final Platform platform;
  final String _host;
  final Api _api;
  final String? _userId;
  final ClientHelper _clientHelper;

  ApiService(
    this.platform,
    this._host,
    this._api,
    this._userId
  ) : _clientHelper = _api.getClientHelper(_host, _userId);

  bool get isValid => _clientHelper.isValid;

  void dispose() => _clientHelper.dispose();

  Future<LoginResult> login([Map<String, String>? credentials]) async {
    try {
      if (_clientHelper is! AuthClientHelper) {
        return LoginError();
      }
      final result = await _clientHelper.fetchToken(credentials);
      if (result is FetchTokenError) {
        return LoginError(result.message);
      }
      final user = await fetchLoggedInUser();
      await _clientHelper.saveToken(user.id);
      return LoginSuccess(user);
    }
    catch (e) {
      return LoginError();
    }
  }

  Future<CommunityDetails> fetchCommunityDetails(String name) async {
    final details = await _api.getCommunityDetails(_clientHelper, name);
    if (_userId != null && details.isSubscribed != null) {
      if (details.isSubscribed!) {
        Communities.addSubscribedCommunity(platform, _host, _userId, name);
      }
      else {
        Communities.removeSubscribedCommunity(platform, _host, _userId, name);
      }
    }
    return details;
  }

  Future<PagedItems<Post>> fetchCommunityPosts(String? id, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
    final pagedItems = await _api.getCommunityPosts(_clientHelper, id, pageToken, options);
    Communities.saved.updateAll((savedCommunities) {
      bool changed = false;
      final savedCommunitiesIndexes = {
        for (int i = 0; i < savedCommunities.length; i++) 
          (savedCommunities[i].host, savedCommunities[i].name): i
      };
      for (final post in pagedItems.items) {
        final index = savedCommunitiesIndexes[(post.community.host, post.community.name)];
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

  Future<Post> fetchPost(String id) async {
    final post = await _api.getPost(_clientHelper, id);
    _updateDynamicInteractionStates([post]);
    return post;
  }

  Future<(List<CommentItem>, Post)> fetchCommentsAndPost(String id, String? communityName, String? contextCommentShortId, Map<FeedOptionType, FeedOption>? options) async {
    final commentsAndPost = await _api.getCommentsAndPost(_clientHelper, id, communityName, contextCommentShortId, options);
    _updateDynamicInteractionStates([commentsAndPost.$2, ...commentsAndPost.$1]);
    return commentsAndPost;
  }

  Future<(List<CommentItem>, Post?)> fetchCommentsAndMaybePost(String id, String? communityName, String? contextCommentShortId, Map<FeedOptionType, FeedOption>? options) async {
    final commentsAndMaybePost = await _api.getCommentsAndMaybePost(_clientHelper, id, communityName, contextCommentShortId, options);
    _updateDynamicInteractionStates([commentsAndMaybePost.$2, ...commentsAndMaybePost.$1]);
    return commentsAndMaybePost;
  }

  Future<List<CommentItem>> fetchMoreComments(String id, int? depth, String pageToken, Map<FeedOptionType, FeedOption>? options) async {
    final comments = await _api.getMoreComments(_clientHelper, id, depth, pageToken, options);
    _updateDynamicInteractionStates(comments);
    return comments;
  }

  MultiPartFeedResponse<dynamic, List<UserStat>> fetchUserDetails(String id, Map<FeedOptionType, FeedOption>? options) {
    final result = _api.getUserDetails(_clientHelper, id, options);
    result.items.then((pagedItems) => _updateDynamicInteractionStates(pagedItems.items));
    return result;
  }

  Future<PagedItems<dynamic>> fetchUserItems(String id, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
    final pagedItems = await _api.getUserItems(_clientHelper, id, pageToken, options);
    _updateDynamicInteractionStates(pagedItems.items);
    return pagedItems;
  }

  Future<PagedItems<dynamic>> fetchSearchResults(String query, String? communityName, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
    final pagedItems = await _api.getSearchResults(_clientHelper, query, communityName, pageToken, options);
    _updateDynamicInteractionStates(pagedItems.items);
    return pagedItems;
  }

  Future<Post> resolveGlobalToLocalPost(String globalId) => _api.resolveGlobalToLocalPost(_clientHelper, globalId);

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
    Communities.addAllSubscribedCommunities(platform, _host, _userId!, communities);
    return communities;
  }

  Future<void> subscribeToCommunity(String communityId) {
    Communities.addSubscribedCommunity(platform, _host, _userId!, communityId);
    return _api.subscribeToCommunity(_clientHelper, communityId);
  }

  Future<void> unsubscribeFromCommunity(String communityId) {
    Communities.removeSubscribedCommunity(platform, _host, _userId!, communityId);
    return _api.unsubscribeFromCommunity(_clientHelper, communityId);
  }

  Future<void> votePost(String postId, bool up) => _api.votePost(_clientHelper, postId, _updateVoteInteractionState(Posts.interactionStates, postId, up));
  
  Future<void> voteComment(String commentId, bool up) => _api.voteComment(_clientHelper, commentId, _updateVoteInteractionState(Comments.interactionStates, commentId, up));

  Future<Comment> postComment(String parentId, String text) => _api.postComment(_clientHelper, parentId, text);

  Future<void> deleteComment(String commentId) => _api.deleteComment(_clientHelper, commentId);

  bool? _updateVoteInteractionState(InteractionStateCollectionListenable listenable, String id, bool up) {
    final vote = up == listenable.value((_userId!, id))?.vote ? null : up;
    listenable.updateVote(_userId, id, vote);
    return vote;
  }

  void _updateDynamicInteractionStates(List<dynamic> items) {
    if (_userId == null) {
      return;
    }
    for (final item in items) {
      if (item is Post) {
        Posts.interactionStates.update(_userId, item.localId, InteractionState(score: item.score, vote: item.vote));
      }
      else if (item is Comment) {
        Comments.interactionStates.update(_userId, item.localId, InteractionState(score: item.score, vote: item.vote));
      }
    }
  }

}