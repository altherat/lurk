import 'dart:developer' as dev;
import 'dart:io' as io;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';

class DiggApi extends Api {

  static const _baseUrl = 'https://digg.com';
  static const _baseUrlGraphQl = 'https://apineapple-prod.digg.com/graphql';
  static const _defaultHeaders = {
    'Accept': 'application/graphql-response+json',
    'Content-Type': 'application/json',
  };

  final postFragment = r'''
    fragment PostFragment on Post {
      _id
      title
      score
      commentCount
      createdDate
      deletedDate
      slug
      type
      nsfw
      text
      author {
        _id
        username
      }
      community {
        slug
      }
      attachments {
        __typename
        ... on Image {
          url
          width
          height
        }
      }
      externalContent {
        url
        imageUrl
      }
    }
  ''';
  final commentFragment = r'''
    fragment CommentFragment on Comment {
      _id
      text
      score
      createdDate
      deletedDate
      commentCount
      author {
        _id
        username
      }
      pm,
      attachments {
        __typename
        ... on Image {
          url
          width
          height
        }
        ... on GiphyGIF {
          id
        }
      }
    }
  ''';

  static const resultsLimit = 30;

  static gql.GraphQLClient? _clientInstance;

  const DiggApi();

  @override
  bool get hasLogin => false;

  @override
  String get defaultUnauthenticatedUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:0.1.0 (by @altherat)';

  @override
  String get baseUrl => _baseUrl;

  gql.GraphQLClient get _client {
    return _clientInstance ??= gql.GraphQLClient(
      link: gql.Link.function((request, [forward]) {
        return forward!(
          request.updateContextEntry<gql.HttpLinkHeaders>(
            (headers) => gql.HttpLinkHeaders(
              headers: {
                ...?headers?.headers,
                'User-Agent': super.savedOrDefaultUserAgent,
                ..._defaultHeaders
              },
            ),
          )
        );
      }).concat(gql.HttpLink(_baseUrlGraphQl)),
      cache: gql.GraphQLCache(),
      defaultPolicies: gql.DefaultPolicies(
        query: gql.Policies(
          fetch: gql.FetchPolicy.networkOnly,
        )
      )
    );
  }

  @override
  Future<PagedItems<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // dev.log('[Digg] getPosts: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final sort = options?[FeedOptionType.sort];
    return _getPostsRecursive({
      'first': resultsLimit,
      'where': {
        'isPersonalized': false,
        if (id != null)
          'community': {'slug_EQ': id},
        if (sort?.id == 'MOST_DUGG')
          'publishedDate_GT': DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(), // Current functionality of Digg website/app is to only return most dugg posts in past day
      },
      'sort': (sort ?? Platform.digg.postsFeedOptions.options.first).id,
      if (pageToken != null)
        'after': pageToken
    });
  }

  @override
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options}) {
    // dev.log('[Digg] getPostDetailsFromUrl: url=$url, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final pathSegments = Uri.parse(url).pathSegments;
    final String postId = '${pathSegments[0]}-${pathSegments[1]}';
    return getPostDetailsFromId(postId, shortCommentId: pathSegments.length > 3 ? pathSegments[3] : null, options: options);
  }

  @override
  Future<PostDetails> getPostDetailsFromId(String id, {String? shortCommentId, Map<FeedOptionType, FeedOption>? options}) async {
    // dev.log('[Digg] getPostDetailsFromId: id=$id, commentId=$commentId, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final sort = options?[FeedOptionType.sort];
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query PostDetails($postWhere: PostWhere!, $commentWhere: CommentWhere!, $sort: CommentSort, $first: Int) {

          posts(first: 1, where: $postWhere) {
            edges {
              node {
                ...PostFragment
              }
            }
          }

          comments(first: $first, where: $commentWhere, sort: $sort) {
            edges {
              node {
                ...CommentFragment
                comments {
                  ...CommentFragment
                  comments {
                    ...CommentFragment
                    comments {
                      ...CommentFragment
                      comments {
                        ...CommentFragment
                      }
                    }
                  }
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        '''
        + postFragment
        + commentFragment
      ),
      variables: {
        'first': 20,
        'postWhere': {
          '_id_EQ': id, 
        },
        'commentWhere': {
          if (shortCommentId != null)
            '_id_EQ': '$id-$shortCommentId'
          else
            'postId_EQ': id
        },
        'sort': (sort ?? Platform.digg.postCommentsFeedOptions.options.first).id
      }
    );
    final response = await _client.query(queryOptions);
    return compute(_parsePostDetails, (response.data!, shortCommentId));
  }

  @override
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? depth, Map<FeedOptionType, FeedOption>? options}) async {
    // dev.log('[Digg] getMoreComments: id=$id, pageToken=$pageToken, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final sort = options?[FeedOptionType.sort];
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query MoreComments($first: Int, $postWhere: PostWhere!, $commentWhere: CommentWhere!, $sort: CommentSort, $after: String) {

          posts(first: 1, where: $postWhere) {
            edges {
              node {
                commentCount
              }
            }
          }

          comments(first: $first, where: $commentWhere, sort: $sort, after: $after) {
            edges {
              node {
                ...CommentFragment
                comments {
                  ...CommentFragment
                  comments {
                    ...CommentFragment
                    comments {
                      ...CommentFragment
                      comments {
                        ...CommentFragment
                      }
                    }
                  }
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        '''
        + commentFragment
      ),
      variables: {
        'first': 20,
        'postWhere': {
          '_id_EQ': id, 
        },
        'commentWhere': {
          'postId_EQ': id,
        },
        'sort': (sort ?? Platform.digg.postCommentsFeedOptions.options.first).id,
        'after': pageToken,
      },
    );

    final response = await _client.query(queryOptions);
    return compute(
      (data) {
        final List edges = data['comments']['edges'];
        final Map<String, dynamic> pageInfo = data['comments']['pageInfo'];
        final List<CommentItem> comments = _parseComments(edges, '', depth ?? 0);
        if (pageInfo['hasNextPage']) {
          comments.add(
            LoadMoreComment(
              platform: Platform.digg,
              depth: 0,
              count: data['posts']['edges'][0]['node']['commentCount'] - comments.length,
              pageToken: pageInfo['endCursor'],
            ),
          );
        }
        return comments;
      },
      response.data!
    );
  }

  @override
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options}) {
    // dev.log('[Digg] getUserDetails: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final UserFeedType type = options?[FeedOptionType.category]?.id ?? Platform.digg.userFeedOptions.options.first.id;
    final FeedOption? sort = options?[FeedOptionType.sort];
    switch (type) {
      case UserFeedType.posts:
        final gql.QueryOptions queryOptions = gql.QueryOptions(
          document: gql.gql(r'''
            query PostsQuery($first: Int, $username: String!, $where: PostWhere, $sort: PostSort) {

              accounts(first: 1, where: { username_EQ: $username }) {
                edges {
                  node {
                    _id
                    createdDate
                    score
                    diggsGiven
                    gemsCount
                    postCount
                    commentCount
                  }
                }
              }

              posts(first: $first, where: $where, sort: $sort) {
                edges {
                  node {
                    ...PostFragment
                  }
                }
                pageInfo {
                  hasNextPage
                  endCursor
                }
              }

            }
            '''
            + postFragment
          ),
          variables: {
            'first': resultsLimit,
            'username': id,
            'where': {
              'author': {
                'username_EQ': id
              },
            },
            if (sort != null)
              'sort': sort.id
          }
        );
        
        final responseFuture = _client.query(queryOptions);
        return MultiPartFeedResponse(
          items: responseFuture.then((response) => _parsePostsResult(response.data!)),
          other: responseFuture.then((response) => _parseAllUserStats(response.data!['accounts']['edges'].first['node'])),
        );
      case UserFeedType.comments:
        final gql.QueryOptions queryOptions = gql.QueryOptions(
          document: gql.gql(r'''
            query UserDetailsQuery($first: Int, $username: String!, $where: CommentWhere!, $sort: CommentSort) {
            
              accounts(first: 1, where: { username_EQ: $username }) {
                edges {
                  node {
                    _id
                    createdDate
                    score
                    diggsGiven
                    gemsCount
                    postCount
                    commentCount
                  }
                }
              }

              comments(first: $first, where: $where, sort: $sort) {
                edges {
                  node {
                    ...CommentFragment
                    post {
                      title
                      community {
                        slug
                      }
                    }
                  }
                }
                pageInfo {
                  hasNextPage
                  endCursor
                }
              }
            }
            '''
            + commentFragment
          ),
          variables: {
            'first': resultsLimit,
            'username': id,
            'where': {
              'author': {
                'username_EQ': id
              }
            },
            if (sort != null)
              'sort': sort.id
          },
        );
        
        final responseFuture = _client.query(queryOptions);
        return MultiPartFeedResponse(
          items: responseFuture.then((response) {
            final comments = response.data!['comments'];
            final pageInfo = comments['pageInfo'];
            return PagedItems(
              items: (comments['edges'] as List).map((edge) => _parseComment(edge['node'])).toList(),
              pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
            );
          }),
          other: responseFuture.then((response) => _parseAllUserStats(response.data!['accounts']['edges'].first['node'])),
        );
      case _:
        throw UnimplementedError();
    }
  }

  @override
  Future<PagedItems<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    dev.log('[Digg] getUserItems: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final UserFeedType type = options?[FeedOptionType.category]?.id ?? Platform.digg.userFeedOptions.options.first.id;
    final FeedOption? sort = options?[FeedOptionType.sort];
    switch (type) {
      case UserFeedType.posts:
        final gql.QueryOptions queryOptions = gql.QueryOptions(
          document: gql.gql(r'''
            query PostsQuery($first: Int, $where: PostWhere, $sort: PostSort, $after: String) {

              posts(first: $first, where: $where, sort: $sort, after: $after) {
                edges {
                  node {
                    ...PostFragment
                  }
                }
                pageInfo {
                  hasNextPage
                  endCursor
                }
              }

            }
            '''
            + postFragment
          ),
          variables: {
            'first': resultsLimit,
            'username': id,
            'where': {
              'author': {
                'username_EQ': id
              },
            },
            if (sort != null)
              'sort': sort.id,
            if (pageToken != null)
              'after': pageToken
          }
        );
        final response = await _client.query(queryOptions);
        return compute(_parsePostsResult, response.data!);
      case UserFeedType.comments:
        final gql.QueryOptions queryOptions = gql.QueryOptions(
          document: gql.gql(r'''
            query UserDetailsQuery($first: Int, $where: CommentWhere!, $sort: CommentSort, $after: String) {

              comments(first: $first, where: $where, sort: $sort, after: $after) {
                edges {
                  node {
                    ...CommentFragment
                    post {
                      title
                      community {
                        slug
                      }
                    }
                  }
                }
                pageInfo {
                  hasNextPage
                  endCursor
                }
              }
            }
            '''
            + commentFragment
          ),
          variables: {
            'first': resultsLimit,
            'where': {
              'author': {
                'username_EQ': id
              }
            },
            if (sort != null)
              'sort': sort.id,
            if (pageToken != null)
              'after': pageToken
          },
        );
        final response = await _client.query(queryOptions);
        return compute(_parseCommentsResult, response.data!);
      case _:
        throw UnimplementedError();
    }
  }

  @override
  Future<PagedItems<dynamic>> search(String query, String? communityName, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // dev.log('[Digg] search: query=$query, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final type = options?[FeedOptionType.category]?.id ?? SearchFeedType.posts;
    final gql.QueryOptions queryOptions;
    final PagedItems<dynamic> Function(Map<String, dynamic>) parseFn;
    if (type == SearchFeedType.communities) {
      queryOptions = gql.QueryOptions(
        document: gql.gql(r'''
          query CommunitiesQuery($first: Int, $where: CommunitiesWhere, $sort: CommunitiesSort, $after: String) {
            communities(first: $first, where: $where, sort: $sort, after: $after) {
              edges {
                node {
                  _id
                  slug
                  description
                  iconUrl
                  memberCount
                }
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
          '''
        ),
        variables: {
          'first': resultsLimit,
          'where': {'query': query},
          if (pageToken != null)
            'after': pageToken,
        },
      );
      parseFn = (data) {
        final Map<String, dynamic> communitiesData = data['communities'];
        final List edges = communitiesData['edges'];
        final pageInfo = communitiesData['pageInfo'];
        return PagedItems(
          items: edges.map((edge) {
            final Map<String, dynamic> node = edge['node'];
            final String? iconUrl = node['iconUrl'];
            return Community(
              platform: Platform.digg,
              name: node['slug'],
              description: node['description'],
              iconUrl: iconUrl != null ? _getThumbnailUrl(Uri.parse(iconUrl)) : null,
              subscriberCount: node['memberCount'],
            );
          }).toList(),
          pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
        );
      };
    }
    else if (type == SearchFeedType.users) {
      queryOptions = gql.QueryOptions(
        document: gql.gql(r'''
          query AccountsQuery($after: String, $first: Int, $sort: AccountSort, $where: AccountWhere) {
            accounts(after: $after, first: $first, sort: $sort, where: $where) {
              edges {
                node {
                  _id
                  username
                  avatarUrl
                  createdDate
                  score
                }
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
          '''
        ),
        variables: {
          'first': resultsLimit,
          'where': {'username_CONTAINS': query},
          if (pageToken != null)
            'after': pageToken,
        },
      );
      parseFn = (data) {
        final accountsData = data['accounts'];
        final List edges = accountsData['edges'];
        final pageInfo = accountsData['pageInfo'];
        return PagedItems(
          items: edges.map((edge) {
            final Map<String, dynamic> node = edge['node'];
            final String? iconUrl = node['avatarUrl'];
            return LookedUpUser(
              id: node['_id'],
              name: node['username'],
              iconUrl: iconUrl != null ? _getThumbnailUrl(Uri.parse(iconUrl)) : iconUrl,
              isSuspended: false,
              stats: [
                UserStat(
                  label: 'Digg age',
                  value: DateTime.parse(node['createdDate'])
                ),
                UserStat(
                  label: 'Score',
                  value: node['score']
                )
              ]
            );
          }).toList(),
          pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
        );
      };
    }
    else {
      final sort = options?[FeedOptionType.sort];
      queryOptions = gql.QueryOptions(
        document: gql.gql(r'''
          query PostsQuery($first: Int, $after: String, $where: PostWhere, $sort: PostSort) {
            posts(first: $first, after: $after, where: $where, sort: $sort) {
              edges {
                node {
                  ...PostFragment
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
          }
          '''
          + postFragment
        ),
        variables: {
          'first': resultsLimit,
          'where': {
            'query_MATCHES': query,
            if (communityName != null)
              'community': {
                'slug_EQ': communityName
              }
          },
          'sort': sort?.id ?? 'TRENDING',
          if (pageToken != null)
            'after': pageToken,
        },
      );
      parseFn = _parsePostsResult;
    }
    final response = await _client.query(queryOptions);
    return compute(parseFn, response.data!);
  }

  @override
  Future<String?> login() async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<LoggedInUser> getLoggedInUser() {
    throw UnimplementedError();
  }
  
  @override
  Future<List<String>> getSubscribedCommunityNames() {
    throw UnimplementedError();
  }

  @override
  Future<void> vote(String id, bool? up) {
    throw UnimplementedError();
  }
  @override
  Future<Comment> postComment(String id, String text) {
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteComment(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> unsubscribe(String id) {
    throw UnimplementedError();
  }

  Future<PagedItems<Post>> _getPostsRecursive(Map<String, dynamic> variables, {List<Post>? accumulatedPosts, int depth = 0}) async {
    // dev.log('[Digg] _getPostsRecursive: variables=[${variables.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}], posts=${accumulatedPosts?.length}, depth=$depth');
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query PostsQuery($first: Int, $where: PostWhere, $sort: PostSort, $after: String) {

          posts(first: $first, where: $where, sort: $sort, after: $after) {
            edges {
              node {
                ...PostFragment
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }

        }
        '''
        + postFragment
      ),
      variables: variables
    );
    final response = await _client.query(queryOptions);
    final postsData = response.data!['posts'];
    final Map<String, dynamic> pageInfo = postsData['pageInfo'];
    final List<Post> allPosts = [...?accumulatedPosts, ...postsData['edges'].map((edge) => _parsePost(edge['node']))];
    if (allPosts.length < resultsLimit && pageInfo['hasNextPage'] == true && pageInfo['endCursor'] != null && depth < Settings.diggPostsFetchDepth.value + 1) {
      return _getPostsRecursive(
        {
          ...variables,
          'after': pageInfo['endCursor'],
        },
        accumulatedPosts: allPosts,
        depth: depth + 1,
      );
    }
    return PagedItems(
      items: allPosts,
      pageToken: allPosts.length < resultsLimit ? null : pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
    );

  }

  static PagedItems<Post> _parsePostsResult(Map<String, dynamic> data) {
    final postsData = data['posts'];
    final List edges = postsData['edges'];
    final pageInfo = postsData['pageInfo'];
    return PagedItems(
      items: edges.map((edge) => _parsePost(edge['node'])).toList(),
      pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
    );
  }

  static PagedItems<Comment> _parseCommentsResult(Map<String, dynamic> data) {
    final comments = data['comments'];
    final pageInfo = comments['pageInfo'];
    return PagedItems(
      items: (comments['edges'] as List).map((edge) => _parseComment(edge['node'])).toList(),
      pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
    );
  }

  static Post _parsePost(Map<String, dynamic> json) {
    final String id = json['_id'];
    final String? text = json['text'];
    final authorUsername = json['author']['username'];
    final List attachments = json['attachments'];
    final externalContent = json['externalContent'];
    final communityName = json['community']['slug'];

    final idLastDashIndex = id.lastIndexOf('-');
    final permalink = '/${id.substring(0, idLastDashIndex)}/${id.substring(idLastDashIndex + 1)}/${json['slug']}';

    final String url;
    final String domain;
    final String? thumbnailUrl;
    final Size? mediaSize;
    final List<GalleryImage> galleryImages;
    if (attachments.isNotEmpty) {
      url = attachments.first['url'];
      thumbnailUrl = _getThumbnailUrl(Uri.parse(url));
      if (attachments.length > 1) {
        domain = 'image/gallery';
        mediaSize = null;
        galleryImages = attachments.map((a) => GalleryImage(url: a['url'], size: Size((a['width'] as num).toDouble(), (a['height'] as num).toDouble()))).toList();
      }
      else {
        final attachment = attachments.first;
        final num? width = attachment['width'];
        domain = 'image';
        mediaSize = width != null ? Size(width.toDouble(), (attachment['height'] as num).toDouble()) : null;
        galleryImages = const [];
      }
    }
    else {
      mediaSize = null;
      galleryImages = const [];
      if (externalContent != null) {
        url = externalContent['url'];
        final host = Uri.parse(url).host;
        final List parts = host.split('.');
        final imageUrl = externalContent['imageUrl'];
        domain = parts.length >= 2 ? parts.sublist(parts.length - 2).join('.') : host;
        if (imageUrl != null) {
          final uri = Uri.parse(imageUrl);
          thumbnailUrl = uri.host.endsWith('.imgix.net') ? _getThumbnailUrl(uri) : imageUrl;
        }
        else {
          thumbnailUrl = null;
        }
      }
      else {
        url = '$_baseUrl$permalink';
        domain = 'self.$communityName';
        thumbnailUrl = null;
      }
    }
    return Post(
      community: Community(
        platform: Platform.digg,
        name: communityName
      ),
      id: id,
      permalink: permalink,
      title: (json['title'] as String).trim(),
      textHtml: text != null && text.isNotEmpty ? text : null,
      score: json['score'],
      timestampMs: DateTime.tryParse(json['createdDate'])?.millisecondsSinceEpoch ?? 0,
      commentCount: json['commentCount'],
      author: authorUsername == '[deleted]' ? null : authorUsername,
      domain: domain,
      isSelf: json['type'] == 'TEXT',
      isNsfw: json['nsfw'],
      url: url,
      thumbnailUrl: thumbnailUrl,
      isGallery: attachments.length > 1,
      isDeleted: json['deletedDate'] != null,
      mediaSize: mediaSize,
      galleryImages: galleryImages,
    );
  }

  static String _getThumbnailUrl(Uri uri) {
    // dev.log('[Digg] _getThumbnailUrl: uri=$uri');
    final width = Constants.thumbnailSize * 3;
    final params = Map<String, dynamic>.from(uri.queryParameters);
    params['w'] = width.toString();
    params['h'] = width.toString();
    params['fit'] = 'crop';
    params['crop'] = 'faces,center';
    params['auto'] = 'format,compress';
    params['q'] = '75';
    return uri.replace(queryParameters: params).toString();
  }

  static PostDetails _parsePostDetails((Map<String, dynamic>, String?) args) {
    final (data, contextCommentId) = args;
    final postData = (data['posts']['edges'] as List).first['node'];
    final commentsData = data['comments'];
    final post = _parsePost(postData);
    final comments = _parseComments(commentsData['edges'], postData['author']['_id']);
    final pageInfo = commentsData['pageInfo'];
    if (pageInfo['hasNextPage']) {
      comments.add(
        LoadMoreComment(
          platform: Platform.digg,
          depth: 0,
          count: post.commentCount - comments.length,
          pageToken: pageInfo['endCursor']
        )
      );
    }
    return PostDetails(
      post: post,
      comments: comments,
      contextCommentShortId: contextCommentId
    );
  }

  static List<CommentItem> _parseComments(List<dynamic> children, String postAuthorId, [int depth = 0]) {
    final List<CommentItem> comments = [];

    for (int i = 0; i < children.length; i++) {
      final item = children[i];
      final Map<String, dynamic> data = (item is Map && item.containsKey('node')) ? item['node'] : item as Map<String, dynamic>;
      comments.add(_parseComment((item is Map && item.containsKey('node')) ? item['node'] : item as Map<String, dynamic>, depth, postAuthorId));
      if (depth < 4) {
        final List? replyComments = data['comments'];
        if (replyComments != null && replyComments.isNotEmpty) {
          comments.addAll(_parseComments(replyComments, postAuthorId, depth + 1));
        }
      }
      else {
        final replyCount = data['commentCount'];
        if (replyCount > 0) {
          final remainingItems = children.sublist(i + 1);
          if (remainingItems.isNotEmpty) {
            final int itemsToTake = replyCount > remainingItems.length ? remainingItems.length : replyCount;
            final childrenToIndent = remainingItems.sublist(0, itemsToTake);
            comments.addAll(_parseComments(childrenToIndent, postAuthorId, depth + 1));
            i += itemsToTake;
          }
        }
      }

    }

    return comments; 
  }

  static Comment _parseComment(Map<String, dynamic> data, [int depth = 0, String? postAuthorId]) {
    final String id = data['_id'];
    final text = data['text'];
    final author = data['author'];
    final postData = data['post'];
    final pm = data['pm'];
    final List attachments = data['attachments'];

    final idLastDashIndex = id.lastIndexOf('-');
    final idSecondLastDash = id.lastIndexOf('-', idLastDashIndex - 1);
    final commentId = id.substring(idLastDashIndex + 1);

    final String? authorId;
    final String? authorName;
    final bool isSubmitter;
    final String? postTitle;
    final String? communityName;
    if (author != null) {
      authorId = author['_id'];
      authorName = author['username'];
      isSubmitter = authorId == postAuthorId;
    }
    else {
      authorId = null;
      authorName = null;
      isSubmitter = false;
    }

    if (postData != null) {
      postTitle = postData?['title'];
      communityName = postData['community']['slug'];
    }
    else {
      postTitle = null;
      communityName = null;
    }

    final Map<String, Size> images = {};
    final String html = ((pm != null ? _parsePmToHtml(pm) : text) ?? '') + attachments.map((a) {
      switch (a['__typename']) {
        case 'Image':
          final url = a['url'];
          images[url] = Size((a['width'] as num).toDouble(), (a['height'] as num).toDouble());
          return '<img src="$url">';
        case 'GiphyGIF':
          return '<img src="https://media.giphy.com/media/${a['id']}/giphy.gif">';
      }
      return '';
    }).join();


    return Comment(
      depth: depth,
      platform: Platform.digg,
      id: id,
      shortId: commentId,
      permalink: '/${id.substring(0, idSecondLastDash)}/${id.substring(idSecondLastDash + 1, idLastDashIndex)}/comment/$commentId',
      isDeleted: data['deletedDate'] != null,
      authorId: null,
      authorName: authorName,
      isModerator: false,
      isSubmitter: isSubmitter,
      score: data['score'],
      timestampMs: DateTime.parse(data['createdDate']).millisecondsSinceEpoch,
      text: text,
      textHtml: html.isEmpty ? null : html,
      images: images,
      postTitle: postTitle,
      communityName: communityName,
    );
  }

  // ProseMirror
  static String _parsePmToHtml(Map<String, dynamic> pm) {
    final html = StringBuffer();
    for (var block in pm['content']) {
      if (block['type'] == 'diggTextBlock') {
        for (var paragraph in block['content']) {
          if (paragraph['type'] == 'paragraph') {
            html.write('<p>');
            for (var node in paragraph['content']) {
              final type = node['type'];
              if (type == 'text') {
                final String nodeText = node['text'];
                final List marks = node['marks'] ?? [];
                var linkMark = marks.firstWhere((m) => m['type'] == 'link', orElse: () => null);

                if (linkMark != null) {
                  html.write('<a href="${linkMark['attrs']['href']}">$nodeText</a>');
                } else {
                  html.write(nodeText);
                }
              } 
              else if (type == 'mention') {
                final attrs = node['attrs'];
                final String label = '${attrs['mentionSuggestionChar']}${attrs['label']}';
                final String type = attrs['type'];
                if (type == 'account') {
                  html.write('<a href="/$label">$label</a>');
                }
                else if (type == 'community') {
                  html.write('<a href="$label">$label</a>');
                }
              }
              else if (type == 'hardBreak') {
                html.write('<br/>');
              }
            }
            html.write('</p>');
          }
        }
      }
    }
    return html.toString();
  }

  static List<UserStat> _parseAllUserStats(Map<String, dynamic> data) {
    return [
      UserStat(
        label: 'Digg age',
        value: DateTime.parse(data['createdDate'])
      ),
      UserStat(
        label: 'Score',
        value: data['score']
      ),
      UserStat(
        label: 'Diggs given',
        value: data['diggsGiven']
      ),
      UserStat(
        label: 'Gems',
        value: data['gemsCount']
      ),
      UserStat(
        label: 'Post count',
        value: data['postCount'],
      ),
      UserStat(
        label: 'Comment count',
        value: data['commentCount']
      )
    ];
  }
  
}