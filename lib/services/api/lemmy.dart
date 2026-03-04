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
    LoginField(
      type: LoginFieldType.identity,
      label: 'Username or email'
    ),
    LoginField(
      type: LoginFieldType.secret,
      label: 'Password'
    ),
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

    final body = response.body;
    return Isolate.run(() {
      final Map<String, dynamic> json = jsonDecode(body);
      final Map<String, dynamic> view = json['community_view'];
      final Map<String, dynamic> communityData = view['community'];
      final Map<String, dynamic> counts = view['counts'];
      return CommunityDetails(
        community: _parseCommunity(communityData),
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
  Future<PagedItems<Post>> getCommunityPosts(RestClientHelper clientHelper, String? id, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
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
    final host = clientHelper.host;
    final body = response.body;
    return Isolate.run(() => _parsePosts(host, body));
  }

  @override
  Future<Post> getPost(RestClientHelper clientHelper, String id) async {
    final response = await clientHelper.get(
      '$_basePath/post',
      {
        'id': id,
      },
    );
    final host = clientHelper.host;
    final body = response.body;
    return Isolate.run(() => _parsePost(host, jsonDecode(body)['post_view']));
  }

  @override
  Future<(List<CommentItem>, Post)> getCommentsAndPost(RestClientHelper clientHelper, String id, String? communityName, String? contextCommentShortId, Map<FeedOptionType, FeedOption>? options) async {
    return ((await getCommentsAndMaybePost(clientHelper, id, communityName, contextCommentShortId, options)).$1, await getPost(clientHelper, id));
  }

  @override
  Future<(List<CommentItem>, Post?)> getCommentsAndMaybePost(RestClientHelper clientHelper, String id, String? communityName, String? contextCommentShortId, Map<FeedOptionType, FeedOption>? options) async {
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
    final body = response.body;
    return Isolate.run(() {
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

      return (rawComments.map<CommentItem>((item) => _parseComment(item)).toList(), null);
    });
  }

  @override
  Future<List<CommentItem>> getMoreComments(RestClientHelper clientHelper, String id, int? depth, String pageToken, Map<FeedOptionType, FeedOption>? options) async {
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
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(RestClientHelper clientHelper, String id, Map<FeedOptionType, FeedOption>? options) {
    final Future<String> futureBody = clientHelper.get('$_basePath/user', {'username': id}).then((response) => response.body);
    final host = clientHelper.host;
    return MultiPartFeedResponse(
      items: futureBody.then((body) => _parseUserItems(host, body, null, options?[FeedOptionType.category])),
      other: futureBody.then((body) {
        final personView = jsonDecode(body)['person_view'];
        return _parseUserStats(personView['person'], personView['counts']);
      })
    );
  }
  
  @override
  Future<PagedItems<dynamic>> getUserItems(RestClientHelper clientHelper, String id, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
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
  Future<PagedItems<dynamic>> getSearchResults(RestClientHelper clientHelper, String query, String? communityName, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
    final response = await clientHelper.get(
      '$_basePath/search',
        {
        'q': query,
        'type_': ?options?[FeedOptionType.category]?.id,
        'sort': ?options?[FeedOptionType.sort]?.id,
        'community_name': ?communityName,
        'limit': _resultsLimit.toString(),
        'page': ?pageToken
      }
    );
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
          items.add(_parseComment(item));
        }
      }

      final List<dynamic>? communities = json['communities'];
      if (communities != null) {
        for (var item in communities) {
          final communityData = item['community'];
          final counts = item['counts'];
          items.add(
            CommunityDetails(
              community: _parseCommunity(communityData),
              title: communityData['title'],
              iconUrl: communityData['icon'],
              subscriberCount: counts['subscribers'],
              postCount: counts['posts'],
            )
          );
        }
      }

      final List<dynamic>? users = json['users'];
      if (users != null) {
        for (var item in users) {
          final Map<String, dynamic> personData = item['person'];
          items.add(
            LookedUpUser(
              platform: Platform.lemmy,
              host: Uri.parse(personData['actor_id']).host,
              id: personData['id'].toString(),
              name: personData['name'],
              iconUrl: personData['avatar'],
              isSuspended: personData['banned'],
              stats: _parseUserStats(personData, item['counts'])
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
  Future<Post> resolveGlobalToLocalPost(RestClientHelper clientHelper, String globalId) async => _parsePost(clientHelper.host, jsonDecode((await clientHelper.get('/api/v3/resolve_object', {'q': globalId})).body)['post']);

  @override
  Future<LoggedInUser> getLoggedInUser(RestClientHelper clientHelper) async {
    final response = await clientHelper.get('/api/v3/site');
    final Map<String, dynamic> data = jsonDecode(response.body);
    final personData = data['my_user']['local_user_view']['person'];
    return LoggedInUser(
      id: personData['id'].toString(),
      platform: Platform.lemmy,
      host: clientHelper.host,
      name: personData['name'],
      iconUrl: personData['avatar'],
      hostIconUrl: data['site_view']['site']['icon'],
    );
  }

  @override
  Future<List<Community>> getSubscribedCommunities(RestClientHelper clientHelper) async {
    final response = await clientHelper.get(
      '/api/v3/community/list',
      {
        'limit': _resultsLimit.toString(),
        'type_': 'Subscribed',
      },
    );
    final body = response.body;
    return Isolate.run(() => (jsonDecode(body)['communities'] as List).map((json) => _parseCommunity(json['community'])).toList());
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
    final body = response.body;
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

  Community _parseCommunity(Map<String, dynamic> communityData) {
    return Community(
      platform: Platform.lemmy,
      host: Uri.parse(communityData['actor_id']).host,
      name: (communityData['name'] as String).toLowerCase(),
      id: communityData['id'].toString(),
    );
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
    final Map<String, dynamic> creatorData = json['creator'];
    final Map<String, dynamic> counts = json['counts'];
    final Map<String, dynamic>? imageDetails = json['image_details'];
    final String? body = postData['body'];
    final String? postDataUrl = postData['url'];
    final String apId = postData['ap_id'];
    final String? urlContentType = postData['url_content_type'];
    final id = postData['id'].toString();
    final vote = json['my_vote'];
    ContentType? contentType;
    final String url;
    if (postDataUrl != null) {
      url = postDataUrl;
    }
    else {
      contentType = ContentType.local;
      url = apId;
    }
    final String domain;
    if (urlContentType?.startsWith('image/') ?? false) {
      contentType = ContentType.image;
      domain = 'image';
    }
    else {
      final uri = Uri.tryParse(url);
      domain = uri?.host.replaceFirst(RegExp(r'^www\.'), '') ?? (urlContentType ?? 'unknown');
    }
    return Post(
      community: _parseCommunity(json['community']),
      localId: id,
      localHost: host,
      shortLocalId: id,
      globalId: apId,
      localUrlPath: '/post/$id',
      authorId: creatorData['id'].toString(),
      authorHost: Uri.parse(creatorData['actor_id']).host,
      authorName: creatorData['name'],
      contentType: contentType,
      score: counts['score'],
      timestampMs: DateTime.parse(postData['published']).millisecondsSinceEpoch,
      title: postData['name'],
      body: body,
      bodyHtml: body != null && body.isNotEmpty ? _markdownToHtml(body) : null,
      commentCount: counts['comments'],
      linkUrl: url,
      linkDomain: domain,
      thumbnailUrl: postData['thumbnail_url'],
      mediaSize: imageDetails != null ? Size((imageDetails['width'] as num).toDouble(), (imageDetails['height'] as num).toDouble()) : null,
      galleryImages: null,
      isRemoved: false,
      isStickied: postData['featured_local'] || postData['featured_community'],
      isNsfw: postData['nsfw'],
      vote: vote == 1 ? true : (vote == -1 ? false : null),
    );
  }

  Comment _parseComment(Map<String, dynamic> json) {
    final Map<String, dynamic> commentData = json['comment'];
    final Map<String, dynamic> creatorData = json['creator'];
    final Map<String, dynamic> postData = json['post'];
    final String commentId = commentData['id'].toString();
    final String content = commentData['content'];
    final textHtml = _markdownToHtml(content);
    final depth = commentData['path'].split('.').length - 2;
    final creatorId = creatorData['id'];
    return Comment(
      depth: depth < 0 ? 0 : depth,
      community: _parseCommunity(json['community']),
      localId: commentId,
      shortLocalId: commentId,
      urlPath: '/post/${postData['id']}/$commentId',
      authorId: creatorId.toString(),
      authorName: creatorData['name'],
      authorHost: Uri.parse(creatorData['actor_id']).host,
      isDeleted: commentData['deleted'],
      isModerator: json['creator_is_moderator'],
      isSubmitter: creatorId == postData['creator_id'],
      score: json['counts']['score'],
      timestampMs: DateTime.parse(commentData['published']).millisecondsSinceEpoch,
      text: _htmlToPlainText(textHtml),
      textHtml: textHtml,
      imageSizes: null,
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
  Future<FetchTokenResult?> fetchToken([Map<String, String>? credentials]) async {
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
    dev.log('[Lemmy][_ClientHelper] saveToken: key=${'lemmy_jwt_${host}_$userId'}, jwt=${debugTruncateLongString(_jwt)}');
    return _secureStorage.write(key: 'lemmy_jwt_${host}_$userId', value: _jwt);
  }

}