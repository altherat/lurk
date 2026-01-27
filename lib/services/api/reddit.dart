import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' show Element;
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';

class RedditApi extends Api {

  static const _host = 'reddit.com';
  static const _baseUrl = 'https://$_host';
  static const _baseUrlOld = 'https://old.$_host';

  const RedditApi() : super(const {'Accept': 'application/json'});

  @override
  String get defaultUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:0.1.0 (by @altherat)';

  @override
  String get baseUrl => Settings.redditCopyOldRedditLinks.value ? _baseUrlOld : _baseUrl;

  @override
  Future<PagedResult<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // debugPrint('[Reddit] getPosts: $id, sort=${sort?.label}, timeRange=$timeRange, after=$pageToken');
    final sort = options?[FeedOptionType.sort];
    final timeRange = options?[FeedOptionType.time];
    final subreddit = id ?? Platform.reddit.communityHome;
    String url = '$_baseUrl/r/$subreddit/';
    if (sort != null) {
      url += '${sort.id}/';
    }

    final Map<String, dynamic> params = {};
    if (timeRange != null) {
      params['t'] = timeRange.id;
    }
    if (pageToken != null) {
      params['after'] = pageToken;
    }

    Uri uri = Uri.parse('$url.json');
    if (params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    return compute(_parsePostsResult, (await _get(uri)).body);
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
    final queryParams = {
      if (sort != null) 'sort': sort.id,
    };
    if (commentId != null) {
      segments.addAll(['comment', commentId]);
      queryParams['context'] = '3';
    }
    final uri = Uri.https(_host, '${segments.join('/')}.json', queryParams);
    return compute(_parsePostDetails, ((await _get(uri)).body, commentId));
  }

  @override
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) async {
    // debugPrint('[Reddit] getPostDetailsFromUrl: id=$id, pageToken=$pageToken, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final sort = options?[FeedOptionType.sort];
    final uri = Uri.parse('$_baseUrlOld/api/morechildren');
    final body = {
      'api_type': 'json',
      'link_id': 't3_$id',
      'children': pageToken,
    };
    if (sort != null) {
      body['sort'] = sort.id;
    }
    final response = await _post(
      uri,
      body
    );
    return compute(
      (String body) {
        final Map<String, dynamic> jsonResponse = jsonDecode(body);
        final List<dynamic> things = jsonResponse['json']?['data']?['things'] ?? [];
        final List<CommentItem> items = [];
        final Map<String, int> batchDepthCache = {};
        for (var thing in things) {
          final kind = thing['kind'];
          final data = thing['data'];
          final parentId = data['parent'];
          final currentDepth = batchDepthCache.containsKey(parentId) ? batchDepthCache[parentId]! + 1 : depth!;
          batchDepthCache[data['id']] = currentDepth;
          if (kind == 't1') {
            items.add(_parseCommentFromHtml(parse(parse(data['content']).body?.text).querySelector('.thing')!, currentDepth));
          }
          else if (kind == 'more') {
            items.add(_parseLoadMoreCommentFromHtml(parse(parse(data['content']).body?.text).querySelector('.thing')!, currentDepth));
          }
        }
        return items;
      },
      response.body
    );
  }

  @override
  UserDetailsResponse getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options}) {
    // debugPrint('[Reddit] getUserDetails: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}]');
    return UserDetailsResponse(
      stats: _get(Uri.parse('$_baseUrl/u/$id/about.json')).then((response) => _parseUserStats(response.body)),
      items: getUserItems(id, options: options)
    );
  }

  @override
  Future<PagedResult<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // debugPrint('[Reddit] getUserItems: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final FeedOption? type = options?[FeedOptionType.type];
    final FeedOption? sort = options?[FeedOptionType.sort];
    final FeedOption? timeRange = options?[FeedOptionType.time];
    String url = '$_baseUrl/u/$id/';
    if (type != null) {
      if (type.id == UserFeedType.posts) {
        url += 'submitted';
      }
      else if (type.id == UserFeedType.comments) {
        url += 'comments';
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

    Uri uri = Uri.parse('$url.json');
    if (params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    return compute(_parseUserItemsResult, (await _get(uri)).body);
  }

  @override
  Future<PagedResult<dynamic>> search(String query, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    debugPrint('[Reddit] search: query=$query, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final type = options?[FeedOptionType.type];
    final sort = options?[FeedOptionType.sort];
    final timeRange = options?[FeedOptionType.time];
    final Map<String, dynamic> params = {
      'q': query,
    };
    final PagedResult<dynamic> Function(String) parseFn;
    if (type != null) {
      switch (type.id) {
        case SearchFeedType.communities:
          params['type'] = 'sr';
          parseFn = _parseSubredditsResult;
          break;
        case SearchFeedType.users:
          params['type'] = 'user';
          parseFn = _parseUsersResult;
          break;
        default:
          parseFn = _parsePostsResult;
      }
    }
    else {
      parseFn = _parsePostsResult;
    }
    if (sort != null) {
      params['sort'] = sort.id;
    }
    if (timeRange != null) {
      params['t'] = timeRange.id;
    }
    if (pageToken != null) {
      params['after'] = pageToken;
    }
    final uri = Uri.parse('$_baseUrl/search.json').replace(queryParameters: params);
    return compute(parseFn, (await _get(uri)).body);
  }

  Future<Response> _get(Uri uri) {
    return _handleResponse(
      get(
        uri,
        headers: headers
      )
    );
  }

  Future<Response> _post(Uri uri, Map<String, dynamic> body) {
    return _handleResponse(
      post(
        uri,
        headers: headers,
        body: body
      )
    );
  }
  
  Future<Response> _handleResponse(Future<Response> futureResponse) async {
    final Response response = await futureResponse;
    if (response.statusCode != 200) {
      throw Exception('HTTP error ${response.statusCode}');
    }
    return response;
  }

  PagedResult<Post> _parsePostsResult(String body) {
    final json = jsonDecode(body);
    final data = json['data'];
    final children = data['children'] as List;
    return PagedResult(
      items: children
        .where((child) => child['kind'] == 't3')
        .map((child) => _parsePost(child))
        .toList(),
      pageToken: data['after']
    );
  }

  PagedResult<Community> _parseSubredditsResult(String body) {
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
  }

  PagedResult<User> _parseUsersResult(String body) {
    final json = jsonDecode(body);
    final data = json['data'];
    final children = data['children'] as List;

    return PagedResult(
      items: children
        .map((child) {
          final childData = child['data'];
          final bool isSuspended = childData['is_suspended'] ?? false;
          debugPrint(childData.toString());
          return User(
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
        })
          .toList(),
      pageToken: data['after'],
    );
  }

  PostDetails _parsePostDetails((String, String?) args) {
    final (body, contextCommentId) = args;
    final json = jsonDecode(body);
    return PostDetails(
      post: _parsePost(json[0]['data']['children'][0]),
      comments: _parseComments(json[1]['data']['children'] as List, 0),
      contextCommentId: contextCommentId
    );
  }

  Post _parsePost(Map<String, dynamic> json) {
    final data = json['data'];
    final author = data['author'];
    String? thumbnail = data['thumbnail'];
    if (thumbnail != null) {
      if (thumbnail == '' || thumbnail == 'self' || thumbnail == 'default' || thumbnail == 'nsfw' || thumbnail == 'image') {
        thumbnail = null;
      }
      else if (thumbnail!.startsWith('http')) {
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

    return Post(
      community: Community(
        platform: Platform.reddit,
        name: data['subreddit'].toLowerCase()
      ),
      id: data['id'],
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
    );
  }

  List<CommentItem> _parseComments(List<dynamic> json, int depth) {
    List<CommentItem> items = [];
    for (var child in json) {
      final kind = child['kind'];
      final data = child['data'];
      if (kind == 't1') { 
        items.add(_parseCommentFromJson(data, depth));
        if (data['replies'] is Map) {
          final repliesData = data['replies']['data'];
          if (repliesData != null && repliesData['children'] != null) {
            items.addAll(_parseComments(repliesData['children'], depth + 1));
          }
        }
      }
      else if (kind == 'more') {
        if (data['count'] != 0) {
          items.add(_parseLoadMoreCommentFromJson(data, depth));
        }
      }
    }
    return items;
  }

  Comment _parseCommentFromJson(Map<String, dynamic> data, int depth) {
    final author = data['author'];
    return Comment(
      depth: depth,
      platform: Platform.reddit,
      id: data['id'],
      permalink: data['permalink'],
      isDeleted: author == '[deleted]',
      author: author,
      isModerator: data['distinguished'] == 'moderator',
      isSubmitter: data['is_submitter'] ?? false,
      score: data['score_hidden'] ? null : data['score'],
      timestampMs: ((data['created_utc'] ?? 0) as num).toInt() * 1000,
      text: data['body'],
      textHtml: data['body_html'].replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&amp;', '&'),
      postTitle: data['link_title'],
      communityName: data['subreddit']?.toLowerCase()
    );
  }

  Comment _parseCommentFromHtml(Element element, int depth) {
    final entry = element.querySelector('.entry');
    final authorElement = entry?.querySelector('.author');
    final author = authorElement?.text;
    final scoreTitle = entry?.querySelector('.tagline .score.unvoted')?.attributes['title'];
    final textHtml = entry?.querySelector('.usertext-body .md');
    final score = scoreTitle == null ? null : int.tryParse(scoreTitle);
    final dateTimeString = entry?.querySelector('.tagline time')?.attributes['datetime'];
    int timestampMs = 0;
    if (dateTimeString != null) {
      timestampMs = DateTime.tryParse(dateTimeString)?.millisecondsSinceEpoch ?? 0;
    }
    return Comment(
      depth: depth,
      platform: Platform.digg,
      id: element.attributes['data-fullname']!,
      permalink: element.attributes['data-permalink']!,
      isDeleted: author == '[deleted]',
      author: author,
      isModerator: authorElement?.classes.contains('moderator') ?? false,
      isSubmitter: authorElement?.classes.contains('submitter') ?? false,
      score: score,
      timestampMs: timestampMs,
      text: textHtml!.text,
      textHtml: textHtml.innerHtml.trim(),
    );
  }

  LoadMoreComment _parseLoadMoreCommentFromJson(Map<String, dynamic> data, int depth) {
    return LoadMoreComment(
      depth: depth,
      count: data['count']!,
      pageToken: List<String>.from(data['children']!).join(','),
    );
  }

  LoadMoreComment _parseLoadMoreCommentFromHtml(Element element, int depth) {
    final moreLink = element.querySelector('.morecomments a');
    final countMatch = RegExp(r'(\d+)').firstMatch(moreLink!.text.trim());
    final idMatch = RegExp(r"morechildren\(.*?\s*'.*?'\s*,\s*'.*?'\s*,\s*'(.*?)'").firstMatch(moreLink.attributes['onclick']!);
    return LoadMoreComment(
      depth: depth,
      count: int.tryParse(countMatch!.group(1)!)!,
      pageToken: idMatch!.group(1)!
    );
  }

  List<UserStat> _parseUserStats(String body) {
    final data = jsonDecode(body)['data'];
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
  }

  PagedResult<dynamic> _parseUserItemsResult(String body) {
    final json = jsonDecode(body);
    final data = json['data'];
    final children = data['children'] as List;
    return PagedResult(
      items: children.map((child) {
        final String kind = child['kind'];
        final Map<String, dynamic> childData = child['data'];

        if (kind == 't3') {
          return _parsePost(child);
        } else if (kind == 't1') {
          return _parseCommentFromJson(childData, 0);
        }
        return null;
      }).toList(),
      pageToken: data['after']
    );
  }

}
