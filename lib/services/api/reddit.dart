import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' as io;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/services/votes.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/interfaces.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

class RedditApi extends Api {

  static const _domain = 'www.reddit.com';
  static const _oauthDomain = 'oauth.reddit.com';
  static const _baseUrl = 'https://www.reddit.com';
  static const _baseUrlOld = 'https://old.reddit.com';
  static const _oauthScopes = ['edit', 'history', 'identity', 'mysubreddits', 'read', 'subscribe', 'submit', 'vote'];
  static const _defaultUnauthenticatedUserAgent = 'Mozilla/5.0 (Linux; Android 14; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Mobile Safari/537.36';
  static const _defaultUnauthenticatedHeaders = {
    'User-Agent': _defaultUnauthenticatedUserAgent,
    'Referer': 'https://www.reddit.com/',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Ch-Ua': '"Chromium";v="144", "Not/A)Brand";v="24", "Google Chrome";v="144"',
    'Sec-Ch-Ua-Mobile': '?1',
    'Sec-Ch-Ua-Platform': '"Android"',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1'
  };
  static const _defaultAuthenticatedHeaders = {
    'Accept': 'application/json'
  };
  
  static final Map<String?, _AuthClientHelper> _authClientHelpers = {};

  const RedditApi();

  @override
  bool get hasLogin => true;

  @override
  String get defaultUnauthenticatedUserAgent => _defaultUnauthenticatedUserAgent;
  // String get defaultUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:0.1.0 (by /u/altherat)';

  Map<String, String> get authenticatedHeaders => {
    ..._defaultAuthenticatedHeaders,
    'User-Agent': savedOrDefaultUserAgent
  };

  Future<Response> _get(String path, {Map<String, dynamic>? params}) async {
    dev.log('[Reddit] _get: path=$path, params=$params]');
    return _handleResponse(_getClientHelper().get(path, params));
  }

  Future<Response> _post(String path, dynamic body) async {
    dev.log('[Reddit] _post: path=$path, params=$body]');
    return _handleResponse(_getClientHelper().post(path, body));
  }

  Future<Response> _handleResponse(Future<Response> response) async {
    final awaited = await response;
    dev.log('[Reddit] Rate limit headers:');
    for (var headerEntry in awaited.headers.entries) {
      // dev.log('[Reddit] ${headerEntry.key}: ${headerEntry.value}');
      if (headerEntry.key.startsWith('x-ratelimit-')) {
        dev.log('[Reddit]\t${headerEntry.key}: ${headerEntry.value}');
      }
    }
    return awaited;
  }

  _ClientHelper _getClientHelper() {
    final clientId = Settings.redditClientId.value;
    if (clientId == null) {
      for (var helper in _authClientHelpers.values) {
        helper.dispose();
      }
      _authClientHelpers.clear();
      return _HttpClientHelper();
    }
    for (var helper in _authClientHelpers.values) {
      helper.ensureClientId(clientId);
    }
    final activeUserId = Settings.activeUser.value?.id;
    return _authClientHelpers[activeUserId] ??= _AuthClientHelper(clientId, activeUserId, () => savedOrDefaultUserAgent);
  }

  @override
  String get baseUrl => Settings.redditCopyOldRedditLinks.value ? _baseUrlOld : _baseUrl;

  @override
  Future<PagedItems<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // dev.log('[Reddit] getPosts: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final sort = options?[FeedOptionType.sort];
    final timeRange = options?[FeedOptionType.time];
    String path = id != null && id.isNotEmpty ? '/r/$id/' : '/';
    if (sort != null) {
      path += '${sort.id}/';
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
    // dev.log('[Reddit] getPostDetailsFromUrl: url=$url, options=[${options?.values.map((option) => option.id).join(', ')}]');
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
    return getPostDetailsFromId(pathSegments[3], shortCommentId: commentId, options: options);
  }

  @override
  Future<PostDetails> getPostDetailsFromId(String id, {String? shortCommentId, Map<FeedOptionType, FeedOption>? options}) async {
    // dev.log('[Reddit] getPostDetailsFromId: id=$id, commentId=$shortCommentId, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final sort = options?[FeedOptionType.sort];
    final segments = ['comments', id];
    final params = {
      if (sort != null)
        'sort': sort.id,
    };
    if (shortCommentId != null) {
      segments.addAll(['comment', shortCommentId]);
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
            contextCommentShortId: contextCommentId
          )
        );
      },
      ((await _get('/${segments.join('/')}.json', params: params)).body, shortCommentId)
    );
    Votes.posts.setVote(postDetails.post.id, postVote);
    commentVotes.forEach((commentId, vote) => Votes.comments.setVote(commentId, vote));
    return postDetails;
  }

  @override
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) async {
    // dev.log('[Reddit] getPostDetailsFromUrl: id=$id, pageToken=$pageToken, options=[${options?.values.map((option) => option.id).join(', ')}]');
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
    final clientHelper = _getClientHelper();
    if (clientHelper is _HttpClientHelper) {
      response = clientHelper.post('/api/morechildren', body);
      parseFn = (String body) {
        final Map<String, dynamic> jsonResponse = jsonDecode(body);
        final List<dynamic> things = jsonResponse['json']['data']['things'];
        final Map<String, bool?> votes = {};
        final List<CommentItem> items = [];
        final Map<String, int> batchDepthCache = {};
        for (var thing in things) {
          final kind = thing['kind'];
          final data = thing['data'];
          final String id = data['id'];
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
                id: id,
                shortId: id.split('_').last,
                permalink: element.attributes['data-permalink']!,
                isDeleted: author == '[deleted]',
                authorId: element.attributes['data-author-fullname'],
                authorName: author,
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
    else {
      response = clientHelper.post('/api/morechildren', body);
      parseFn = (String body) {
        final Map<String, dynamic> jsonResponse = jsonDecode(body);
        final List<dynamic> things = jsonResponse['json']['data']['things'];
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
    final (votes, items) = await compute(parseFn, (await response).body);
    votes.forEach((commentId, vote) => Votes.comments.setVote(commentId, vote));
    return items;
  }

  @override
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options}) {
    dev.log('[Reddit] getUserDetails: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}]');
    return MultiPartFeedResponse(
      items: getUserItems(id, options: options),
      other: _get('/user/$id/about.json').then((response) {
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
    );
  }

  @override
  Future<PagedItems<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    dev.log('[Reddit] getUserItems: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final FeedOption? type = options?[FeedOptionType.category];
    final FeedOption? sort = options?[FeedOptionType.sort];
    final FeedOption? timeRange = options?[FeedOptionType.time];
    String path = '/user/$id';
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
          PagedItems(
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
  Future<PagedItems<dynamic>> search(String query, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // dev.log('[Reddit] search: query=$query, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final type = options?[FeedOptionType.category]?.id;
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
            if (json is String) {
              return PagedItems(items: [], pageToken: null);
            }
            final data = json['data'];
            final children = data['children'] as List;
            return PagedItems(
              items: children
                  .map((child) {
                    final Map<String, dynamic> childData = child['data'];
                    final String description = childData['public_description'];
                    final String iconUrl = childData['community_icon'];
                    return Community(
                      platform: Platform.reddit,
                      name: (childData['display_name'] as String).toLowerCase(),
                      description: description.isNotEmpty ? description : null,
                      iconUrl: iconUrl.isNotEmpty ? Uri.parse(iconUrl).replace(queryParameters: {}).toString() : null,
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
            debugPrint("body: $body");
            final json = jsonDecode(body);
            if (json is! Map<String, dynamic>) {
              return PagedItems(items: [], pageToken: null);
            }
            debugPrint('test: $json');
            final data = json['data'];
            final children = data['children'] as List;

            return PagedItems(
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
                            label: 'Karma',
                            value: childData['link_karma'] + childData['comment_karma']
                          ),
                          // UserStat(
                          //   label: 'Link karma',
                          //   value: childData['link_karma']
                          // ),
                          // UserStat(
                          //   label: 'Comment karma',
                          //   value: childData['comment_karma']
                          // )
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
  Future<String?> login() async {
    final clientId = Settings.redditClientId.value!;
    final helper = _authClientHelpers[null] ??= _AuthClientHelper(clientId, null, () => savedOrDefaultUserAgent);
    if (await helper.fetchToken()) {
      final user = _parseLoggedInUser((await helper.get('/api/v1/me', null)).body);
      if (Settings.loggedInUsers.value.any((u) => u.id == user.id)) {
        return null;
      }
      await helper.updateTokenStorageKey(clientId, user.id);
      _authClientHelpers[user.id] = helper;
      _authClientHelpers.remove(null);
      Settings.loggedInUsers.add(user);
      Settings.activeUser.value = user;
      final subscribedCommunityNames = await getSubscribedCommunityNames();
      Settings.communities.addAll(
        subscribedCommunityNames.map((name) {
          return Community(
            platform: Platform.reddit,
            name: name
          );
        })
      );
      return user.name;
    }
    return null;
  }

  @override
  Future<void> logout(String id) async {
    // dev.log('[Reddit] logout: id=$id');
    final helper = _authClientHelpers.remove(id);
    if (helper != null) {
      helper.dispose();
    }
    else {
      await TokenStorage(id).deleteAllTokens();
    }
  }

  @override
  Future<LoggedInUser> getLoggedInUser() async => compute(_parseLoggedInUser, (await _get('/api/v1/me')).body);
  
  @override
  Future<List<String>> getSubscribedCommunityNames() async {
    List<String> communityNames = [];
    String? after;
    try {
      do {
        final response = await _get(
          '/subreddits/mine/subscriber.json',
            params: {
              'limit': '100',
              if (after != null)
                'after': after,
            }
        );
        final data = jsonDecode(response.body)['data'];
        for (var child in data['children']) {
          communityNames.add((child['data']['display_name'] as String).toLowerCase());
        }
        after = data['after'];
      }
      while (after != null);
    }
    catch (e) {
      dev.log('Error fetching subscriptions: $e');
    }
    return communityNames;
  }

  @override
  Future<void> vote(String id, bool? up) {
    // dev.log('[Reddit] upvote: id=$id, up=$up');
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

  @override
  Future<void> postComment(String id, String text) {
    // dev.log('[Reddit] postcomment: id=$id, text=$text');
    return _post(
      '/api/comment',
      {
        'api_type': 'json',
        'thing_id': id,
        'text': text
      }
    );
  }

  @override
  Future<void> deleteComment(String id) {
    // dev.log('[Reddit] deleteComment: id=$id');
    return _post(
      '/api/del',
      {
        'id': id,
      }
    );
  }

  @override
  Future<void> unsubscribe(String id) {
    // dev.log('[Reddit] unsubscribe: id=$id');
    return _post(
      '/api/subscribe?action=unsub',
      {
        'id': id,
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

  (Map<String, bool?>, PagedItems<Post>) _parsePosts(String body) {
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
      PagedItems(
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
        shortId: data['id'],
        permalink: data['permalink'],
        isDeleted: author == '[deleted]',
        authorId: data['author_fullname'],
        authorName: author,
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
  
  LoggedInUser _parseLoggedInUser(String body) {
    final data = jsonDecode(body);
    final iconUri = Uri.parse(data['icon_img']);
    return LoggedInUser(
      platform: Platform.reddit,
      id: 't2_${data['id']}',
      name: data['name'],
      iconUrl: Uri(scheme: iconUri.scheme,host: iconUri.host,path: iconUri.path).toString(),
      inboxCount: data['inbox_count'],
      score: data['link_karma'] + data['comment_karma']
    );
  }

}

abstract class _ClientHelper {

  Future<Response> get(String path, Map<String, dynamic>? params);

  Future<Response> post(String path, dynamic body);

  void dispose() {

  }
  
}

class _HttpClientHelper extends _ClientHelper {

  static http.Client? _clientInstance;
  static Map<String, Cookie>? _cookies;
  static Future<void>? _initCookiesFuture;

  @override
  Future<Response> get(String path, Map<String, dynamic>? params) async {
    return _request((client) async {
      return client.get(
        Uri.https(RedditApi._domain, path, params),
        headers: await _headers
      );
    });
  }

  @override
  Future<Response> post(String path, dynamic body) async {
    return _request((client) async {
      return client.post(
        Uri.https(RedditApi._domain, path),
        headers: await _headers,
        body: body
      );
    });
  }

  @override
  void dispose() {
    if (_clientInstance != null) {
      _clientInstance!.close();
      _clientInstance = null;
    }
    _cookies = null;
    _initCookiesFuture = null;
  }

  Future<Response> _request(Future<Response> Function(http.Client client) request) async {
    final client = _clientInstance ??= http.Client();
    Response response = await request(client);
    dev.log('[Reddit][HttpClientHelper] response code: ${response.statusCode}');
    if (response.headers.containsKey('set-cookie')) {
      await _updateCookiesFromHeaders(response.headers['set-cookie']!);
      if (response.statusCode == 403) {
        dev.log('[Reddit][HttpClientHelper] Status code 403 detected. Attempting HTML warm-up...');
        final warmUp = await client.get(
          Uri.parse(RedditApi._baseUrl), 
          headers: {
            'Upgrade-Insecure-Requests': '1',
            'User-Agent': RedditApi._defaultUnauthenticatedUserAgent
          },
        );
        if (warmUp.headers.containsKey('set-cookie')) {
          await _updateCookiesFromHeaders(warmUp.headers['set-cookie']!);
          dev.log('[Reddit][HttpClientHelper] Warm-up complete. Retrying original request...');
          response = await request(client);
        }
      }
    }
    return response;
  }

  Future<Map<String, String>> get _headers async {
    final headers = Map.of(RedditApi._defaultUnauthenticatedHeaders);
    await (_initCookiesFuture ??= _initCookies());
    if (_cookies!.isNotEmpty) {
      final DateTime now = DateTime.now();
      final List<String> expiredKeys = [];
      _cookies!.removeWhere((key, cookie) {
        final isExpired = cookie.expirationTime?.isBefore(now) ?? false;
        if (isExpired) {
          expiredKeys.add(key);
        }
        return isExpired;
      });
      if (expiredKeys.isNotEmpty) {
        Database.instance.deleteCookies(expiredKeys);
      }
      if (_cookies!.isNotEmpty) {
        headers['Cookie'] = _cookies!.values.map((c) => '${c.key}=${c.value}').join('; ');
      }
    }
    dev.log('[Reddit][HttpClientHelper] Cookie headers: ${_cookies!.length}');
    return headers;
  }

  Future<void> _initCookies() async {
    _cookies = {
      for (var cookie in await Database.instance.getAllValidCookies())
        cookie.key: cookie
    };
  }

  Future<void> _updateCookiesFromHeaders(String headerValue) async {
    final cookieStrings = headerValue.split(RegExp(r'(,)(?=[^;]+?=)'));
    final List<Cookie> cookies = [];
    for (var str in cookieStrings) {
      final ioCookie = io.Cookie.fromSetCookieValue(str);
      final cookie = Cookie(
        key: ioCookie.name,
        value: ioCookie.value,
        expirationTime: ioCookie.expires,
      );
      _cookies![ioCookie.name] = cookie;
      cookies.add(cookie);
      dev.log('[Reddit][HttpClientHelper] Added cookie: key=${cookie.key}, value=${cookie.value}, expirationTime=${cookie.expirationTime}');
    }
    if (cookies.isNotEmpty) {
      await Database.instance.saveCookies(cookies);
    }
  }

}

class _AuthClientHelper extends _ClientHelper {

  OAuth2Helper _oAuthHelper;
  final String Function() _userAgentProvider;
  AccessTokenResponse? _cachedToken;

  _AuthClientHelper(String clientId, String? activeUserId, this._userAgentProvider) : _oAuthHelper = _createOAuth2Helper(clientId, activeUserId == null ? null : TokenStorage(activeUserId));

  @override
  Future<Response> get(String path, Map<String, dynamic>? params) {
    return _request(() {
      return _oAuthHelper.get(
        Uri.https(RedditApi._oauthDomain, path, params).toString(),
        headers: {
          ...RedditApi._defaultAuthenticatedHeaders,
          'User-Agent': _userAgentProvider()
        }
      );
    });
  }

  @override
  Future<Response> post(String path, dynamic body) {
    return _request(() {
      return _oAuthHelper.post(
        Uri.https(RedditApi._oauthDomain, path).toString(),
        headers: {
          ...RedditApi._defaultAuthenticatedHeaders,
          'User-Agent': _userAgentProvider()
        },
        body: body
      );
    });
  }

  @override
  Future<void> dispose() async {
    dev.log('[Reddit][OAuthHelper] Disposing OAuth2Helper');
    await _oAuthHelper.removeAllTokens();
    _cachedToken = null;
  }

  Future<bool> fetchToken() async {
    dev.log('[Reddit][OAuthHelper] fetchToken');
    final tokenResponse = await _oAuthHelper.fetchToken();
    _cachedToken = tokenResponse;
    return tokenResponse.isValid();
  }

  Future<void> ensureClientId(String clientId) async {
    if (_oAuthHelper.clientId != clientId) {
      _oAuthHelper.clientId = clientId;
      await _oAuthHelper.removeAllTokens();
      _cachedToken = null;
    }
  }

  Future<void> updateTokenStorageKey(String clientId, String tokenStorageKey) async {
    dev.log('[Reddit][OAuthHelper] updateTokenStorageKey: clientId=$clientId, tokenStorageKey=$tokenStorageKey, access token=${_debugTokenToString(_cachedToken!.accessToken)}');
    await _oAuthHelper.tokenStorage.deleteAllTokens();
    final tokenStorage = TokenStorage(tokenStorageKey);
    await tokenStorage.addToken(_cachedToken!);
    _oAuthHelper = _createOAuth2Helper(clientId, tokenStorage);
  }
  
  static OAuth2Helper _createOAuth2Helper(String clientId, TokenStorage? tokenStorage) {
    final (redirectUri, customUriScheme) = _redirectUriAndCustomUriScheme;
    dev.log('[Redddit] _createOAuth2Helper: clientId=$clientId, tokenStorage key=${tokenStorage?.key}, redirectUri=$redirectUri, customUriScheme=$customUriScheme');
    return OAuth2Helper(
      OAuth2Client(
        authorizeUrl: 'https://www.reddit.com/api/v1/authorize',
        // authorizeUrl: 'https://www.reddit.com/logout?dest=${Uri.encodeComponent('https://www.reddit.com/api/v1/authorize')}',
        tokenUrl: 'https://www.reddit.com/api/v1/access_token',
        redirectUri: redirectUri,
        customUriScheme: customUriScheme,
      ),
      grantType: OAuth2Helper.authorizationCode,
      clientId: clientId,
      clientSecret: '',
      scopes: RedditApi._oauthScopes,
      authCodeParams: {
        'duration': 'permanent',
        'prompt': 'consent'
      },
      tokenStorage: tokenStorage
    );
  }

  Future<AccessTokenResponse?> _getCachedOrStoredToken() async => _cachedToken ??= await _oAuthHelper.getTokenFromStorage();

  Future<Response> _request(Future<Response> Function() request) async {
    final bool cached = _cachedToken != null;
    final tokenResponse = await _getCachedOrStoredToken();
    dev.log('[Reddit][OAuthHelper] Loaded token: cached=$cached, accessToken=${_debugTokenToString(tokenResponse?.accessToken)}, refreshToken=${_debugTokenToString(tokenResponse?.refreshToken)}');
    if (tokenResponse == null || (!tokenResponse.hasRefreshToken() && tokenResponse.isExpired())) {
      dev.log('[Reddit][OAuthHelper] Fetching access token (${tokenResponse == null ? 'new' : 'expired'})');
      if (Settings.redditDeviceId.value == null) {
        Settings.redditDeviceId.value = List<int>.generate(16, (i) => Random.secure().nextInt(256)).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      }
      final response = await http.post( // Manually get access token with http.Client, because using _oAuthHelper.post() initiates login flow
        Uri.parse('https://www.reddit.com/api/v1/access_token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${_oAuthHelper.clientId}:'))}',
          'User-Agent': _userAgentProvider(),
        },
        body: {
          'grant_type': 'https://oauth.reddit.com/grants/installed_client',
          'device_id': Settings.redditDeviceId.value!,
        }
      );
      final data = jsonDecode(response.body);
      await _oAuthHelper.tokenStorage.addToken(
        AccessTokenResponse.fromMap({
          'access_token': data['access_token'],
          'token_type': 'bearer',
          'expires_in': data['expires_in'],
          'scope': RedditApi._oauthScopes.join(' '),
        })
      );
      dev.log('[Reddit][OAuthHelper] Fetched: access token=${_debugTokenToString(data['access_token'])}');
    }
    final response = await request();
    dev.log('[Reddit][OAuthHelper] Response code: ${response.statusCode}');
    // dev.log('[Reddit][OAuthHelper] Response: ${response.body}');
    return response;
  }

  static (String, String) get _redirectUriAndCustomUriScheme {
    final redirectUri = Settings.redditRedirectUri.value;
    return redirectUri != null ? (redirectUri, redirectUri.split('://')[0]) : ('', 'com.altherat.lurk');
  }

  String _debugTokenToString(String? token) {
    if (token == null) return 'null';
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }

  // Future<void> revokeTokens() async {
  //   final tokenResponse = await _getCachedOrStoredToken();
  //   dev.log('[Reddit][OAuthHelper] Revoking tokens: clientId=${_oAuthHelper.clientId}, refresh token=${_debugTokenToString(tokenResponse?.refreshToken)}, access token=${_debugTokenToString(tokenResponse?.accessToken)}');
  //   if (tokenResponse == null) return;

  //   final authHeader = 'Basic ${base64Encode(utf8.encode('${_oAuthHelper.clientId}:'))}';
  //   Future<void> revoke(String token, String hint) async {
  //     final response = await http.post(
  //       Uri.parse('https://www.reddit.com/api/v1/revoke'),
  //       headers: {
  //         'Authorization': authHeader,
  //         'User-Agent': _userAgentProvider(),
  //       },
  //       body: {
  //         'token': token,
  //         'token_type_hint': hint,
  //       },
  //     );
  //     dev.log('[Reddit][OAuthHelper] Revoked $hint: status code=${response.statusCode}');
  //   }

  //   if (tokenResponse.accessToken != null) {
  //     await revoke(tokenResponse.accessToken!, 'access_token');
  //   }
  //   if (tokenResponse.hasRefreshToken()) {
  //     await revoke(tokenResponse.refreshToken!, 'refresh_token');
  //   }
  // }

}