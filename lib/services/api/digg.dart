import 'dart:io' as io;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/community_details.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/client_helpers.dart';
import 'package:lurk/services/settings.dart';

class DiggApi extends Api<GraphQlClientHelper> {

  static const resultsLimit = 30;
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
      text
      pm
      slug
      type
      nsfw
      author {
        _id
        username
      }
      community {
        _id
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

  const DiggApi();

  @override
  String? get savedUserAgent => Settings.diggUserAgent.value;

  @override
  String get defaultUnauthenticatedUserAgent => '${io.Platform.operatingSystem}:com.altherat.lurk:${Constants.version} (by @altherat)';

  @override
  String getBaseUrl(String host) => _baseUrl;

  @override
  ClientHelper getClientHelper(String host, String? userId) => GraphQlClientHelper(_baseUrlGraphQl, () => {'User-Agent': savedOrDefaultUserAgent, ..._defaultHeaders});

  @override
  Future<CommunityDetails> getCommunityDetails(GraphQlClientHelper clientHelper, String name) async {
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query CommunityQuery($slug: String!) {

          community(where: { slug_EQ: $slug }) {
            _id
            createdDate
            name
            description
            descriptionPM
            iconUrl
            bannerMobileImage {
              url
            }
            memberCount
            postCount
          }

        }
        '''
      ),
      variables: {
        'slug': name
      },
    );

    final response = await clientHelper.query(queryOptions);
    final data = response.data!['community'];
    final descriptionPm = data['descriptionPM'];
    final bannerImage = data['bannerMobileImage'];
    final iconUrl = data['iconUrl'];
    return CommunityDetails(
      community: Community(
        platform: Platform.digg,
        host: Platform.digg.preferredHost!,
        name: name,
        id: data['_id'],
      ),
      createdDate: DateTime.parse(data['createdDate']),
      title: data['name'],
      shortDescription: data['description'],
      longDescriptionHtml: descriptionPm != null ? _parsePmToHtml(descriptionPm) : null,
      iconUrl: iconUrl != null ? _getThumbnailUrl(Uri.parse(iconUrl)) : null,
      bannerUrl: bannerImage != null ? bannerImage['url'] : null,
      subscriberCount: data['memberCount'],
      postCount: data['postCount'],
    );
  }

  @override
  Future<PagedItems<Post>> getCommunityPosts(GraphQlClientHelper clientHelper, String? id, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
    final sort = options?[FeedOptionType.sort];
    return _getPostsRecursive(
      clientHelper,
      {
        'first': resultsLimit,
        'where': {
          'isPersonalized': false,
          if (id != null)
            'community': {'slug_EQ': id},
          if (sort?.id == 'MOST_DUGG')
            'publishedDate_GT': DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(), // Current functionality of Digg website/app is to only return most dugg posts in past day
        },
        'sort': (sort ?? Platform.digg.postsFeedOptions.options.first).id,
        'after': ?pageToken
      }
    );
  }

  @override
  Future<Post> getPost(GraphQlClientHelper clientHelper, String id) async {
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query PostDetails($postWhere: PostWhere!) {

          posts(first: 1, where: $postWhere) {
            edges {
              node {
                ...PostFragment
              }
            }
          }

        }
        '''
        + postFragment
      ),
      variables: {
        'postWhere': {
          '_id_EQ': id,
        }
      }
    );
    final response = await clientHelper.query(queryOptions);
    return compute(
      (data) => _parsePost((data['posts']['edges'] as List).first['node']),
      response.data!,
    );
  }

  @override
  Future<(List<CommentItem>, Post)> getCommentsAndPost(GraphQlClientHelper clientHelper, String id, String? communityName, String? contextCommentShortId, Map<FeedOptionType, FeedOption>? options) async {
    final postId = '$communityName-$id';
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
          '_id_EQ': postId, 
        },
        'commentWhere': {
          if (contextCommentShortId != null)
            '_id_EQ': '$postId-$contextCommentShortId'
          else
            'postId_EQ': postId
        },
        'sort': (sort ?? Platform.digg.postCommentsFeedOptions.options.first).id
      }
    );
    final response = await clientHelper.query(queryOptions);
    return compute(
      (data) {
        final postData = (data['posts']['edges'] as List).first['node'];
        final commentsData = data['comments'];
        final post = _parsePost(postData);
        final comments = _parseComments(commentsData['edges'], post.community, postData['author']['_id'], 0);
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
        return (comments, post);
      },
      response.data!,
    );
  }

  @override
  Future<(List<CommentItem>, Post?)> getCommentsAndMaybePost(GraphQlClientHelper clientHelper, String id, String? communityName, String? contextCommentShortId, Map<FeedOptionType, FeedOption>? options) => getCommentsAndPost(clientHelper, id, communityName, contextCommentShortId, options);

  @override
  Future<List<CommentItem>> getMoreComments(GraphQlClientHelper clientHelper, String id, int? depth, String pageToken, Map<FeedOptionType, FeedOption>? options) async {
    final sort = options?[FeedOptionType.sort];
    final gql.QueryOptions queryOptions = gql.QueryOptions(
      document: gql.gql(r'''
        query MoreComments($first: Int, $postWhere: PostWhere!, $commentWhere: CommentWhere!, $sort: CommentSort, $after: String) {

          posts(first: 1, where: $postWhere) {
            edges {
              node {
                commentCount
                author {
                  _id
                }
                community {
                  _id
                  slug
                }
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

    final response = await clientHelper.query(queryOptions);
    return compute(
      (data) {
        final Map<String, dynamic> postData = data['posts']['edges'][0]['node'];
        final Map<String, dynamic> communityData = postData['community'];
        final List edges = data['comments']['edges'];
        final Map<String, dynamic> pageInfo = data['comments']['pageInfo'];
        final List<CommentItem> comments = _parseComments(
          edges,
          Community(
            platform: Platform.digg,
            host: Platform.digg.preferredHost!,
            name: communityData['slug'],
            id: communityData['_id'],
          ),
          postData['author']['_id'],
          depth ?? 0
        );
        if (pageInfo['hasNextPage']) {
          comments.add(
            LoadMoreComment(
              depth: 0,
              count: postData['commentCount'] - comments.length,
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
  MultiPartFeedResponse<dynamic, List<UserStat>> getUserDetails(GraphQlClientHelper clientHelper, String id, Map<FeedOptionType, FeedOption>? options) {
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
        
        final responseFuture = clientHelper.query(queryOptions);
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
                      _id
                      title
                      community {
                        _id
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
        
        final responseFuture = clientHelper.query(queryOptions);
        return MultiPartFeedResponse(
          items: responseFuture.then((response) => _parseCommentsResult(response.data!)),
          other: responseFuture.then((response) => _parseAllUserStats(response.data!['accounts']['edges'].first['node'])),
        );
      case _:
        throw UnimplementedError();
    }
  }

  @override
  Future<PagedItems<dynamic>> getUserItems(GraphQlClientHelper clientHelper, String id, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
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
            'after': ?pageToken
          }
        );
        final response = await clientHelper.query(queryOptions);
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
                      _id
                      title
                      community {
                        _id
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
            'after': ?pageToken
          },
        );
        final response = await clientHelper.query(queryOptions);
        return compute(_parseCommentsResult, response.data!);
      case _:
        throw UnimplementedError();
    }
  }

  @override
  Future<PagedItems<dynamic>> getSearchResults(GraphQlClientHelper clientHelper, String query, String? communityName, String? pageToken, Map<FeedOptionType, FeedOption>? options) async {
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
          'after': ?pageToken,
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
            return CommunityDetails(
              community: Community(
                platform: Platform.digg,
                host: Platform.digg.preferredHost!,
                name: node['slug'],
                id: node['_id'],
              ),
              shortDescription: node['description'],
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
          'after': ?pageToken,
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
              platform: Platform.digg,
              host: Platform.digg.preferredHost!,
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
          'after': ?pageToken,
        },
      );
      parseFn = _parsePostsResult;
    }
    final response = await clientHelper.query(queryOptions);
    return compute(parseFn, response.data!);
  }

  @override
  Future<Post> resolveGlobalToLocalPost(GraphQlClientHelper clientHelper, String globalId) {
    throw UnimplementedError();
  }

  @override
  Future<LoggedInUser> getLoggedInUser(GraphQlClientHelper clientHelper) {
    throw UnimplementedError();
  }
  
  @override
  Future<List<Community>> getSubscribedCommunities(GraphQlClientHelper clientHelper) {
    throw UnimplementedError();
  }

  @override
  Future<void> subscribeToCommunity(GraphQlClientHelper clientHelper, String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> unsubscribeFromCommunity(GraphQlClientHelper clientHelper, String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> votePost(GraphQlClientHelper clientHelper, String id, bool? up) {
    throw UnimplementedError();
  }

  @override
  Future<void> voteComment(GraphQlClientHelper clientHelper, String id, bool? up) {
    throw UnimplementedError();
  }

  @override
  Future<Comment> postComment(GraphQlClientHelper clientHelper, String parentId, String text) {
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteComment(GraphQlClientHelper clientHelper, String id) {
    throw UnimplementedError();
  }

  Future<PagedItems<Post>> _getPostsRecursive(GraphQlClientHelper clientHelper, Map<String, dynamic> variables, {List<Post>? accumulatedPosts, int depth = 0}) async {
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
    final response = await clientHelper.query(queryOptions);
    final postsData = response.data!['posts'];
    final Map<String, dynamic> pageInfo = postsData['pageInfo'];
    final List<Post> allPosts = [...?accumulatedPosts, ...postsData['edges'].map((edge) => _parsePost(edge['node']))];
    if (allPosts.length < resultsLimit && pageInfo['hasNextPage'] == true && pageInfo['endCursor'] != null && depth < Settings.diggPostsFetchDepth.value + 1) {
      return _getPostsRecursive(
        clientHelper,
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

  PagedItems<Post> _parsePostsResult(Map<String, dynamic> data) {
    final postsData = data['posts'];
    final List edges = postsData['edges'];
    final pageInfo = postsData['pageInfo'];
    return PagedItems(
      items: edges.map((edge) => _parsePost(edge['node'])).toList(),
      pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
    );
  }

  PagedItems<Comment> _parseCommentsResult(Map<String, dynamic> data) {
    final comments = data['comments'];
    final pageInfo = comments['pageInfo'];
    return PagedItems(
      items: (comments['edges'] as List).map((edge) => _parseComment(edge['node'], null, null, 0)).toList(),
      pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
    );
  }

  Post _parsePost(Map<String, dynamic> json) {
    final String fullId = json['_id'];
    final Map<String, dynamic> communityData = json['community'];
    final Map<String, dynamic> authorData = json['author'];
    final externalContent = json['externalContent'];
    final communityName = communityData['slug'];
    final List attachments = json['attachments'];
    final idLastDashIndex = fullId.lastIndexOf('-');
    final id = fullId.substring(idLastDashIndex + 1);
    final permalink = '/${fullId.substring(0, idLastDashIndex)}/$id/${json['slug']}';
    ContentType? contentType;
    final String linkUrl;
    final String linkDomain;
    final String? thumbnailUrl;
    final Size? mediaSize;
    final List<GalleryImage>? galleryImages;
    if (attachments.isNotEmpty) {
      linkUrl = attachments.first['url'];
      thumbnailUrl = _getThumbnailUrl(Uri.parse(linkUrl));
      if (attachments.length > 1) {
        contentType = ContentType.imageGallery;
        linkDomain = 'image/gallery';
        mediaSize = null;
        galleryImages = attachments.map((a) => GalleryImage(url: a['url'], size: Size((a['width'] as num).toDouble(), (a['height'] as num).toDouble()))).toList();
      }
      else {
        final attachment = attachments.first;
        final num? width = attachment['width'];
        contentType = ContentType.image;
        linkDomain = 'image';
        mediaSize = width != null ? Size(width.toDouble(), (attachment['height'] as num).toDouble()) : null;
        galleryImages = null;
      }
    }
    else {
      mediaSize = null;
      galleryImages = null;
      if (externalContent != null) {
        linkUrl = externalContent['url'];
        final host = Uri.parse(linkUrl).host;
        final List parts = host.split('.');
        final imageUrl = externalContent['imageUrl'];
        linkDomain = parts.length >= 2 ? parts.sublist(parts.length - 2).join('.') : host;
        if (imageUrl != null) {
          final uri = Uri.parse(imageUrl);
          thumbnailUrl = uri.host.endsWith('.imgix.net') ? _getThumbnailUrl(uri) : imageUrl;
        }
        else {
          thumbnailUrl = null;
        }
      }
      else {
        contentType = ContentType.local;
        linkUrl = '$_baseUrl$permalink';
        linkDomain = 'self.$communityName';
        thumbnailUrl = null;
      }
    }
    return Post(
      community: Community(
        platform: Platform.digg,
        host: Platform.digg.preferredHost!,
        name: communityName,
        id: communityData['_id'],
      ),
      localId: fullId,
      localHost: Platform.digg.preferredHost!,
      shortLocalId: id,
      globalId: fullId,
      localUrlPath: permalink,
      authorId: authorData['_id'],
      authorHost: Platform.digg.preferredHost!,
      authorName: authorData['username'],
      contentType: contentType,
      score: json['score'],
      timestampMs: DateTime.tryParse(json['createdDate'])?.millisecondsSinceEpoch ?? 0,
      title: (json['title'] as String).trim(),
      body: json['text'],
      bodyHtml: _parsePmToHtml(json['pm']),
      commentCount: json['commentCount'],
      linkUrl: linkUrl,
      linkDomain: linkDomain,
      thumbnailUrl: thumbnailUrl,
      mediaSize: mediaSize,
      galleryImages: galleryImages,
      isRemoved: false,
      isStickied: false,
      isNsfw: json['nsfw'],
      vote: null
    );
  }

  String _getThumbnailUrl(Uri uri) {
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

  List<CommentItem> _parseComments(List<dynamic> children, Community? community, String postAuthorId, int depth) {
    final List<CommentItem> comments = [];
    for (int i = 0; i < children.length; i++) {
      final item = children[i];
      final Map<String, dynamic> data = (item is Map && item.containsKey('node')) ? item['node'] : item as Map<String, dynamic>;
      comments.add(_parseComment((item is Map && item.containsKey('node')) ? item['node'] : item as Map<String, dynamic>, community, postAuthorId, depth));
      if (depth < 4) {
        final List? replyComments = data['comments'];
        if (replyComments != null && replyComments.isNotEmpty) {
          comments.addAll(_parseComments(replyComments, community, postAuthorId, depth + 1));
        }
      }
      else {
        final replyCount = data['commentCount'];
        if (replyCount > 0) {
          final remainingItems = children.sublist(i + 1);
          if (remainingItems.isNotEmpty) {
            final int itemsToTake = replyCount > remainingItems.length ? remainingItems.length : replyCount;
            final childrenToIndent = remainingItems.sublist(0, itemsToTake);
            comments.addAll(_parseComments(childrenToIndent, community, postAuthorId, depth + 1));
            i += itemsToTake;
          }
        }
      }
    }
    return comments; 
  }

  Comment _parseComment(Map<String, dynamic> data, Community? community, String? postAuthorId, int depth) {
    final Community finalCommunity;
    final String? postTitle;
    if (community != null) {
      finalCommunity = community;
      postTitle = null;
    }
    else {
      final postData = data['post'];
      finalCommunity = Community(
        platform: Platform.digg,
        host: Platform.digg.preferredHost!,
        name: postData['community']['slug'],
        id: postData['community']['_id'],
      );  
      postTitle = postData['title'];
    }
    final String id = data['_id'];
    final text = data['text'];
    final author = data['author'];
    final pm = data['pm'];
    final List attachments = data['attachments'];

    final idLastDashIndex = id.lastIndexOf('-');
    final idSecondLastDash = id.lastIndexOf('-', idLastDashIndex - 1);
    final commentId = id.substring(idLastDashIndex + 1);
    final postId = id.substring(idSecondLastDash + 1, idLastDashIndex);

    final String? authorId;
    final String? authorName;
    final bool isSubmitter;
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

    // final String? postTitle;
    // final String? communityId;
    // final String? communityHost;
    // final String? communityName;
    // if (postData != null) {
    //   final communityData = postData['community'];
    //   postTitle = postData['title'];
    //   communityId = communityData['_id'];
    //   communityHost = Platform.digg.host!;
    //   communityName = communityData['slug'];
    // }
    // else {
    //   postTitle = null;
    //   communityId = null;
    //   communityHost = null;
    //   communityName = null;
    // }

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
      community: finalCommunity,
      localId: id,
      shortLocalId: commentId,
      urlPath: '/${id.substring(0, idSecondLastDash)}/$postId/comment/$commentId',
      authorId: null,
      authorName: authorName,
      authorHost: Platform.digg.preferredHost!,
      isDeleted: data['deletedDate'] != null,
      isModerator: false,
      isSubmitter: isSubmitter,
      score: data['score'],
      timestampMs: DateTime.parse(data['createdDate']).millisecondsSinceEpoch,
      text: text,
      textHtml: html.isEmpty ? null : html,
      imageSizes: images,
      vote: null,
      postTitle: postTitle,
      postId: postId,
    );
  }

  // ProseMirror
  static String? _parsePmToHtml(Map<String, dynamic> pm) {
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
    return html.isEmpty ? null : html.toString();
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