import 'dart:developer' as dev;
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
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

  static const resultsLimit = 30;

  static gql.GraphQLClient? _clientInstance;

  const DiggApi();

  @override
  bool get hasLogin => false;

  @override
  String get defaultUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:0.1.0 (by @altherat)';

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
  Future<PagedResult<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
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
    return getPostDetailsFromId(postId, commentId: pathSegments.length > 3 ? '$postId-${pathSegments[3]}' : null, options: options);
  }

  @override
  Future<PostDetails> getPostDetailsFromId(String id, {String? commentId, Map<FeedOptionType, FeedOption>? options}) async {
    // dev.log('[Digg] getPostDetailsFromId: id=$id, commentId=$commentId, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final sort = options?[FeedOptionType.sort];
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query PostDetails($postWhere: PostWhere!, $commentWhere: CommentWhere!, $sort: CommentSort, $first: Int) {

          posts(first: 1, where: $postWhere) {
            edges {
              node {
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
                  _id,
                  username
                }
                community {
                  name
                }
                attachments {
                  __typename
                  ... on Image {
                    url
                  }
                }
                externalContent {
                  url
                  imageUrl
                }
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

        fragment CommentFragment on Comment {
          _id
          text
          score
          createdDate
          deletedDate
          commentCount
          author {
            _id,
            username
          }
          pm,
          attachments {
            __typename
            ... on Image {
              url
            }
            ... on GiphyGIF {
              id
            }
          }
        }

      '''),
      variables: {
        'first': 20,
        'postWhere': {
          '_id_EQ': id, 
        },
        'commentWhere': {
          if (commentId != null)
            '_id_EQ': commentId
          else
            'postId_EQ': id
        },
        'sort': (sort ?? Platform.digg.postCommentsFeedOptions.options.first).id
      }
    );
    final response = await _client.query(queryOptions);
    return compute(_parsePostDetails, (response.data!, commentId));
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

        fragment CommentFragment on Comment {
          _id
          text
          score
          createdDate
          deletedDate
          commentCount
          author {
            _id,
            username
          }
          pm
          attachments {
            __typename
            ... on Image {
              url
            }
            ... on GiphyGIF {
              id
            }
          }
        }

      '''),
      variables: {
        'parentId': id,
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
  UserDetailsResponse getUserDetails(String id, {Map<FeedOptionType, FeedOption>? options}) {
    // dev.log('[Digg] getUserDetails: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}]');
    final UserFeedType type = options?[FeedOptionType.type]?.id ?? Platform.digg.userFeedOptions.options.first.id;
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
                    _id
                    title
                    score
                    upvoteCount
                    commentCount
                    createdDate
                    deletedDate
                    slug
                    type
                    nsfw
                    text
                    author {
                      username
                    }
                    community {
                      name
                    }
                    externalContent {
                      url,
                      imageUrl
                    }
                    attachments {
                      __typename
                      ... on Image {
                        url
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
          '''),
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
        return UserDetailsResponse(
          stats: responseFuture.then((response) => _parseUserStats(response.data!['accounts']['edges'].first['node'])),
          items: responseFuture.then((response) => _parsePostsResult(response.data!))
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
                    _id
                    text
                    score
                    createdDate
                    deletedDate
                    commentCount
                    post {
                      title
                      community {
                        name
                      }
                    }
                    pm
                    attachments {
                      __typename
                      ... on Image {
                        url
                      }
                      ... on GiphyGIF {
                        id
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
          '''),
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
        return UserDetailsResponse(
          stats: responseFuture.then((response) => _parseUserStats(response.data!['accounts']['edges'].first['node'])),
          items: responseFuture.then((response) {
            final comments = response.data!['comments'];
            final pageInfo = comments['pageInfo'];
            return PagedResult(
              items: (comments['edges'] as List).map((edge) => _parseComment(edge['node'])).toList(),
              pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
            );
          })
        );
      case _:
        throw UnimplementedError();
    }
  }

  @override
  Future<PagedResult<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // dev.log('[Digg] getUserItems: id=$id, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final UserFeedType type = options?[FeedOptionType.type]?.id ?? Platform.digg.userFeedOptions.options.first.id;
    final FeedOption? sort = options?[FeedOptionType.sort];
    switch (type) {
      case UserFeedType.posts:
        final gql.QueryOptions queryOptions = gql.QueryOptions(
          document: gql.gql(r'''
            query PostsQuery($first: Int, $where: PostWhere, $sort: PostSort, $after: String) {

              posts(first: $first, where: $where, sort: $sort, after: $after) {
                edges {
                  node {
                    _id
                    title
                    score
                    upvoteCount
                    commentCount
                    createdDate
                    deletedDate
                    slug
                    type
                    nsfw
                    text
                    author {
                      username
                    }
                    community {
                      name
                    }
                    externalContent {
                      url,
                      imageUrl
                    }
                    attachments {
                      __typename
                      ... on Image {
                        url
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
          '''),
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
                    _id
                    text
                    score
                    createdDate
                    deletedDate
                    commentCount
                    post {
                      title
                      community {
                        name
                      }
                    }
                    pm
                    attachments {
                      __typename
                      ... on Image {
                        url
                      }
                      ... on GiphyGIF {
                        id
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
          '''),
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
  Future<PagedResult<dynamic>> search(String query, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // dev.log('[Digg] search: query=$query, options=[${options?.values.map((option) => option.id).join(', ')}], pageToken=$pageToken');
    final type = options?[FeedOptionType.type]?.id ?? SearchFeedType.posts;
    final sort = options?[FeedOptionType.sort];
    final gql.QueryOptions queryOptions;
    final PagedResult<dynamic> Function(Map<String, dynamic>) parseFn;
    if (type == SearchFeedType.communities) {
      parseFn = (data) {
        final communitiesData = data['communities'];
        final List edges = communitiesData['edges'];
        final pageInfo = communitiesData['pageInfo'];
        return PagedResult(
          items: edges.map((edge) {
            final node = edge['node'];
            return Community(
              platform: Platform.digg,
              name: node['name'],
              description: node['description'],
              iconUrl: node['iconUrl'],
              subscriberCount: node['memberCount'],
            );
          }).toList(),
          pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
        );
      };
      queryOptions = gql.QueryOptions(
        document: gql.gql(r'''
          query CommunitiesQuery($first: Int, $where: CommunitiesWhere, $sort: CommunitiesSort, $after: String) {
            communities(first: $first, where: $where, sort: $sort, after: $after) {
              edges {
                node {
                  _id
                  name
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
        '''),
        variables: {
          'first': resultsLimit,
          'where': {'query': query},
          if (pageToken != null)
            'after': pageToken,
        },
      );
    }
    else if (type == SearchFeedType.users) {
      parseFn = (data) {
        final accountsData = data['accounts'];
        final List edges = accountsData['edges'];
        final pageInfo = accountsData['pageInfo'];
        return PagedResult(
          items: edges.map((edge) {
            final node = edge['node'];
            return LookedUpUser(
              id: node['_id'],
              name: node['username'],
              iconUrl: node['avatarUrl'],
              isSuspended: false,
              stats: _parseUserStats(node)
            );
          }).toList(),
          pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
        );
      };
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
                  diggsGiven
                  gemsCount
                  postCount
                  commentCount
                }
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
        '''),
        variables: {
          'first': resultsLimit,
          'where': {'username_CONTAINS': query},
          if (pageToken != null)
            'after': pageToken,
        },
      );
    }
    else {
      parseFn = _parsePostsResult;
      queryOptions = gql.QueryOptions(
        document: gql.gql(r'''
          query PostsQuery($first: Int, $after: String, $where: PostWhere, $sort: PostSort) {
            posts(first: $first, after: $after, where: $where, sort: $sort) {
              edges {
                node {
                  _id
                  title
                  score
                  upvoteCount
                  commentCount
                  createdDate
                  deletedDate
                  slug
                  type
                  nsfw
                  text
                  author {
                    username
                  }
                  community {
                    name
                  }
                  externalContent {
                    url
                    imageUrl
                  }
                  attachments {
                    __typename
                    ... on Image {
                      url
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
        '''),
        variables: {
          'first': resultsLimit,
          'where': {'query_MATCHES': query},
          'sort': sort?.id ?? 'TRENDING',
          if (pageToken != null)
            'after': pageToken,
        },
      );
    }
    final response = await _client.query(queryOptions);
    return compute(parseFn, response.data!);
  }

  @override
  Future<String?> login() async {
    throw UnimplementedError();
  }

  @override
  Future<String> logout() async {
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

  Future<PagedResult<Post>> _getPostsRecursive(Map<String, dynamic> variables, {List<Post>? accumulatedPosts, int depth = 0}) async {
    // dev.log('[Digg] _getPostsRecursive: variables=[${variables.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}], posts=${accumulatedPosts?.length}, depth=$depth');
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query PostsQuery($first: Int, $where: PostWhere, $sort: PostSort, $after: String) {

          posts(first: $first, where: $where, sort: $sort, after: $after) {
            edges {
              node {
                _id
                title
                score
                upvoteCount
                commentCount
                createdDate
                deletedDate
                slug
                type
                nsfw
                text
                author {
                  username
                }
                community {
                  name
                }
                externalContent {
                  url,
                  imageUrl
                }
                attachments {
                  __typename
                  ... on Image {
                    url
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
      '''),
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

    return PagedResult(
      items: allPosts,
      pageToken: allPosts.length < resultsLimit ? null : pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
    );

  }

  static PagedResult<Post> _parsePostsResult(Map<String, dynamic> data) {
    final postsData = data['posts'];
    final List edges = postsData['edges'];
    final pageInfo = postsData['pageInfo'];
    return PagedResult(
      items: edges.map((edge) => _parsePost(edge['node'])).toList(),
      pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
    );
  }

  static PagedResult<Comment> _parseCommentsResult(Map<String, dynamic> data) {
    final comments = data['comments'];
    final pageInfo = comments['pageInfo'];
    return PagedResult(
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
    final communityName = (json['community']['name'] as String).toLowerCase();

    final idLastDashIndex = id.lastIndexOf('-');
    final permalink = '/${id.substring(0, idLastDashIndex)}/${id.substring(idLastDashIndex + 1)}/${json['slug']}';

    final String url;
    final String domain;
    final String? thumbnailUrl;
    final List<String> galleryImageUrls;
    if (attachments.isNotEmpty) {
      url = attachments.first['url'];
      domain = 'image';
      thumbnailUrl = url;
      galleryImageUrls = attachments.map((item) => item['url'] as String).toList();
    }
    else {
      if (externalContent != null) {
        url = externalContent['url'];
        final String host = Uri.parse(url).host;
        final List<String> parts = host.split('.');
        domain = parts.length >= 2 ? parts.sublist(parts.length - 2).join('.') : host;
        thumbnailUrl = externalContent['imageUrl'];
      }
      else {
        url = '$_baseUrl$permalink';
        domain = 'self.$communityName';
        thumbnailUrl = null;
      }
      galleryImageUrls = [];
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
      galleryImageUrls: galleryImageUrls,
    );
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
          depth: 0,
          count: post.commentCount - comments.length,
          pageToken: pageInfo['endCursor']
        )
      );
    }
    return PostDetails(
      post: post,
      comments: comments,
      contextCommentId: contextCommentId
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

    final bool isSubmitter;
    final String? authorUsername;
    final String? postTitle;
    final String? communityName;
    if (author != null) {
      isSubmitter = author['_id'] == postAuthorId;
      authorUsername = author['username'];
    }
    else {
      isSubmitter = false;
      authorUsername = null;
    }

    if (postData != null) {
      postTitle = postData?['title'];
      communityName = postData['community']['name'];
    }
    else {
      postTitle = null;
      communityName = null;
    }

    final String html = ((pm != null ? _parsePmToHtml(pm) : text) ?? '') + attachments.map((a) {
      switch (a['__typename']) {
        case 'Image':
          return '<img src="${a['url']}">';
        case 'GiphyGIF':
          return '<img src="https://media.giphy.com/media/${a['id']}/giphy.gif">';
      }
      return '';
    }).join();


    return Comment(
      depth: depth,
      platform: Platform.digg,
      id: id,
      permalink: '/${id.substring(0, idSecondLastDash)}/${id.substring(idSecondLastDash + 1, idLastDashIndex)}/comment/$commentId',
      isDeleted: data['deletedDate'] != null,
      author: authorUsername,
      isModerator: false,
      isSubmitter: isSubmitter,
      score: data['score'],
      timestampMs: DateTime.parse(data['createdDate']).millisecondsSinceEpoch,
      text: text,
      textHtml: html.isEmpty ? null : html,
      postTitle: postTitle,
      communityName: communityName,
    );
  }

  static String _parsePmToHtml(Map<String, dynamic> pm) {
    final html = StringBuffer();
    for (var block in pm['content']) {
      if (block['type'] == 'diggTextBlock') {
        for (var paragraph in block['content']) {
          if (paragraph['type'] == 'paragraph') {
            html.write('<p>');
            for (var node in paragraph['content']) {
              if (node['type'] == 'text') {
                final String nodeText = node['text'];
                var linkMark = (node['marks'] as List).firstWhere(
                  (m) => m['type'] == 'link', 
                  orElse: () => null
                );
                html.write(linkMark != null ? '<a href="${linkMark['attrs']['href']}">$nodeText</a>' : nodeText);
              }
              else if (node['type'] == 'hardBreak') {
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

  static List<UserStat> _parseUserStats(Map<String, dynamic> data) {
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