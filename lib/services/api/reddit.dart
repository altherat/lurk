import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' show Element;
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/posts.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';

class RedditApi extends Api {

  static const baseUrl = 'https://reddit.com';
  static const baseUrlOld = 'https://old.reddit.com';
  static const headers = {
    'Accept': 'application/json'
  };
    
  @override
  String getPostDetailsUrl(Post post) => '${Settings.copyOldRedditLinks.value ? baseUrlOld : baseUrl}${post.urlPath}';

  @override
  String getCommentUrl(Post post, Comment comment) => '${getPostDetailsUrl(post)}${comment.id}';

  @override
  Future<Posts> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // debugPrint('[Reddit] getPosts: $id, sort=${sort?.label}, timeRange=$timeRange, after=$pageToken');
    final sort = options?[FeedOptionType.sort];
    final timeRange = options?[FeedOptionType.time];
    final subreddit = id ?? Platform.reddit.communityHome;
    String url = '$baseUrl/r/$subreddit/';
    if (sort != null) {
      url += '${sort.apiValue}/';
    }

    final Map<String, dynamic> params = {};
    if (timeRange != null) {
      params['t'] = timeRange.apiValue;
    }
    if (pageToken != null) {
      params['after'] = pageToken;
    }

    Uri uri = Uri.parse('$url.json');
    if (params.isNotEmpty) {
      uri = uri.replace(queryParameters: params);
    }
    return compute(_parsePosts, (await _get(uri)).body);
  }

  @override
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options}) async {
    // debugPrint('[Reddit] getPostDetailsFromUrl: url=$url, sort=$sort');
    final sort = options?[FeedOptionType.sort];
    var uri = Uri.parse(url);
    if (uri.queryParameters['sort'] == null && sort != null) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters, 
          'sort': sort.apiValue,
        },
      );
    }
    if (!uri.path.endsWith('.json')) {
      uri = uri.replace(path: '${uri.path}.json');
    }
    return compute(_parsePostDetails, (await _get(uri)).body);
  }

  @override
  Future<PostDetails> getPostDetailsFromId(String id, {Map<FeedOptionType, FeedOption>? options}) => getPostDetailsFromUrl('$baseUrl/comments/$id', options: options);

  @override
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? level, Map<FeedOptionType, FeedOption>? options}) async {
    final sort = options?[FeedOptionType.sort];
    final uri = Uri.parse('$baseUrlOld/api/morechildren');
    final body = {
      'api_type': 'json',
      'link_id': 't3_$id',
      'children': pageToken,
    };
    if (sort != null) {
      body['sort'] = sort.apiValue;
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
        final Map<String, int> batchLevelCache = {};
        for (var thing in things) {
          final kind = thing['kind'];
          final data = thing['data'];
          final parentId = data['parent'];
          final currentLevel = batchLevelCache.containsKey(parentId) ? batchLevelCache[parentId]! + 1 : level!;
          batchLevelCache[data['id']] = currentLevel;
          if (kind == 't1') {
            items.add(_parseCommentFromHtml(parse(parse(data['content']).body?.text).querySelector('.thing')!, currentLevel));
          }
          else if (kind == 'more') {
            items.add(_parseLoadMoreCommentFromHtml(parse(parse(data['content']).body?.text).querySelector('.thing')!, currentLevel));
          }
        }
        return items;
      },
      response.body
    );
  }

  Future<Response> _get(Uri uri) {
    return _handleResponse(
      get(
        uri,
        headers: getHeaders(headers)
      )
    );
  }

  Future<Response> _post(Uri uri, Map<String, dynamic> body) {
    return _handleResponse(
      post(
        uri,
        headers: getHeaders(headers),
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

  Posts _parsePosts(String body) {
    final json = jsonDecode(body);
    final data = json['data'];
    final children = data['children'] as List;
    return Posts(
      posts: children
        .where((child) => child['kind'] == 't3')
        .map((child) => _parsePost(child))
        .toList(),
      pageToken: data['after']
    );
  }

  PostDetails _parsePostDetails(String body) {
    final json = jsonDecode(body);
    return PostDetails(
      post: _parsePost(json[0]['data']['children'][0]),
      comments: _parseComments(json[1]['data']['children'] as List, 0),
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

    final secureMedia = data['secure_media'];
    String? videoUrl;
    if (secureMedia != null) {
      final redditVideo = secureMedia['reddit_video'];
      if (redditVideo != null) {
        // videoUrl = redditVideo['hls_url'].replaceAll('&amp;', '&');
        // videoUrl = redditVideo['dash_url'].replaceAll('&amp;', '&');
        videoUrl = redditVideo['fallback_url'];
        // videoUrl = (redditVideo['hls_url'] ?? redditVideo['dash_url'] ?? redditVideo['fallback_url']).replaceAll('&amp;', '&');
      }
    }

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
      domain = data['domain'];
    }

    return Post(
      id: data['id'],
      score: data['score'],
      timestampMs: (data['created_utc'] as num).toInt() * 1000,
      title: parse(data['title']).body!.text,
      textHtml: textHtml,
      author: author,
      commentCount: data['num_comments'],
      url: videoUrl ?? data['url'],
      urlPath: data['permalink'],
      domain: domain,
      communityName: data['subreddit'].toLowerCase(),
      thumbnailUrl: thumbnail,
      isStickied: data['stickied'],
      isSelf: data['is_self'],
      isNsfw: data['over_18'],
      isGallery: isGallery,
      isDeleted: author == '[deleted]',
      galleryImageUrls: galleryImageUrls
    );
  }

  List<CommentItem> _parseComments(List<dynamic> json, int level) {
    List<CommentItem> items = [];
    for (var child in json) {
      final kind = child['kind'];
      final data = child['data'];
      if (kind == 't1') { 
        items.add(_parseCommentFromJson(data, level));
        if (data['replies'] is Map) {
          final repliesData = data['replies']['data'];
          if (repliesData != null && repliesData['children'] != null) {
            items.addAll(_parseComments(repliesData['children'], level + 1));
          }
        }
      }
      else if (kind == 'more') {
        if (data['count'] != 0) {
          items.add(_parseLoadMoreCommentFromJson(data, level));
        }
      }
    }
    return items;
  }

  Comment _parseCommentFromJson(Map<String, dynamic> data, int level) {
    final author = data['author'];
    return Comment(
      level: level,
      id: data['id'],
      isDeleted: author == '[deleted]',
      author: author,
      isModerator: data['distinguished'] == 'moderator',
      isSubmitter: data['is_submitter'] ?? false,
      score: data['score_hidden'] ? null : data['score'],
      timestampMs: ((data['created_utc'] ?? 0) as num).toInt() * 1000,
      text: data['body'],
      textHtml: data['body_html'].replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&amp;', '&'),
    );
  }

  Comment _parseCommentFromHtml(Element element, int level) {
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
      level: level,
      id: element.attributes['data-fullname']!,
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

  LoadMoreComment _parseLoadMoreCommentFromJson(Map<String, dynamic> data, int level) {
    return LoadMoreComment(
      level: level,
      count: data['count']!,
      pageToken: List<String>.from(data['children']!).join(','),
    );
  }

  LoadMoreComment _parseLoadMoreCommentFromHtml(Element element, int level) {
    final moreLink = element.querySelector('.morecomments a');
    final countMatch = RegExp(r'(\d+)').firstMatch(moreLink!.text.trim());
    final idMatch = RegExp(r"morechildren\(.*?\s*'.*?'\s*,\s*'.*?'\s*,\s*'(.*?)'").firstMatch(moreLink.attributes['onclick']!);
    return LoadMoreComment(
      level: level,
      count: int.tryParse(countMatch!.group(1)!)!,
      pageToken: idMatch!.group(1)!
    );
  }

  // List<Post> _postsFromHtml(String html) {
  //   return parse(html)
  //     .querySelectorAll('div.thing.link')
  //     .where((element) => !element.classes.contains('promoted'))
  //     .map((element) => Post._fromElement(element))
  //     .toList();
  // }

  // Post _postFromElement(Element element) {
  //   String url = element.attributes['data-url']!;
  //   String? thumbnailUrl = element.querySelector('img.thumbnail')?.attributes['src'] ?? element.querySelector('a.thumbnail img')?.attributes['src'];
  //   if (thumbnailUrl != null && thumbnailUrl.startsWith('//')) {
  //     thumbnailUrl = 'https:$thumbnailUrl';
  //   }

  //   List<String> galleryImageUrls = [];
  //   String? textHtml;

  //   final expando = element.querySelector('div.expando');
  //   final cachedHtml = expando?.attributes['data-cachedhtml'];

  //   if (cachedHtml != null) {
  //     DocumentFragment fragment = parseFragment(parse(cachedHtml).body!.text);
  //     final anchors = fragment.querySelectorAll('a.gallery-item-thumbnail-link');
  //     for (var a in anchors) {
  //       String? href = a.attributes['href'];
  //       if (href != null) {
  //         galleryImageUrls.add(href.replaceAll('&amp;', '&'));
  //       }
  //     }
  //     final userTextDiv = fragment.querySelector('.usertext-body .md');
  //     if (userTextDiv != null) {
  //       textHtml = userTextDiv.innerHtml; 
  //     }
  //   }

  //   return Post(
  //     id: element.attributes['data-fullname']!,
  //     score: int.tryParse(element.attributes['data-score']!)!,
  //     timestampMs: int.tryParse(element.attributes['data-timestamp']!)!,
  //     title: element.querySelector('a.title')!.text,
  //     textHtml: textHtml,
  //     author: element.attributes['data-author']!,
  //     commentCount: int.tryParse(element.attributes['data-comments-count']!)!,
  //     url: url,
  //     permalink: element.attributes['data-permalink']!,
  //     domain: url.contains('gallery') ? 'reddit/gallery' : element.attributes['data-domain']!,
  //     subreddit: element.attributes['data-subreddit']!,
  //     thumbnailUrl: thumbnailUrl,
  //     isStickied: element.classes.contains('stickied'),
  //     isNsfw: element.attributes['data-nsfw']! == 'true',
  //     galleryImageUrls: galleryImageUrls
  //   );
  // }

}
