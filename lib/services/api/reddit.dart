import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' as io;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/votes.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

class RedditApi extends Api {

  static const _domain = 'reddit.com';
  static const _baseUrl = 'https://$_domain';
  static const _baseUrlOld = 'https://old.$_domain';
  static const _oauthDomain = 'oauth.$_domain';
  static const _oauthScopes = ['history', 'identity', 'read', 'submit', 'vote'];
  
  static http.Client? _clientInstance;
  static OAuth2Helper? _oauth2Helper;
  static Future<bool>? _initClientFuture;

  const RedditApi();

  @override
  // String get defaultUserAgent => 'RedReader/1.25.1';
  String get defaultUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:0.1.0 (by u/altherat)';

  @override
  Map<String, String> get defaultHeaders => const {'Accept': 'application/json'};

  Future<String?> login() async {
    await _checkIfSettingsChanged();
    if (await _ensureClientInitialized()) {
      final tokenResponse = await _oauth2Helper!.fetchToken();
      if (tokenResponse.isValid()) {
        _clientInstance?.close();
        _clientInstance = null;
        final data = jsonDecode((await _get('/api/v1/me')).body);
        final iconUri = Uri.parse(data['icon_img']);
        final user = LoggedInUser(
          id: data['name'],
          name: data['name'],
          iconUrl: Uri(scheme: iconUri.scheme,host: iconUri.host,path: iconUri.path).toString(),
          inboxCount: data['inbox_count'],
          score: data['link_karma'] + data['comment_karma']
        );
        Settings.loggedInUsers.add(user);
        Settings.activeUser.value = user;
        return user.name;
      }
    }
    return null;
  }

  Future<String> logout() async {
    await _ensureClientInitialized();
    await _oauth2Helper!.removeAllTokens();
    final user = Settings.activeUser.value!;
    Settings.loggedInUsers.remove(user);
    Settings.activeUser.value = null;
    _oauth2Helper = null;
    _initClientFuture = null;
    return user.name;
  }

  Future<bool> _ensureClientInitialized() => _initClientFuture ??= _initClient();

  Future<bool> _initClient() async {
    final clientId = Settings.redditClientId.value;
    if (clientId == null) {
      if (_oauth2Helper != null) {
        await _oauth2Helper!.removeAllTokens();
        _oauth2Helper = null;
      }
      _clientInstance ??= http.Client();
      Settings.activeUser.value = null;
      debugPrint('initialized http.Client');
      return false;
    }

    final (redirectUri, customUriScheme) = _redirectUriAndCustomUriScheme;
    _oauth2Helper = OAuth2Helper(
      OAuth2Client(
        authorizeUrl: 'https://www.reddit.com/api/v1/authorize',
        tokenUrl: 'https://www.reddit.com/api/v1/access_token',
        redirectUri: redirectUri,
        customUriScheme: customUriScheme
      ),
      grantType: OAuth2Helper.authorizationCode,
      clientId: clientId,
      clientSecret: '',
      scopes: _oauthScopes,
      authCodeParams: {
        'duration': 'permanent',
        'prompt': 'select_account'
      },
    );
      debugPrint('initialized OAuth2Helper');
    return true;
  }

  Future<void> _checkIfSettingsChanged() async {
    final clientId = Settings.redditClientId.value;
    final redirectUri = Settings.redditRedirectUri.value;
    if (clientId == null || redirectUri == null) {
      if (_oauth2Helper != null) {
        await _oauth2Helper!.removeAllTokens();
        _initClientFuture = null;
      }
    }
    else if (_oauth2Helper == null || _oauth2Helper!.clientId != clientId || _oauth2Helper!.client.redirectUri != redirectUri) {
      await _oauth2Helper?.removeAllTokens();
      if (_clientInstance != null) {
        _clientInstance!.close();
        _clientInstance = null;
      }
      _initClientFuture = null;
    }
  }

  Future<Response> _request(Future<Response> Function() request, Future<Response> Function() oAuthRequest) async {
    await _checkIfSettingsChanged();
    if (await _ensureClientInitialized()) {
      final accessToken = await _oauth2Helper!.getTokenFromStorage();
      if (accessToken == null || (!accessToken.hasRefreshToken() && accessToken.isExpired())) {
        final response = await http.post(
          Uri.parse('https://www.reddit.com/api/v1/access_token'),
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('${Settings.redditClientId.value}:'))}',
            'User-Agent': defaultUserAgent,
          },
          body: {
            'grant_type': 'https://oauth.reddit.com/grants/installed_client',
            'device_id': List<int>.generate(16, (i) => Random.secure().nextInt(256)).map((e) => e.toRadixString(16).padLeft(2, '0')).join(),
          }
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await _oauth2Helper!.tokenStorage.addToken(AccessTokenResponse.fromMap({
            'access_token': data['access_token'],
            'token_type': 'bearer',
            'expires_in': data['expires_in'],
            'scope': _oauthScopes.join(' '),
          }));
        }
      }
      return _onResponse(await oAuthRequest());
    }
    return _onResponse(await request());
  }

  Future<Response> _get(String path, {Map<String, dynamic>? params}) async {
    // debugPrint('[Reddit] _get: path=$path, params=$params]');
    return _request(
      () => _clientInstance!.get(
        Uri.https(_domain, path, (params != null && params.isNotEmpty) ? params : null),
        headers: headers
      ),
      () => _oauth2Helper!.get(
        Uri.https(_oauthDomain, path, (params != null && params.isNotEmpty) ? params : null).toString(),
        headers: headers
      )
    );
  }

  Future<Response> _post(String path, Map<String, String> body) async {
    // debugPrint('[Reddit] _post: path=$path, params=$body]');
    await _checkIfSettingsChanged();
    await _ensureClientInitialized();
    return _request(
      () => _clientInstance!.post(
        Uri.https(_domain, path),
        headers: headers,
        body: body
      ),
      () => _oauth2Helper!.post(
        Uri.https(_oauthDomain, path).toString(),
        headers: headers,
        body: body
      )
    );
  }

  Future<Response> _onResponse(Response response) async {
    // debugPrint('_onResponse: statusCode=${response.statusCode}');
    // debugPrint('Response: ${response.body}');
    // debugPrint('Headers:');
    // for (var header in response.headers.entries) {
    //   if (header.key.startsWith('x-ratelimit-')) {
    //     debugPrint('\t${header.key}: ${header.value}');
    //   }
    // }
    return response;
  }

  (String, String) get _redirectUriAndCustomUriScheme {
    final redirectUri = Settings.redditRedirectUri.value;
    return redirectUri != null ? (redirectUri, redirectUri.split('://')[0]) : ('', 'com.altherat.lurk');
  }

  @override
  String get baseUrl => Settings.redditCopyOldRedditLinks.value ? _baseUrlOld : _baseUrl;

  @override
  Future<PagedResult<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // debugPrint('[Reddit] getPosts: $id, sort=${sort?.label}, timeRange=$timeRange, after=$pageToken');
    final sort = options?[FeedOptionType.sort];
    final timeRange = options?[FeedOptionType.time];
    final subreddit = id ?? Platform.reddit.communityHome;
    String path = '/r/$subreddit';
    if (sort != null) {
      path += '/${sort.id}';
    }

    final Map<String, dynamic> params = {};
    if (timeRange != null) {
      params['t'] = timeRange.id;
    }
    if (pageToken != null) {
      params['after'] = pageToken;
    }
    
    final (votes, result) = await compute(_parsePosts, (await _get('$path.json', params: params)).body);
    votes.forEach((postId, vote) => Votes.posts.setVote(postId, vote));
    return result;
  }

  @override
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options}) async {
    // debugPrint('[Reddit] getPostDetailsFromUrl: url=$url, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    final sort = uri.queryParameters['sort'];
    if (sort != null) {
      options ??= {};
      options[FeedOptionType.sort] = FeedOption('Sort', id: sort);
    }
    final String? commentId;
    if (pathSegments.length > 5) {
      final segment = pathSegments[5];
      commentId = segment.isNotEmpty ? segment : null;
    }
    else {
      commentId = null;
    }
    return getPostDetailsFromId(pathSegments[3], commentId: commentId, options: options);
  }

  @override
  Future<PostDetails> getPostDetailsFromId(String id, {String? commentId, Map<FeedOptionType, FeedOption>? options}) async {
    // debugPrint('[Reddit] getPostDetailsFromId: id=$id, commentId=$commentId, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final sort = options?[FeedOptionType.sort];
    final segments = ['comments', id];
    final params = {
      if (sort != null)
        'sort': sort.id,
    };
    if (commentId != null) {
      segments.addAll(['comment', commentId]);
      params['context'] = '3';
    }
    final (postVote, commentVotes, postDetails) = await compute(
      ((String, String?) args) {
        final (body, contextCommentId) = args;
        final json = jsonDecode(body);
        final (postVote, post) = _parsePost(json[0]['data']['children'][0]);
        final (Map<String, bool?> commentVotes, List<CommentItem> comments) = _parseComments(json[1]['data']['children'] as List, 0);
        return (
          postVote,
          commentVotes,
          PostDetails(
            post: post,
            comments: comments,
            contextCommentId: contextCommentId
          )
        );
      },
      ((await _get('/${segments.join('/')}.json', params: params)).body, commentId)
    );
    Votes.posts.setVote(postDetails.post.id, postVote);
    commentVotes.forEach((commentId, vote) => Votes.comments.setVote(commentId, vote));
    return postDetails;
  }

  @override
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) async {
    // debugPrint('[Reddit] getPostDetailsFromUrl: id=$id, pageToken=$pageToken, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final sort = options?[FeedOptionType.sort];
    final body = {
      'api_type': 'json',
      'link_id': id,
      'children': pageToken,
      if (sort != null)
        'sort': sort.id.toString()
    };
    final Future<Response> response;
    final (Map<String, bool?>, List<CommentItem>) Function(String) parseFn;
    if (_oauth2Helper != null) {
      response = _oauth2Helper!.post(
        Uri.https(_oauthDomain, '/api/morechildren').toString(),
        headers: headers,
        body: body
      );
      parseFn = (String body) {
        final Map<String, dynamic> jsonResponse = jsonDecode(body);
        final List<dynamic> things = jsonResponse['json']?['data']?['things'] ?? [];
        
        final Map<String, bool?> votes = {};
        final List<CommentItem> items = [];
        final Map<String, int> batchDepthCache = {};

        for (var thing in things) {
          final String kind = thing['kind'];
          final Map<String, dynamic> data = thing['data'];
          final String id = data['name'];
          final String parentId = data['parent_id'];
          final currentDepth = batchDepthCache.containsKey(parentId) ? batchDepthCache[parentId]! + 1 : (data['depth'] ?? depth ?? 0);
          batchDepthCache[id] = currentDepth;
          if (kind == 't1') {
            final (vote, comment) = _parseCommentFromJson(data, currentDepth);
            votes[comment.id] = vote;
            items.add(comment);
          } 
          else if (kind == 'more') {
            items.add(
              LoadMoreComment(
                depth: currentDepth,
                count: data['count'] ?? 0,
                pageToken: (data['children'] as List).join(','),
              ),
            );
          }
        }
        return (votes, items);
      };
    }
    else {
      _clientInstance ??= http.Client();
      response = _clientInstance!.post(
        Uri.parse('$_baseUrlOld/api/morechildren'),
        headers: headers,
        body: body
      );
      parseFn = (String body) {
        final Map<String, dynamic> jsonResponse = jsonDecode(body);
        final List<dynamic> things = jsonResponse['json']['data']['things'];
        final Map<String, bool?> votes = {};
        final List<CommentItem> items = [];
        final Map<String, int> batchDepthCache = {};
        for (var thing in things) {
          final kind = thing['kind'];
          final data = thing['data'];
          final id = data['id'];
          final parentId = data['parent'];
          final currentDepth = batchDepthCache.containsKey(parentId) ? batchDepthCache[parentId]! + 1 : depth!;
          batchDepthCache[id] = currentDepth;
          if (kind == 't1') {
            final content = data['content'];
            final element = parse(parse(content).body?.text).querySelector('.thing')!;
            final entry = element.querySelector('.entry');
            final authorElement = entry?.querySelector('.author');
            final author = authorElement?.text;
            final scoreTitle = entry?.querySelector('.tagline .score.unvoted')?.attributes['title'];
            final textHtml = entry?.querySelector('.usertext-body .md');
            final dateTimeString = entry?.querySelector('.tagline time')?.attributes['datetime'];
            final midcol = element.querySelector('.midcol')!;
            votes[id] = midcol.classes.contains('likes') ? true : midcol.classes.contains('dislikes') ? false : null;
            items.add(
              Comment(
                depth: currentDepth,
                platform: Platform.reddit,
                id: element.attributes['data-fullname']!,
                permalink: element.attributes['data-permalink']!,
                isDeleted: author == '[deleted]',
                author: author,
                isModerator: authorElement?.classes.contains('moderator') ?? false,
                isSubmitter: authorElement?.classes.contains('submitter') ?? false,
                score: scoreTitle == null ? null : int.tryParse(scoreTitle),
                timestampMs: dateTimeString != null ? DateTime.parse(dateTimeString).millisecondsSinceEpoch : 0,
                text: textHtml!.text,
                textHtml: textHtml.innerHtml.trim(),
              )
            );
          }
          else if (kind == 'more') {
            final moreLink = parse(parse(data['content']).body?.text).querySelector('.thing')!.querySelector('.morecomments a');
            final countMatch = RegExp(r'(\d+)').firstMatch(moreLink!.text.trim());
            final idMatch = RegExp(r"morechildren\(.*?\s*'.*?'\s*,\s*'.*?'\s*,\s*'(.*?)'").firstMatch(moreLink.attributes['onclick']!);
            items.add(
              LoadMoreComment(
                depth: currentDepth,
                count: int.tryParse(countMatch!.group(1)!)!,
                pageToken: idMatch!.group(1)!
              )
            );
          }
        }
        return (votes, items);
      };
    }
    final (votes, items) = await compute(parseFn, (await response).body);
    votes.forEach((commentId, vote) => Votes.comments.setVote(commentId, vote));
    return items;
  }

  @override
  UserDetailsResponse getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options}) {
    // debugPrint('[Reddit] getUserDetails: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}]');
    return UserDetailsResponse(
      stats: _get('/u/$id/about.json').then((response) {
        final data = jsonDecode(response.body)['data'];
        return [
          UserStat(
            label: 'Reddit age',
            value: DateTime.fromMillisecondsSinceEpoch((data['created_utc'] as num).toInt() * 1000, isUtc: true)
          ),
          UserStat(
            label: 'Karma',
            value: data['total_karma']
          ),
          UserStat(
            label: 'Link karma',
            value: data['link_karma']
          ),
          UserStat(
            label: 'Comment karma',
            value: data['comment_karma']
          )
        ];
      }),
      items: getUserItems(id, options: options)
    );
  }

  @override
  Future<PagedResult<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // debugPrint('[Reddit] getUserItems: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final FeedOption? type = options?[FeedOptionType.type];
    final FeedOption? sort = options?[FeedOptionType.sort];
    final FeedOption? timeRange = options?[FeedOptionType.time];
    String path = '/u/$id';
    if (type != null) {
      if (type.id == UserFeedType.posts) {
        path += '/submitted';
      }
      else if (type.id == UserFeedType.comments) {
        path += '/comments';
      }
    }

    final Map<String, dynamic> params = {};
    if (sort != null) {
      params['sort'] = sort.id;
    }
    if (timeRange != null) {
      params['t'] = timeRange.id;
    }
    if (pageToken != null) {
      params['after'] = pageToken;
    }
    
    final (postVotes, commentVotes, result) = await compute(
      (String body) {
        final Map<String, bool?> postVotes = {};
        final Map<String, bool?> commentVotes = {};
        final List<dynamic> items = [];
        final json = jsonDecode(body);
        final data = json['data'];
        final children = data['children'] as List;
        for (var child in children) {
          final String kind = child['kind'];
          if (kind == 't3') {
            final (vote, post) = _parsePost(child);
            postVotes[post.id] = vote;
            items.add(post);
          }
          else if (kind == 't1') {
            final (vote, comment) = _parseCommentFromJson(child['data'], 0);
            commentVotes[comment.id] = vote;
            items.add(comment);
          }
        }
        return (
          postVotes,
          commentVotes,
          PagedResult(
            items: items,
            pageToken: data['after'],
          )
        );
      },
      (await _get('$path.json', params: params)).body
    );

    postVotes.forEach((id, vote) => Votes.posts.setVote(id, vote));
    commentVotes.forEach((id, vote) => Votes.comments.setVote(id, vote));

    return result;
  }

  @override
  Future<PagedResult<dynamic>> search(String query, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // debugPrint('[Reddit] search: query=$query, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final type = options?[FeedOptionType.type]?.id;
    final sort = options?[FeedOptionType.sort];
    final timeRange = options?[FeedOptionType.time];
    final Map<String, dynamic> params = {
      'q': query,
    };
    if (sort != null) {
      params['sort'] = sort.id;
    }
    if (timeRange != null) {
      params['t'] = timeRange.id;
    }
    if (pageToken != null) {
      params['after'] = pageToken;
    }
    switch (type) {
      case SearchFeedType.communities:
        params['type'] = 'sr';
      case SearchFeedType.users:
        params['type'] = 'user';
    }

    final responseBody = (await _get('/search.json', params: params)).body;

    switch (type) {
      case SearchFeedType.communities:
        return compute(
          (String body) {
            final json = jsonDecode(body);
            final data = json['data'];
            final children = data['children'] as List;
            return PagedResult(
              items: children
                  .where((child) => child['kind'] == 't5')
                  .map((child) {
                    final childData = child['data'];
                    final String description = childData['public_description'];
                    return Community(
                      platform: Platform.reddit,
                      name: childData['display_name'],
                      description: description.isNotEmpty ? description : null,
                      subscriberCount: childData['subscribers'],
                    );
                  })
                  .toList(),
              pageToken: data['after'],
            );
          },
          responseBody
        );
      case SearchFeedType.users:
        return compute(
          (String body) {
            final json = jsonDecode(body);
            final data = json['data'];
            final children = data['children'] as List;

            return PagedResult(
              items: children
                .map((child) {
                  final childData = child['data'];
                  final bool isSuspended = childData['is_suspended'] ?? false;
                  return LookedUpUser(
                    id: childData['id'],
                    name: childData['name'],
                    iconUrl: (childData['icon_img'] as String?)?.replaceAll('&amp;', '&'),
                    isSuspended: isSuspended,
                    stats: !isSuspended
                      ? [
                          UserStat(
                            label: 'Reddit age',
                            value: DateTime.fromMillisecondsSinceEpoch((childData['created_utc'] as num).toInt() * 1000, isUtc: true)
                          ),
                          UserStat(
                            label: 'Link karma',
                            value: childData['link_karma']
                          ),
                          UserStat(
                            label: 'Comment karma',
                            value: childData['comment_karma']
                          )
                        ]
                      : null
                  );
                }).toList(),
              pageToken: data['after'],
            );
          },
          responseBody
        );
    }
    final (votes, result) = await compute(_parsePosts, responseBody);
    votes.forEach((postId, vote) => Votes.posts.setVote(postId, vote));
    return result;
  }

  @override
  Future<void> vote(String id, bool? up) {
    // debugPrint('[Reddit] upvote: id=$id, up=$up');
    return _post(
      '/api/vote',
      {
        // 'api_type': 'json',
        'id': id,
        'dir': switch (up) {
          true => '1',
          false => '-1',
          null => '0',
        }
      }
    );
  }

  (bool?, Post) _parsePost(Map<String, dynamic> json) {
    final data = json['data'];
    final author = data['author'];
    String? thumbnail = data['thumbnail'];
    if (thumbnail != null) {
      if (thumbnail == '' || thumbnail == 'self' || thumbnail == 'default' || thumbnail == 'nsfw' || thumbnail == 'image') {
        thumbnail = null;
      }
      else if (thumbnail.startsWith('http')) {
        thumbnail = thumbnail.replaceAll('&amp;', '&');
      }
    }

    String? textHtml = data['selftext_html'];
    if (textHtml != null) {
      textHtml = parseFragment(textHtml).text;
    }

    // final secureMedia = data['secure_media'];
    // String? videoUrl;
    // if (secureMedia != null) {
      // final redditVideo = secureMedia['reddit_video'];
      // if (redditVideo != null) {
        // videoUrl = redditVideo['hls_url'].replaceAll('&amp;', '&');
        // videoUrl = redditVideo['dash_url'].replaceAll('&amp;', '&');
        // videoUrl = redditVideo['fallback_url'];
        // videoUrl = (redditVideo['hls_url'] ?? redditVideo['dash_url'] ?? redditVideo['fallback_url']).replaceAll('&amp;', '&');
      // }
    // }

    final List<String> galleryImageUrls = [];
    final bool isGallery = data['is_gallery'] == true;
    final String domain;
    if (isGallery) {
      domain = 'image/gallery';
      final metadata = data['media_metadata'];
      final galleryData = data['gallery_data'];
      if (galleryData != null && galleryData['items'] != null) {
        for (var item in galleryData['items']) {
          final mediaId = item['media_id'];
          final mediaItem = metadata[mediaId];
          if (mediaItem != null && mediaItem['s'] != null) {
            final source = mediaItem['s'];
            String? imageUrl = source['u'] ?? source['gif'];
            if (imageUrl != null) {
              galleryImageUrls.add(imageUrl.replaceAll('&amp;', '&'));
            }
          }
        }
      }
    }
    else {
      domain = (data['domain'] as String).toLowerCase();
    }

    return (
      data['likes'],
      Post(
        community: Community(
          platform: Platform.reddit,
          name: data['subreddit'].toLowerCase()
        ),
        id: data['name'],
        shortId: data['id'],
        permalink: data['permalink'],
        score: data['score'],
        timestampMs: (data['created_utc'] as num).toInt() * 1000,
        title: parse(data['title']).body!.text,
        textHtml: textHtml,
        author: author,
        commentCount: data['num_comments'],
        url: data['url'],
        domain: domain,
        thumbnailUrl: thumbnail,
        isStickied: data['stickied'],
        isSelf: data['is_self'],
        isNsfw: data['over_18'],
        isGallery: isGallery,
        isDeleted: author == '[deleted]',
        galleryImageUrls: galleryImageUrls
      )
    );
  }

  (Map<String, bool?>, PagedResult<Post>) _parsePosts(String body) {
    final Map<String, bool?> votes = {};
    final List<Post> posts = [];
    final json = jsonDecode(body);
    final data = json['data'];
    for (var child in data['children'] as List) {
      final (vote, post) = _parsePost(child);
      votes[post.id] = vote;
      posts.add(post);
    }
    return (
      votes,
      PagedResult(
        items: posts,
        pageToken: data['after']
      )
    );
  }

  (Map<String, bool?>, List<CommentItem>) _parseComments(List<dynamic> json, int depth) {
    final Map<String, bool?> votes = {};
    final List<CommentItem> comments = [];
    for (var child in json) {
      final kind = child['kind'];
      final data = child['data'];
      if (kind == 't1') { 
        final (vote, comment) = _parseCommentFromJson(data, depth);
        votes[comment.id] = vote;
        comments.add(comment);
        if (data['replies'] is Map) {
          final repliesData = data['replies']['data'];
          if (repliesData != null && repliesData['children'] != null) {
            final (childVotes, childItems) = _parseComments(repliesData['children'], depth + 1);
            votes.addAll(childVotes);
            comments.addAll(childItems);
          }
        }
      }
      else if (kind == 'more') {
        if (data['count'] != 0) {
          comments.add(
            LoadMoreComment(
              depth: depth,
              count: data['count']!,
              pageToken: List<String>.from(data['children']!).join(','),
            )
          );
        }
      }
    }
    return (votes, comments);
  }

  (bool?, Comment) _parseCommentFromJson(Map<String, dynamic> data, int depth) {
    final author = data['author'];
    return (
      data['likes'],
      Comment(
        depth: depth,
        platform: Platform.reddit,
        id: data['name'],
        permalink: data['permalink'],
        isDeleted: author == '[deleted]',
        author: author,
        isModerator: data['distinguished'] == 'moderator',
        isSubmitter: data['is_submitter'] ?? false,
        score: data['score_hidden'] ? null : data['score'],
        timestampMs: (data['created_utc'] as num).toInt() * 1000,
        text: data['body'],
        textHtml: (data['body_html'] as String).replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&amp;', '&'),
        postTitle: data['link_title'],
        communityName: (data['subreddit'] as String).toLowerCase()
      )
    );
  
  }

}

class _ParsedIds<T> {
  
  final List<String>? postIds;
  final List<String>? commentIds;
  final PagedResult<T>? result;

  _ParsedIds({
    required this.postIds,
    required this.commentIds,
    required this.result
  });

}
