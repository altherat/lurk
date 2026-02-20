import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' show Response;
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/login.dart';
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
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  const LemmyApi();

  @override
  List<LoginField>? get loginFields => [
    LoginField(label: 'Username or email', isSecret: false),
    LoginField(label: 'Password', isSecret: true),
  ];

  @override
  String get defaultUnauthenticatedUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:${Constants.version} (by u/altherat)';

  @override
  String? get savedUserAgent => Settings.lemmyUserAgent.value;
  
  @override
  String getBaseUrl(String host) => 'https://$host';

  @override
  ClientHelper getClientHelper(String? host, String? userId) => _ClientHelper(host!, {... _defaultHeaders, 'User-Agent': defaultUnauthenticatedUserAgent}, userId);

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
    final timeInterval = options?[FeedOptionType.time]?.id;
    final response = await clientHelper.get(
      '$_basePath/post/list',
      {
        'type_': ?options?[FeedOptionType.type]?.id,
        if (timeInterval != null)
          'sort': timeInterval
        else
          'sort': ?options?[FeedOptionType.sort]?.id,
        'community_name': ?id,
        'limit': _resultsLimit.toString(),
        'page_cursor': ?pageToken,
      }
    );
    final body = response.body;
    return Isolate.run(() => _parsePosts(body));
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
  Future<List<CommentItem>> getMoreComments(RestClientHelper clientHelper, String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) async {
    final response = await clientHelper.get(
      '$_basePath/comment/list',
      {
        'parent_id': id,
        'limit': _resultsLimit.toString(),
        'page': pageToken,
        'sort': options?[FeedOptionType.sort]?.id,
      }
    );
    final body = response.body;
    return Isolate.run(() {
      final Map<String, dynamic> json = jsonDecode(body);
      final List<dynamic> rawComments = json['comments'];
      return rawComments.map<CommentItem>((item) => _parseComment(item)).toList();
    });
  }

  @override
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(RestClientHelper clientHelper, String id, {Map<FeedOptionType, FeedOption>? options}) {
    final Future<String> futureBody = clientHelper.get('$_basePath/user', {'username': id}).then((response) => response.body);
    return MultiPartFeedResponse(
      items: futureBody.then((body) => _parseUserItems(body, null, options?[FeedOptionType.category])),
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
    final body = response.body;
    return Isolate.run(() => _parseUserItems(body, pageToken, options?[FeedOptionType.category]));
  }

  @override
  Future<PagedItems<dynamic>> getSearchResults(RestClientHelper clientHelper, String query, String? communityName, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final Map<String, dynamic> params = {
      'q': query,
      'type_': ?options?[FeedOptionType.category]?.id,
      'sort': ?options?[FeedOptionType.sort]?.id,
      'community_id': ?communityName,
      'limit': _resultsLimit.toString(),
      'page': ?pageToken
    };

    final response = await clientHelper.get('$_basePath/search', params);
    final body = response.body;
    return Isolate.run(() {
      final Map<String, dynamic> json = jsonDecode(body);
      final List<dynamic> items = [];

      final List<dynamic>? posts = json['posts'];
      if (posts != null) {
        for (var item in posts) {
          items.add(_parsePost(item));
        }
      }

      final List<dynamic>? comments = json['comments'];
      if (comments != null) {
        for (var item in comments) {
          items.add(_parseComment(item));
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
                host: Uri.parse(community['actor_id']).host,
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
              host: Uri.parse(person['actor_id']).host,
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
  Future<LoggedInUser> getLoggedInUser(RestClientHelper clientHelper) async {
    final response = await clientHelper.get('/api/v3/site');
    final Map<String, dynamic> data = jsonDecode(response.body);
    final personData = data['my_user']['local_user_view']['person'];
    return LoggedInUser(
      platform: Platform.lemmy,
      host: clientHelper.host,
      hostIconUrl: data['site_view']['site']['icon'],
      id: personData['id'].toString(),
      name: personData['name'],
      iconUrl: personData['avatar'],
    );
  }

  @override
  Future<List<Community>> getSubscribedCommunities(RestClientHelper clientHelper) async {
    final response = await clientHelper.get(
      '/api/v3/community/list',
      {
        'limit': _resultsLimit,
        'type_': 'Subscribed',
      },
    );
    final body = response.body;
    return Isolate.run(() {
      return (jsonDecode(body)['communities'] as List<dynamic>).map((json) {
        final community = json['community'];
        return Community(
          platform: Platform.lemmy,
          host: clientHelper.host,
          name: community['name'],
          id: community['id'].toString(),
        );
      }).toList();
    });
  }

  @override
  Future<void> subscribeToCommunity(RestClientHelper clientHelper, String communityId) {
    return clientHelper.post(
      '/api/v3/community/follow',
      {
        'community_id': int.parse(communityId),
        'follow': true,
      },
    );
  }

  @override
  Future<void> unsubscribeFromCommunity(RestClientHelper clientHelper, String communityId) {
    return clientHelper.post(
      '/api/v3/community/follow',
      {
        'community_id': int.parse(communityId),
        'follow': false,
      },
    );
  }

  @override
  Future<void> voteComment(RestClientHelper clientHelper, String commentId, bool? vote) {
    return clientHelper.post(
      '/api/v3/comment/like',
      {
        'comment_id': int.parse(commentId),
        'score': vote == true ? 1 : vote == false ? -1 : 0,
      },
    );
  }

  @override
  Future<void> votePost(RestClientHelper clientHelper, String postId, bool? vote) {
    return clientHelper.post(
      '/api/v3/post/like',
      {
        'post_id': int.parse(postId),
        'score': vote == true ? 1 : vote == false ? -1 : 0,
      },
    );
  }

  @override
  Future<Comment> postComment(RestClientHelper clientHelper, String parentId, String text) async {
    final response = await clientHelper.post(
      '/api/v3/comment/create',
      {
        'parent_id': int.parse(parentId),
        'body': text,
      },
    );
    final String body = response.body;
    return Isolate.run(() => _parseComment(jsonDecode(body)['comment_view']));
  }

  @override 
  Future<void> deleteComment(RestClientHelper clientHelper, String commentId) {
    return clientHelper.post(
      '/api/v3/comment/delete',
      {
        'comment_id': int.parse(commentId),
        'deleted': true,
      },
    );
  }

  PagedItems<Post> _parsePosts(String body) {
    final Map<String, dynamic> json = jsonDecode(body);
    return PagedItems(
      items: (json['posts'] as List<dynamic>).map((item) => _parsePost(item)).toList(),
      pageToken: json['next_page'],
    );
  }

  Post _parsePost(Map<String, dynamic> json) {
    final Map<String, dynamic> postData = json['post'];
    final Map<String, dynamic> communityData = json['community'];
    final Map<String, dynamic> creatorData = json['creator'];
    final Map<String, dynamic> counts = json['counts'];
    final Map<String, dynamic>? imageDetails = json['image_details'];
    final String? body = postData['body'];
    final String? rawUrl = postData['url'];
    final String apId = postData['ap_id'];
    final id = postData['id'].toString();

    final String url;
    final String domain;
    final bool isSelf;
    final Size? mediaSize;

    (String, Size?) getDomainAndMediaSize(String url) {
      if (imageDetails != null) {
        return (imageDetails['content_type'], Size((imageDetails['width'] as num).toDouble(), (imageDetails['height'] as num).toDouble()));
      }
      return (Uri.parse(apId).host.replaceFirst(RegExp(r'^www\.'), ''), null);
    }

    if (rawUrl != null) {
      url = rawUrl;
      isSelf = false;
      (domain, mediaSize) = getDomainAndMediaSize(rawUrl);
    }
    else {
      url = apId;
      isSelf = true;
      (domain, mediaSize) = getDomainAndMediaSize(apId);
    }
    return Post(
      community: Community(
        platform: Platform.lemmy,
        host: Uri.parse(communityData['actor_id']).host,
        name: communityData['name'],
        id: communityData['id'].toString(),
      ),
      id: id,
      permalink: '/post/$id',
      score: counts['score'],
      timestampMs: DateTime.parse(postData['published']).millisecondsSinceEpoch,
      title: postData['name'],
      textHtml: body != null && body.isNotEmpty ? _markdownToHtml(body) : null,
      author: creatorData['name'],
      authorHost: Uri.parse(creatorData['actor_id']).host,
      commentCount: counts['comments'],
      url: url,
      domain: domain,
      thumbnailUrl: postData['thumbnail_url'],
      isDeleted: postData['deleted'],
      isSelf: isSelf,
      isNsfw: postData['nsfw'],
      isStickied: postData['featured_community'],
      isGallery: false, 
      mediaSize: mediaSize,
      galleryImages: [],
      vote: json['my_vote'] == 1 ? true : (json['my_vote'] == -1 ? false : null),
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
      comments: rawComments.map<CommentItem>((item) => _parseComment(item)).toList(),
      contextCommentShortId: null,
    );
  }

  Comment _parseComment(Map<String, dynamic> json) {
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
        host: Uri.parse(communityData['actor_id']).host,
        name: communityData['name'],
        id: communityData['id'].toString(),
      ),
      id: commentId,
      permalink: '/post/${postData['id']}/$commentId',
      isDeleted: commentData['deleted'],
      authorId: creatorId.toString(),
      authorName: creatorData['name'],
      authorHost: Uri.parse(creatorData['actor_id']).host,
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

  PagedItems<dynamic> _parseUserItems(String body, String? pageToken, FeedOption? type) {
    final Map<String, dynamic> json = jsonDecode(body);
    final items = [
      if (type?.id != UserFeedType.comments)
        for (var item in json['posts'] ?? []) 
          _parsePost(item),
      if (type?.id != UserFeedType.posts)
        for (var item in json['comments'] ?? []) 
          _parseComment(item),
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

class _ClientHelper extends SimpleRestClientHelper implements AuthClientHelper {

  final _secureStorage = const FlutterSecureStorage();
  final String? _userId;
  String? _jwt;
  Future<String?>? _loadJwtFuture;

  _ClientHelper(
    super.host,
    super.headers,
    String? userId
  ) : _userId = userId;

  @override
  Future<Response> performPost(Uri uri, Map<String, String> headers, dynamic body) => super.performPost(uri, headers, jsonEncode(body));

  @override
  Future<Response> request(Map<String, String> headers, Future<Response> Function(Map<String, String> headers) request) async {
    if (_jwt != null || (_userId != null && (_jwt = await (_loadJwtFuture ??= _secureStorage.read(key: 'lemmy_jwt_${host}_$_userId'))) != null)) {
      dev.log('[Lemmy][_ClientHelper] Adding authorization header: jwt=${debugTruncateLongString(_jwt)}');
      headers['Authorization'] = 'Bearer $_jwt';
    }
    return request(headers);
  }
  
  @override
  Future<FetchTokenResult> fetchToken([Map<String, String>? credentials]) async {
    dev.log('[Lemmy][_ClientHelper] fetchToken');
    final response = await post(
      '/api/v3/user/login',
      {
        'username_or_email': credentials!['Username or email'],
        'password': credentials['Password'],
      }
    );
    dev.log('[Lemmy][_ClientHelper] fetchToken response: statusCode=${response.statusCode}, body=${response.body}');
    if (response.statusCode == 200) {
      _jwt = jsonDecode(response.body)['jwt'];
      return FetchTokenSuccess();
    }
    if (response.statusCode == 401) {
      return switch(jsonDecode(response.body)['error']) {
        'incorrect_login' => FetchTokenError('invalid credentials'),
        'email_not_verified' => FetchTokenError('email not verified'),
        'registration_pending' || 'registration_application_pending' => FetchTokenError('registration pending'),
        'registration_denied' => FetchTokenError('registration denied'),
        _ => FetchTokenError(),
      };
    }
    return FetchTokenError();
  }

  @override
  Future<void> saveToken(String userId) {
    dev.log('[Lemmy][_ClientHelper] saveToken: userId=$userId, jwt=${debugTruncateLongString(_jwt)}');
    return _secureStorage.write(key: 'lemmy_jwt_${host}_$userId', value: _jwt);
  }

}