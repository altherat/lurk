import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' as io;
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/login.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/client_helpers.dart';
import 'package:lurk/services/settings.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/interfaces.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

class RedditApi extends Api<RestClientHelper> {

  static const _oAuthDomain = 'oauth.reddit.com';
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

  const RedditApi();

  @override
  List<LoginField>? get loginFields => const [];

  @override
  String get defaultUnauthenticatedUserAgent => _defaultUnauthenticatedUserAgent;
  // String get defaultUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:0.1.0 (by /u/altherat)';

  @override
  String? get savedUserAgent => Settings.redditUserAgent.value;

  @override
  ClientHelper getClientHelper(String host, String? userId) {
    final clientId = Settings.redditClientId.value;
    if (clientId != null) {
      return _AuthClientHelper(clientId, userId, () => savedOrDefaultUserAgent);
    }
    return _ClientHelper(host);
  }

  String _replaceHtmlEscapedCharacters(String text) => text.replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&amp;', '&');

  @override
  String getBaseUrl(String? communityName) => Settings.redditCopyOldRedditLinks.value ? _baseUrlOld : _baseUrl;

  @override
  Future<CommunityDetails> getCommunityDetails(RestClientHelper clientHelper, String name) async {
    final response = await clientHelper.get('/r/$name/about.json');
    return compute(
      (String body) {
        final data = jsonDecode(body)['data'] as Map<String, dynamic>;
        final String description = data['public_description'];
        final String communityIconUrl = data['community_icon'];
        final String iconUrl = data['icon_img'];
        final String? headerUrl = data['header_img'];
        final String bannerMobileUrl = data['mobile_banner_image']!;
        final String bannerBackgroundUrl = data['banner_background_image']!;
        final String bannerUrl = data['banner_img'];
        final String primaryColor = data['primary_color'];
        final String bannerBackgroundColor = data['banner_background_color'];
        final finalIconUrl = communityIconUrl.isNotEmpty ? communityIconUrl : iconUrl.isNotEmpty ? iconUrl : headerUrl;
        final finalBannerUrl = bannerMobileUrl.isNotEmpty ? bannerMobileUrl : bannerBackgroundUrl.isNotEmpty ? bannerBackgroundUrl : bannerUrl.isNotEmpty ? bannerUrl : null;
        return CommunityDetails(
          community: Community(
            platform: Platform.reddit,
            host: Platform.reddit.host!,
            name: data['display_name'],
            id: data['name'],
          ),
          id: data['name'],
          createdDate: DateTime.fromMillisecondsSinceEpoch((data['created_utc'] as num).toInt() * 1000, isUtc: true),
          title: _replaceHtmlEscapedCharacters(data['title']),
          shortDescription: description.isNotEmpty ? description : null,
          iconUrl: finalIconUrl != null ? _replaceHtmlEscapedCharacters(finalIconUrl) : null,
          bannerUrl: finalBannerUrl != null ? _replaceHtmlEscapedCharacters(finalBannerUrl) : null,
          subscriberCount: data['subscribers'],
          primaryColorHexCode: primaryColor.isNotEmpty ? primaryColor.substring(1) : null,
          bannerBackgroundColorHexCode: bannerBackgroundColor.isNotEmpty ? bannerBackgroundColor.substring(1) : null,
          isSubscribed: data['user_is_subscriber']
        );
      },
      response.body
    );
  }

  @override
  Future<PagedItems<Post>> getCommunityPosts(RestClientHelper clientHelper, String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
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
    return compute(_parsePosts, (await clientHelper.get('$path.json', params)).body);
  }

  @override
  Future<PostDetails> getPostDetailsFromUrl(RestClientHelper clientHelper, String url, {Map<FeedOptionType, FeedOption>? options}) async {
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
    return getPostDetailsFromId(clientHelper, pathSegments[3], shortCommentId: commentId, options: options);
  }

  @override
  Future<PostDetails> getPostDetailsFromId(RestClientHelper clientHelper, String id, {String? shortCommentId, Map<FeedOptionType, FeedOption>? options}) async {
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
    return compute(
      ((String, String?) args) {
        final (body, contextCommentId) = args;
        final json = jsonDecode(body);
        return PostDetails(
          post: _parsePost(json[0]['data']['children'][0]),
          comments: _parseComments(json[1]['data']['children'] as List, 0),
          contextCommentShortId: contextCommentId
        );
      },
      ((await clientHelper.get('/${segments.join('/')}.json', params)).body, shortCommentId)
    );
  }

  @override
  Future<List<CommentItem>> getMoreComments(RestClientHelper clientHelper, String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) async {
    final body = {
      'api_type': 'json',
      'link_id': id,
      'children': pageToken,
      'sort': ?options?[FeedOptionType.sort]?.id.toString()
    };
    final Future<Response> response;
    final List<CommentItem> Function(String) parseFn;
    if (clientHelper is _ClientHelper) {
      response = clientHelper.post('/api/morechildren', body);
      parseFn = (String body) {
        final Map<String, dynamic> jsonResponse = jsonDecode(body);
        final List<dynamic> things = jsonResponse['json']['data']['things'];
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
            items.add(
              Comment(
                depth: currentDepth,
                community: Community(
                  platform: Platform.reddit,
                  host: Platform.reddit.host!,
                  name: element.attributes['data-subreddit'],
                  id: element.attributes['data-subreddit-fullname'],
                ),
                id: id,
                shortId: id.split('_').last,
                permalink: element.attributes['data-permalink']!,
                isDeleted: author == '[deleted]',
                authorId: element.attributes['data-author-fullname'],
                authorName: author,
                authorHost: Platform.reddit.host!,
                isModerator: authorElement?.classes.contains('moderator') ?? false,
                isSubmitter: authorElement?.classes.contains('submitter') ?? false,
                score: scoreTitle == null ? null : int.tryParse(scoreTitle),
                timestampMs: dateTimeString != null ? DateTime.parse(dateTimeString).millisecondsSinceEpoch : 0,
                images: const {},
                text: textHtml!.text,
                textHtml: textHtml.innerHtml.trim(),
                vote: midcol.classes.contains('likes') ? true : midcol.classes.contains('dislikes') ? false : null
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
        return items;
      };
    }
    else {
      response = clientHelper.post('/api/morechildren', body);
      parseFn = (String body) {
        final Map<String, dynamic> jsonResponse = jsonDecode(body);
        final List<dynamic> things = jsonResponse['json']['data']['things'];
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
            items.add(_parseCommentFromJson(data, currentDepth));
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
        return items;
      };
    }
    return compute(parseFn, (await response).body);
  }

  @override
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(RestClientHelper clientHelper, String id, {Map<FeedOptionType, FeedOption>? options}) {
    return MultiPartFeedResponse(
      items: getUserItems(clientHelper, id, options: options),
      other: clientHelper.get('/user/$id/about.json').then((response) {
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
  Future<PagedItems<dynamic>> getUserItems(RestClientHelper clientHelper, String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
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
    
    return compute(
      (String body) {
        final List<dynamic> items = [];
        final json = jsonDecode(body);
        final data = json['data'];
        final children = data['children'] as List;
        for (var child in children) {
          final String kind = child['kind'];
          if (kind == 't3') {
            items.add(_parsePost(child));
          }
          else if (kind == 't1') {
            items.add(_parseCommentFromJson(child['data'], 0));
          }
        }
        return PagedItems(
          items: items,
          pageToken: data['after'],
        );
      },
      (await clientHelper.get('$path.json', params)).body
    );
  }

  @override
  Future<PagedItems<dynamic>> getSearchResults(RestClientHelper clientHelper, String query, String? communityName, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    final type = options?[FeedOptionType.category]?.id;
    final sort = options?[FeedOptionType.sort];
    final timeRange = options?[FeedOptionType.time];
    final Map<String, dynamic> params = {
      'q': query,
      if (sort != null)
        'sort': sort.id,
      if (timeRange != null)
        't': timeRange.id,
      'after': ?pageToken,
    };
    switch (type) {
      case SearchFeedType.communities:
        params['type'] = 'sr';
      case SearchFeedType.users:
        params['type'] = 'user';
    }

    final String path;
    if (communityName != null) {
      path = '/r/$communityName/search';
      params['restrict_sr'] = 'true';
    }
    else {
      path = '/search';
    }

    final responseBody = (await clientHelper.get('$path.json', params)).body;
    switch (type) {
      case SearchFeedType.communities:
        return compute(
          (String body) {
            final json = jsonDecode(body);
            if (json is String) {
              return PagedItems(
                items: [],
                pageToken: null
              );
            }
            final data = json['data'];
            final children = data['children'] as List;
            return PagedItems(
              items: children
                  .map((child) {
                    final Map<String, dynamic> childData = child['data'];
                    final String description = childData['public_description'];
                    final String iconUrl = childData['community_icon'];
                    return CommunityDetails(
                      community: Community(
                        platform: Platform.reddit,
                        host: Platform.reddit.host!,
                        name: childData['display_name'],
                        id: childData['name'],
                      ),
                      shortDescription: description.isNotEmpty ? description : null,
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
            final json = jsonDecode(body);
            if (json is! Map<String, dynamic>) {
              return PagedItems(
                items: [],
                pageToken: null
              );
            }
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
      default:
        return compute(_parsePosts, responseBody);
    }
  }

  @override
  Future<String> resolveGlobalToLocalPostId(RestClientHelper clientHelper, String globalId) {
    throw UnimplementedError();
  }

  @override
  Future<LoggedInUser> getLoggedInUser(RestClientHelper clientHelper) async => compute(_parseLoggedInUser, (await clientHelper.get('/api/v1/me')).body);
  
  @override
  Future<List<Community>> getSubscribedCommunities(RestClientHelper clientHelper) async {
    List<Community> communities = [];
    String? after;
    do {
      final response = await clientHelper.get(
        '/subreddits/mine/subscriber.json',
        {
          'limit': '100',
          'after': ?after,
        },
      );
      final data = jsonDecode(response.body)['data'];
      for (var child in data['children']) {
        final data = child['data'];
        communities.add(
          Community(
            platform: Platform.reddit,
            host: Platform.reddit.host!,
            name: data['display_name'],
            id: data['name']
          )
        );
      }
      after = data['after'];
    }
    while (after != null);
    return communities;
  }

  @override
  Future<void> subscribeToCommunity(RestClientHelper clientHelper, String id) => _updateSubscription(clientHelper, id, 'sub');

  @override
  Future<void> unsubscribeFromCommunity(RestClientHelper clientHelper, String id) => _updateSubscription(clientHelper, id, 'unsub');

  @override
  Future<void> votePost(RestClientHelper clientHelper, String id, bool? up) => _vote(clientHelper, id, up);

  @override
  Future<void> voteComment(RestClientHelper clientHelper, String id, bool? up) => _vote(clientHelper, id, up);

  @override
  Future<Comment> postComment(RestClientHelper clientHelper, String parentId, String text) async {
    final response = await clientHelper.post(
      '/api/comment',
      {
        'api_type': 'json',
        'thing_id': parentId,
        'text': text
      },
    );
    return _parseCommentFromJson(jsonDecode(response.body)['json']['data']['things'][0]['data'], -1);
  }

  @override
  Future<void> deleteComment(RestClientHelper clientHelper, String commentId) => clientHelper.post('/api/del', {'id': commentId});

  Future<void> _vote(RestClientHelper clientHelper, String id, bool? up) {
    return clientHelper.post(
      '/api/vote',
      {
        'id': id,
        'dir': switch (up) {
          true => '1',
          false => '-1',
          null => '0',
        }
      },
    );
  }

  Future<void> _updateSubscription(RestClientHelper clientHelper, String id, String action) {
    return clientHelper.post(
      '/api/subscribe',
      {
        'action': action,
        'sr': id,
      },
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

    Size? mediaSize;
    final media = data['media'];
    if (media != null) {
      final video = media['reddit_video'];
      if (video != null) {
        mediaSize = Size((video['width'] as num).toDouble(), (video['height'] as num).toDouble());
      }
    }
    else {
      final preview = data['preview'];
      if (preview != null) {
        final List images = preview['images'];
        if (images.isNotEmpty) {
          final source = images[0]['source'];
          mediaSize = Size(
            (source['width'] as num).toDouble(),
            (source['height'] as num).toDouble(),
          );
        }
      }
    }

    final List<GalleryImage> galleryImages = [];
    final isGallery = data['is_gallery'] == true;
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
              galleryImages.add(GalleryImage(url: imageUrl.replaceAll('&amp;', '&'), size: Size((source['x'] as num).toDouble(),(source['y'] as num).toDouble())));
            }
          }
        }
      }
    }
    else {
      domain = data['domain'];
    }
    return Post(
      community: Community(
        platform: Platform.reddit,
        host: Platform.reddit.host!,
        name: data['subreddit'],
        id: data['subreddit_id'],
      ),
      localId: data['name'],
      shortLocalId: data['id'],
      permalink: data['permalink'],
      score: data['score'],
      timestampMs: (data['created_utc'] as num).toInt() * 1000,
      title: parse(data['title']).body!.text,
      textHtml: textHtml,
      author: author,
      authorHost: Platform.reddit.host!,
      commentCount: data['num_comments'],
      url: data['url'],
      domain: domain,
      thumbnailUrl: thumbnail,
      isStickied: data['stickied'],
      isSelf: data['is_self'],
      isNsfw: data['over_18'],
      isGallery: isGallery,
      isDeleted: author == '[deleted]',
      mediaSize: mediaSize,
      galleryImages: galleryImages,
      vote: data['likes']
    );
  }

  PagedItems<Post> _parsePosts(String body) {
    final List<Post> posts = [];
    final json = jsonDecode(body);
    final data = json['data'];
    for (var child in data['children'] as List) {
      posts.add(_parsePost(child));
    }
    return PagedItems(
      items: posts,
      pageToken: data['after']
    );
  }

  List<CommentItem> _parseComments(List<dynamic> json, int depth) {
    final List<CommentItem> comments = [];
    for (var child in json) {
      final kind = child['kind'];
      final data = child['data'];
      if (kind == 't1') { 
        final comment = _parseCommentFromJson(data, depth);
        comments.add(comment);
        if (data['replies'] is Map) {
          final repliesData = data['replies']['data'];
          if (repliesData != null && repliesData['children'] != null) {
            comments.addAll(_parseComments(repliesData['children'], depth + 1));
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
    return comments;
  }

  Comment _parseCommentFromJson(Map<String, dynamic> data, int depth) {
    final author = data['author'];
    final Map<String, Size> images = {};
    final Map<String, dynamic>? mediaMetadata = data['media_metadata'];
    if (mediaMetadata != null) {
      for (var entry in mediaMetadata.values) {
        final source = entry['s'];
        if (source != null) {
          images[((source['u'] ?? source['gif']) as String).replaceAll('&amp;', '&')] = Size((source['x'] as num).toDouble(), (source['y'] as num).toDouble());
        }
      }
    }
    return Comment(
      depth: depth,
      community: Community(
        platform: Platform.reddit,
        host: Platform.reddit.host!,
        name: data['subreddit'],
        id: data['subreddit_id'],
      ),
      id: data['name'],
      shortId: data['id'],
      permalink: data['permalink'],
      isDeleted: author == '[deleted]',
      authorId: data['author_fullname'],
      authorName: author,
      authorHost: Platform.reddit.host!,
      isModerator: data['distinguished'] == 'moderator',
      isSubmitter: data['is_submitter'] ?? false,
      score: data['score_hidden'] ? null : data['score'],
      timestampMs: (data['created_utc'] as num).toInt() * 1000,
      text: data['body'],
      textHtml: _replaceHtmlEscapedCharacters(data['body_html']),
      images: images,
      postTitle: data['link_title'],
      vote: data['likes']
    );
  }
  
  LoggedInUser _parseLoggedInUser(String body) {
    final data = jsonDecode(body);
    final iconUri = Uri.parse(data['icon_img']);
    return LoggedInUser(
      platform: Platform.reddit,
      host: Platform.reddit.host!,
      id: 't2_${data['id']}',
      name: data['name'],
      iconUrl: Uri(scheme: iconUri.scheme,host: iconUri.host,path: iconUri.path).toString()
    );
  }

}

class _ClientHelper extends SimpleRestClientHelper {

  _ClientHelper(String host) : super(host, RedditApi._defaultUnauthenticatedHeaders);

  Map<String, Cookie>? _cookies;
  Future<void>? _initCookiesFuture;
  
  @override
  bool get isValid => Settings.redditClientId.value == null;

  @override
  Future<Response> request(Map<String, String> headers, Future<Response> Function(Map<String, String> headers) request) async {
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
    dev.log('[Reddit][_ClientHelper] Request headers: ${headers.length} (${_cookies!.length} cookies)');
    dev.log('[Reddit][_ClientHelper]\tUser-Agent: ${headers['User-Agent']}');
    dev.log('[Reddit][_ClientHelper]\tCookie: ${_cookies!.entries.map((entry) => '${entry.key}=${debugTruncateLongString(entry.value.value, 6)}').join(', ')}');

    final Response response = await request(headers);
    if (response.headers.containsKey('set-cookie')) {
      await _updateCookiesFromHeaders(response.headers['set-cookie']!);
      if (response.statusCode == 403) {
        dev.log('[Reddit][_ClientHelper] Status code 403 detected. Attempting HTML warm-up...');
        final warmUp = await client.get(
          Uri.parse(RedditApi._baseUrl), 
          headers: {
            'Upgrade-Insecure-Requests': '1',
            'User-Agent': RedditApi._defaultUnauthenticatedUserAgent
          },
        );
        if (warmUp.headers.containsKey('set-cookie')) {
          await _updateCookiesFromHeaders(warmUp.headers['set-cookie']!);
          dev.log('[Reddit][_ClientHelper] Warm-up complete. Retrying original request...');
          return request(headers);
        }
      }
    }
    return response;
  }

  Future<void> _initCookies() async {
    _cookies = {
      for (var cookie in await Database.instance.getAllValidCookies())
        cookie.key: cookie
    };
    dev.log('[Reddit][_ClientHelper] Loaded ${_cookies!.length} cookies: ${_cookies!.entries.map((entry) => '${entry.key}=${debugTruncateLongString(entry.value.value, 6)}').join(', ')}');
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
      dev.log('[Reddit][_ClientHelper] Added cookie: ${cookie.key}=${debugTruncateLongString(cookie.value)}, expirationTime=${cookie.expirationTime}');
    }
    if (cookies.isNotEmpty) {
      await Database.instance.saveCookies(cookies);
    }
  }

}

class _AuthClientHelper extends RestClientHelper implements AuthClientHelper {

  final OAuth2Helper _oAuthHelper;
  final String Function() _userAgentProvider;
  AccessTokenResponse? _cachedToken;
  bool _resetTokenStorage = false;

  _AuthClientHelper(String clientId, String? userId, this._userAgentProvider)
    : _oAuthHelper = _createOAuth2Helper(clientId, userId != null ? TokenStorage(userId) : null),
      super(RedditApi._oAuthDomain, RedditApi._defaultAuthenticatedHeaders);

  @override
  bool get isValid {
    final currentClientId = Settings.redditClientId.value;
    if (currentClientId == null) {
      return false;
    }
    if (currentClientId != _oAuthHelper.clientId) {
      _oAuthHelper.clientId = currentClientId;
      _cachedToken = null;
      _resetTokenStorage = true;
    }
    return true;
  }

  @override
  Future<void> dispose() async {
    dev.log('[Reddit][_AuthClientHelper] Disposing OAuth2Helper');
    await _oAuthHelper.removeAllTokens();
    _cachedToken = null;
  }
  
  @override
  Future<Response> performGet(Uri uri, Map<String, String> headers) => _oAuthHelper.get(uri.toString(), headers: headers);
  
  @override
  Future<Response> performPost(Uri uri, Map<String, String> headers, body) => _oAuthHelper.post(uri.toString(), headers: headers, body: body);

  @override
  Future<Response> request(Map<String, String> headers, Future<Response> Function(Map<String, String> headers) request) async {
    final bool cached;
    final AccessTokenResponse? tokenResponse;
    if (_resetTokenStorage) {
      await _oAuthHelper.removeAllTokens();
      _resetTokenStorage = false;
      cached = false;
      tokenResponse = null;
    }
    else {
      cached = _cachedToken != null;
      tokenResponse = _cachedToken ??= await _oAuthHelper.getTokenFromStorage();
    }
    dev.log('[Reddit][_AuthClientHelper] Loaded token: cached=$cached, accessToken=${debugTruncateLongString(tokenResponse?.accessToken)}, refreshToken=${debugTruncateLongString(tokenResponse?.refreshToken)}');
    if (tokenResponse == null || (!tokenResponse.hasRefreshToken() && tokenResponse.isExpired())) {
      dev.log('[Reddit][_AuthClientHelper] Fetching access token (${tokenResponse == null ? 'new' : 'expired'})');
      String? deviceId = Settings.redditDeviceId.value;
      if (deviceId == null) {
        deviceId = List<int>.generate(16, (i) => Random.secure().nextInt(256)).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
        Settings.redditDeviceId.value = deviceId;
      }
      final response = await http.post( // Manually get access token with http.Client, because using _oAuthHelper.post() initiates login flow
        Uri.parse('https://www.reddit.com/api/v1/access_token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${_oAuthHelper.clientId}:'))}',
          'User-Agent': _userAgentProvider(),
        },
        body: {
          'grant_type': 'https://oauth.reddit.com/grants/installed_client',
          'device_id': deviceId,
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
      dev.log('[Reddit][_AuthClientHelper] Fetched access token: ${debugTruncateLongString(data['access_token'])}');
    }
    return request({
      ...headers,
      'User-Agent': _userAgentProvider(),
    });
  }

  @override
  Future<FetchTokenResult> fetchToken([Map<String, String>? credentials]) async {
    dev.log('[Reddit][_AuthClientHelper] fetchToken');
    final redirectUri = Settings.redditRedirectUri.value!;
    _oAuthHelper.clientId = Settings.redditClientId.value!;
    _oAuthHelper.client.redirectUri = redirectUri;
    _oAuthHelper.client.customUriScheme = redirectUri.split('://')[0];
    dev.log('[Reddit][_AuthClientHelper] Updated OAuth2Helper: clientId=${_oAuthHelper.clientId}, redirectUri=${_oAuthHelper.client.redirectUri}, customUriScheme=${_oAuthHelper.client.customUriScheme}');
    final tokenResponse = await _oAuthHelper.fetchToken();
    _cachedToken = tokenResponse;
    return tokenResponse.isValid() ? FetchTokenSuccess() : FetchTokenError();
  }

  @override
  Future<void> saveToken(String userId) {
    dev.log('[Reddit][_AuthClientHelper] saveToken: tokenStorageKey=$userId, access token=${debugTruncateLongString(_cachedToken!.accessToken)}');
    // await _oAuthHelper.tokenStorage.deleteAllTokens();
    return TokenStorage(userId).addToken(_cachedToken!);
  }
  
  static OAuth2Helper _createOAuth2Helper(String clientId, TokenStorage? tokenStorage) {
    dev.log('[Reddit][_AuthClientHelper] _createOAuth2Helper: clientId=$clientId, tokenStorage key=${tokenStorage?.key}');
    return OAuth2Helper(
      OAuth2Client(
        authorizeUrl: 'https://www.reddit.com/api/v1/authorize',
        // authorizeUrl: 'https://www.reddit.com/logout?dest=${Uri.encodeComponent('https://www.reddit.com/api/v1/authorize')}',
        tokenUrl: 'https://www.reddit.com/api/v1/access_token',
        redirectUri: '',
        customUriScheme: ''
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

}