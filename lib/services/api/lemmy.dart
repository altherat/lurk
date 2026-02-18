import 'dart:convert';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:ui';

import 'package:lurk/core/constants.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/client_helpers.dart';
import 'package:lurk/services/settings.dart';
import 'package:markdown/markdown.dart' as md;

class LemmyApi extends Api<RestClientHelper> {

  static const _basePath = '/api/v3';
  static const _resultsLimit = 25;
  static const _commentsMaxDepth = 8;
  static const _defaultHeaders = {
    'Accept': 'application/json'
  };

  const LemmyApi();

  @override
  bool get hasLogin => false;

  @override
  String get defaultUnauthenticatedUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:${Constants.version} (by u/altherat)';

  @override
  String? get savedUserAgent => Settings.lemmyUserAgent.value;
  
  @override
  String getBaseUrl(String host) => 'https://$host';

  @override
  ClientHelper getClientHelper(String? host, String? userId) => SimpleRestClientHelper(host!, {... _defaultHeaders, 'User-Agent': defaultUnauthenticatedUserAgent});

  String _markdownToHtml(String markdown) {
    return md.markdownToHtml(
      markdown.replaceAllMapped(RegExp(r':::\s*spoiler\s*(.*?)\n([\s\S]*?)\n:::'), (match) => '<details><summary>${match.group(1)!.trim()}</summary>\n\n${match.group(2)}\n\n</details>'),
      extensionSet: md.ExtensionSet.gitHubFlavored
    );
  }

  String _htmlToPlainText(String html) => html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();

  @override
  Future<CommunityDetails> getCommunityDetails(RestClientHelper clientHelper, String name) async {
    final response = await clientHelper.get(
      '$_basePath/community',
      {
        'name': name,
      },
    );

    final host = clientHelper.host;
    final body = response.body;
    return Isolate.run(() {
      final Map<String, dynamic> json = jsonDecode(body);
      final Map<String, dynamic> view = json['community_view'];
      final Map<String, dynamic> communityData = view['community'];
      final Map<String, dynamic> counts = view['counts'];
      return CommunityDetails(
        community: Community(
          platform: Platform.lemmy,
          host: host,
          name: communityData['name'],
          id: communityData['id'].toString(),
        ),
        id: communityData['id'].toString(),
        title: communityData['title'],
        createdDate: DateTime.parse(communityData['published']),
        longDescriptionHtml: _markdownToHtml(communityData['description']), 
        iconUrl: communityData['icon'],
        bannerUrl: communityData['banner'],
        subscriberCount: counts['subscribers'],
        postCount: counts['posts'],
        isSubscribed: view['subscribed'] != 'NotSubscribed',
      );
    });
  }

  @override
  Future<PagedItems<Post>> getCommunityPosts(RestClientHelper clientHelper, String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final response = await clientHelper.get(
      '$_basePath/post/list',
      {
        'sort': ?options?[FeedOptionType.sort]?.id,
        'community_name': ?id,
        'limit': _resultsLimit.toString(),
        'page_cursor': ?pageToken,
      }
    );
    final host = clientHelper.host;
    final body = response.body;
    return Isolate.run(() => _parsePosts(host, body));
  }

  @override
  Future<PostDetails> getPostDetailsFromUrl(RestClientHelper clientHelper, String url, {Map<FeedOptionType, FeedOption>? options}) {
    return getPostDetailsFromId(clientHelper, url, options: options);
  }

  @override
  Future<PostDetails> getPostDetailsFromId(RestClientHelper clientHelper, String id, {String? shortCommentId, Map<FeedOptionType, FeedOption>? options}) async {
    final response = await clientHelper.get(
      '$_basePath/comment/list',
      {
        'post_id': id,
        'type_': 'All',
        'limit': _resultsLimit.toString(),
        'max_depth': _commentsMaxDepth.toString(),
        'sort': ?options?[FeedOptionType.sort]?.id,
      }
    );
    final host = clientHelper.host;
    final body = response.body;
    return Isolate.run(() => _parsePostDetails(host, body));
  }

  @override
  Future<List<CommentItem>> getMoreComments(RestClientHelper clientHelper, String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) {
    throw UnimplementedError();
  }

  @override
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(RestClientHelper clientHelper, String id, {Map<FeedOptionType, FeedOption>? options}) {
    final Future<String> futureBody = clientHelper.get('$_basePath/user', {'username': id}).then((response) => response.body);
    return MultiPartFeedResponse(
      items: futureBody.then((body) => _parseUserItems(clientHelper.host, body, null, options?[FeedOptionType.category])),
      other: futureBody.then((body) {
        final personView = jsonDecode(body)['person_view'];
        return _parseUserStats(personView['person'], personView['counts']);
      })
    );
  }
  
  @override
  Future<PagedItems<dynamic>> getUserItems(RestClientHelper clientHelper, String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final response = await clientHelper.get(
      '$_basePath/user',
      {
        'username': id,
        'sort': ?options?[FeedOptionType.sort]?.id,
        'limit': _resultsLimit.toString(),
        'page': ?pageToken
      }
    );
    final host = clientHelper.host;
    final body = response.body;
    return Isolate.run(() => _parseUserItems(host, body, pageToken, options?[FeedOptionType.category]));
  }

  @override
  Future<PagedItems<dynamic>> getSearchResults(RestClientHelper clientHelper, String query, String? communityName, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final Map<String, dynamic> params = {
      'q': query,
      'type_': options?[FeedOptionType.category]?.id,
      'sort': options?[FeedOptionType.sort]?.id,
      'community_id': ?communityName,
      'limit': _resultsLimit.toString(),
      'page': ?pageToken
    };

    final response = await clientHelper.get('$_basePath/search', params);
    final host = clientHelper.host;
    final body = response.body;
    return Isolate.run(() {
      final Map<String, dynamic> json = jsonDecode(body);
      final List<dynamic> items = [];

      final List<dynamic>? posts = json['posts'];
      if (posts != null) {
        for (var item in posts) {
          items.add(_parsePost(host, item));
        }
      }

      final List<dynamic>? comments = json['comments'];
      if (comments != null) {
        for (var item in comments) {
          items.add(_parseComment(host, item));
        }
      }

      final List<dynamic>? communities = json['communities'];
      if (communities != null) {
        for (var item in communities) {
          final community = item['community'];
          final counts = item['counts'];
          items.add(
            CommunityDetails(
              community: Community(
                platform: Platform.lemmy,
                host: host,
                name: community['name'],
                id: community['id'].toString(),
              ),
              title: community['title'],
              iconUrl: community['icon'],
              subscriberCount: counts['subscribers'],
              postCount: counts['posts'],
            )
          );
        }
      }

      final List<dynamic>? users = json['users'];
      if (users != null) {
        for (var item in users) {
          final Map<String, dynamic> person = item['person'];
          items.add(
            LookedUpUser(
              host: host,
              id: person['id'].toString(),
              name: person['name'],
              iconUrl: person['avatar'],
              isSuspended: person['banned'],
              stats: _parseUserStats(person, item['counts'])
            )
          );
        }
      }
      
      return PagedItems(
        items: items,
        pageToken: items.length >= _resultsLimit && pageToken != null ? (int.parse(pageToken) + 1).toString() : null,
      );
    });
  }

  @override
  Future<LoggedInUser> getLoggedInUser(RestClientHelper clientHelper) {
    throw UnimplementedError();
  }

  @override
  Future<List<Community>> getSubscribedCommunities(RestClientHelper clientHelper) {
    throw UnimplementedError();
  }

  @override
  Future<void> subscribeToCommunity(RestClientHelper clientHelper, String communityId) {
    throw UnimplementedError();
  }

  @override
  Future<void> unsubscribeFromCommunity(RestClientHelper clientHelper, String communityId) {
    throw UnimplementedError();
  }

  @override
  Future<void> voteComment(RestClientHelper clientHelper, String commentId, bool? vote) {
    throw UnimplementedError();
  }

  @override
  Future<void> votePost(RestClientHelper clientHelper, String commentId, bool? vote) {
    throw UnimplementedError();
  }

  @override
  Future<Comment> postComment(RestClientHelper clientHelper, String parentId, String text) {
    throw UnimplementedError();
  }

  @override 
  Future<void> deleteComment(RestClientHelper clientHelper, String commentId) {
    throw UnimplementedError();
  }

  PagedItems<Post> _parsePosts(String host, String body) {
    final Map<String, dynamic> json = jsonDecode(body);
    return PagedItems(
      items: (json['posts'] as List<dynamic>).map((item) => _parsePost(host, item)).toList(),
      pageToken: json['next_page'],
    );
  }

  Post _parsePost(String host, Map<String, dynamic> json) {
    final Map<String, dynamic> postData = json['post'];
    final Map<String, dynamic> communityData = json['community'];
    final Map<String, dynamic> counts = json['counts'];
    final Map<String, dynamic>? imageDetails = postData['image_details'];
    final String? body = postData['body'];
    final id = postData['id'].toString();
    final rawUrl = postData['url'];
    final apId = postData['ap_id'];
    String url;
    String domain;
    bool isSelf;
    if (rawUrl != null) {
      url = rawUrl;
      domain = Uri.parse(url).host;
      isSelf = false;
    }
    else {
      url = apId;
      domain = Uri.parse(apId).host;
      isSelf = true;
    }
    return Post(
      community: Community(
        platform: Platform.lemmy,
        host: host,
        name: communityData['name'],
        id: communityData['id'].toString(),
      ),
      id: id,
      permalink: '/post/$id',
      score: counts['score'],
      timestampMs: DateTime.parse(postData['published']).millisecondsSinceEpoch,
      title: postData['name'],
      textHtml: body != null && body.isNotEmpty ? _markdownToHtml(body) : null,
      author: json['creator']['name'],
      commentCount: counts['comments'],
      url: url,
      domain: domain.replaceFirst(RegExp(r'^www\.'), ''),
      thumbnailUrl: postData['thumbnail_url'],
      isDeleted: postData['deleted'],
      isSelf: isSelf,
      isNsfw: postData['nsfw'],
      isStickied: postData['featured_community'],
      isGallery: false, 
      mediaSize: imageDetails != null ? Size((imageDetails['width'] as num).toDouble(), (imageDetails['height'] as num).toDouble()) : null,
      galleryImages: [],
      vote: postData['my_vote'] == 1 ? true : (postData['my_vote'] == -1 ? false : null),
    );
  }

  PostDetails _parsePostDetails(String host, String body) {
    final Map<String, dynamic> json = jsonDecode(body);
    final List<dynamic> rawComments = json['comments'];
    final Map<String, int> apiRank = {};
    final Map<String, String> commentToRoot = {};

    for (int i = 0; i < rawComments.length; i++) {
      final Map<String, dynamic> rawComment = rawComments[i]['comment'];
      final segments = (rawComment['path'] as String).split('.');
      final commentId = rawComment['id'].toString();
      apiRank[commentId] = i;
      if (segments.length > 1) {
        commentToRoot[commentId] = segments[1];
      }
    }
    
    rawComments.sort((a, b) {
      final Map<String, dynamic> rawCommentA = a['comment'];
      final Map<String, dynamic> rawCommentB = b['comment'];
      final String rootA = commentToRoot[rawCommentA['id'].toString()]!;
      final String rootB = commentToRoot[rawCommentB['id'].toString()]!;
      if (rootA != rootB) {
        return (apiRank[rootA]!).compareTo(apiRank[rootB]!);
      }
      final partsA = (rawCommentA['path'] as String).split('.');
      final partsB = (rawCommentB['path'] as String).split('.');
      final length = partsA.length < partsB.length ? partsA.length : partsB.length;
      for (int i = 0; i < length; i++) {
        final String segA = partsA[i];
        final String segB = partsB[i];
        if (segA != segB) {
          return (apiRank[segA]!).compareTo(apiRank[segB]!);
        }
      }
      return partsA.length.compareTo(partsB.length);
    });

    return PostDetails(
      post: null,
      comments: rawComments.map<CommentItem>((item) => _parseComment(host, item)).toList(),
      contextCommentShortId: null,
    );
  }

  Comment _parseComment(String host, Map<String, dynamic> json) {
    final Map<String, dynamic> commentData = json['comment'];
    final Map<String, dynamic> creatorData = json['creator'];
    final Map<String, dynamic> communityData = json['community'];
    final Map<String, dynamic> postData = json['post'];
    final String commentId = commentData['id'].toString();
    final String content = commentData['content'];
    final textHtml = _markdownToHtml(content);
    final depth = commentData['path'].split('.').length - 2;
    final creatorId = creatorData['id'];
    return Comment(
      depth: depth < 0 ? 0 : depth,
      community: Community(
        platform: Platform.lemmy,
        host: host,
        name: communityData['name'],
        id: communityData['id'].toString(),
      ),
      id: commentId,
      permalink: '/post/${postData['id']}/$commentId',
      isDeleted: commentData['deleted'],
      authorId: creatorId.toString(),
      authorName: creatorData['name'],
      isModerator: json['creator_is_moderator'],
      isSubmitter: creatorId == postData['creator_id'],
      score: json['counts']['score'],
      timestampMs: DateTime.parse(commentData['published']).millisecondsSinceEpoch,
      text: _htmlToPlainText(textHtml),
      textHtml: textHtml,
      vote: json['my_vote'] == 1 ? true : (json['my_vote'] == -1 ? false : null),
      postTitle: postData['name'],
    );
  }

  PagedItems<dynamic> _parseUserItems(String host, String body, String? pageToken, FeedOption? type) {
    final Map<String, dynamic> json = jsonDecode(body);
    final items = [
      if (type?.id != UserFeedType.comments)
        for (var item in json['posts'] ?? []) 
          _parsePost(host, item),
      if (type?.id != UserFeedType.posts)
        for (var item in json['comments'] ?? []) 
          _parseComment(host, item),
    ];
    return PagedItems(
      items: items,
      pageToken: items.length >= _resultsLimit && pageToken != null ? (int.parse(pageToken) + 1).toString() : null,
    );
  }

  List<UserStat> _parseUserStats(Map<String, dynamic> person, Map<String, dynamic> counts) {
    return [
      UserStat(
        label: 'Lemmy age',
        value: DateTime.parse(person['published']),
      ),
      UserStat(
        label: 'Post count',
        value: counts['post_count'],
      ),
      UserStat(
        label: 'Comment count',
        value: counts['comment_count'],
      ),
    ];
  }
  
}