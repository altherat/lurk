import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post_details.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user_stat.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/settings.dart';

class DiggApi extends Api {

  static const _baseUrl = 'https://digg.com';
  static const _baseUrlGraphQl = 'https://apineapple-prod.digg.com/graphql';
  static const _headers = {
    'Accept': 'application/graphql-response+json',
    'Content-Type': 'application/json',
  };
  static const resultsLimit = 30;
  
  late gql.GraphQLClient _client;

  DiggApi() {
    _client = gql.GraphQLClient(
      link: gql.Link.function((request, [forward]) {
        return forward!(
          request.updateContextEntry<gql.HttpLinkHeaders>(
            (headers) => gql.HttpLinkHeaders(
              headers: {
                ...?headers?.headers,
                ...getHeaders(DiggApi._headers),
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
  String getPostDetailsUrl(Post post) => '$_baseUrl${post.urlPath}';

  @override
  String getCommentUrl(Post post, Comment comment) => '$_baseUrl/${post.community.name}/${post.id.split('-')[1]}/comment/${comment.id.split('-')[2]}';

  @override
  Future<PagedResult<Post>> getPosts(String? id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    debugPrint('[Digg] getPosts: id=$id, options=[${options?.values.map((option) => option.apiValue).join(', ')}], pageToken=$pageToken');
    final sort = options?[FeedOptionType.sort];
    return _getPostsRecursive({
      'first': resultsLimit,
      'where': {
        'isPersonalized': false,
        if (id != null)
          'community': {'slug_EQ': id},
        if (sort?.apiValue == 'MOST_DUGG')
          'publishedDate_GT': DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String(), // Current functionality of Digg website/app is to only return most dugg posts in past day
      },
      'sort': (sort ?? Platform.digg.postsFeedOptions.options.first).apiValue,
      if (pageToken != null)
        'after': pageToken
    });
  }

  @override
  Future<PostDetails> getPostDetailsFromUrl(String url, {Map<FeedOptionType, FeedOption>? options}) => getPostDetailsFromId(Uri.parse(url).pathSegments[1]);

  @override
  Future<PostDetails> getPostDetailsFromId(String id, {Map<FeedOptionType, FeedOption>? options}) async {
    // debugPrint('[Digg] getPostDetailsFromId: id=$id, options=[${options?.values.map((option) => option.apiValue).join(', ')}]');
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
          'postId_EQ': id,
        },
        'sort': (sort ?? Platform.digg.postCommentsFeedOptions.options.first).apiValue
      }
    );
    final response = await _client.query(queryOptions);
    return compute(_parsePostDetails, response.data!);
  }

  @override
  Future<List<CommentItem>> getMoreComments(String id, String pageToken, {int? level, Map<FeedOptionType, FeedOption>? options}) async {
    // debugPrint('[Digg] getMoreComments: id=$id, pageToken=$pageToken, options=[${options?.values.map((option) => option.apiValue).join(', ')}]');
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
        'sort': (sort ?? Platform.digg.postCommentsFeedOptions.options.first).apiValue,
        'after': pageToken,
      },
    );

    final response = await _client.query(queryOptions);
    return compute(
      (data) {
        final List edges = data['comments']['edges'];
        final Map<String, dynamic> pageInfo = data['comments']['pageInfo'];
        final List<CommentItem> comments = _parseComments(edges, '', level ?? 0);
        if (pageInfo['hasNextPage']) {
          comments.add(
            LoadMoreComment(
              level: 0,
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
    // debugPrint('[Digg] getUserDetails: id=$id, options=[${options?.values.map((option) => option.apiValue).join(', ')}]');
    final DiggUserFeedType type = options?[FeedOptionType.type]?.apiValue ?? Platform.digg.userFeedOptions.options.first.apiValue;
    final FeedOption? sort = options?[FeedOptionType.sort];
    switch (type) {
      case DiggUserFeedType.posts:
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
              'sort': sort.apiValue
          }
        );
        
        final responseFuture = _client.query(queryOptions);
        return UserDetailsResponse(
          stats: responseFuture.then((response) => _parseUserStats(response.data!['accounts']['edges'].first['node'])),
          items: responseFuture.then((response) => _parsePostsResult(response.data!))
        );
      case DiggUserFeedType.comments:
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
              'sort': sort.apiValue
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
    }
  }

  @override
  Future<PagedResult<dynamic>> getUserItems(String id, {Map<FeedOptionType, FeedOption>? options, String? pageToken}) async {
    // debugPrint('[Digg] getUserItems: id=$id, options=[${options?.values.map((option) => option.apiValue).join(', ')}], pageToken=$pageToken');
    final DiggUserFeedType type = options?[FeedOptionType.type]?.apiValue ?? Platform.digg.userFeedOptions.options.first.apiValue;
    final FeedOption? sort = options?[FeedOptionType.sort];
    switch (type) {
      case DiggUserFeedType.posts:
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
              'sort': sort.apiValue,
            if (pageToken != null)
              'after': pageToken
          }
        );
        
        final response = await _client.query(queryOptions);
        return compute(_parsePostsResult, response.data!);
      case DiggUserFeedType.comments:
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
              'sort': sort.apiValue,
            if (pageToken != null)
              'after': pageToken
          },
        );
        
        final response = await _client.query(queryOptions);
        return compute(_parseCommentsResult, response.data!);
    }
  }

  Future<PagedResult<Post>> _getPostsRecursive(Map<String, dynamic> variables, {List<Post>? accumulatedPosts, int depth = 0}) async {
    // debugPrint('[Digg] _getPostsRecursive: variables=[${variables.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}], posts=${accumulatedPosts?.length}, depth=$depth');
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

    // debugPrint('[Digg] _getPostsRecursive posts found: ${allPosts.length}');
    return PagedResult(
      items: allPosts,
      pageToken: pageInfo['hasNextPage'] ? pageInfo['endCursor'] : null,
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
    final urlPath = '/${id.replaceAll('-', '/')}/${json['slug']}';
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
        url = '$_baseUrl$urlPath';
        domain = 'self.digg';
        thumbnailUrl = null;
      }
      galleryImageUrls = [];
    }
    return Post(
      community: Community(
        platform: Platform.digg,
        name: json['community']['name'].toLowerCase()
      ),
      id: id,
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
      urlPath: urlPath,
      thumbnailUrl: thumbnailUrl,
      isGallery: attachments.length > 1,
      isDeleted: json['deletedDate'] != null,
      galleryImageUrls: galleryImageUrls,
    );
  }

  static PostDetails _parsePostDetails(Map<String, dynamic> data) {
    final postData = (data['posts']['edges'] as List).first['node'];
    final commentsData = data['comments'];
    final post = _parsePost(postData);
    final comments = _parseComments(commentsData['edges'], postData['author']['_id']);
    final pageInfo = commentsData['pageInfo'];
    if (pageInfo['hasNextPage']) {
      comments.add(
        LoadMoreComment(
          level: 0,
          count: post.commentCount - comments.length,
          pageToken: pageInfo['endCursor']
        )
      );
    }
    return PostDetails(
      post: post,
      comments: comments,
    );
  }

  static List<CommentItem> _parseComments(List<dynamic> children, String postAuthorId, [int level = 0]) {
    final List<CommentItem> comments = [];

    for (int i = 0; i < children.length; i++) {
      final item = children[i];
      final Map<String, dynamic> data = (item is Map && item.containsKey('node')) ? item['node'] : item as Map<String, dynamic>;
      comments.add(_parseComment((item is Map && item.containsKey('node')) ? item['node'] : item as Map<String, dynamic>, level, postAuthorId));
      if (level < 4) {
        final List? replyComments = data['comments'];
        if (replyComments != null && replyComments.isNotEmpty) {
          comments.addAll(_parseComments(replyComments, postAuthorId, level + 1));
        }
      }
      else {
        final replyCount = data['commentCount'];
        if (replyCount > 0) {
          final remainingItems = children.sublist(i + 1);
          if (remainingItems.isNotEmpty) {
            final int itemsToTake = replyCount > remainingItems.length ? remainingItems.length : replyCount;
            final childrenToIndent = remainingItems.sublist(0, itemsToTake);
            comments.addAll(_parseComments(childrenToIndent, postAuthorId, level + 1));
            i += itemsToTake;
          }
        }
      }

    }

    return comments; 
  }

  static Comment _parseComment(Map<String, dynamic> data, [int level = 0, String? postAuthorId]) {
    final text = data['text'];
    final author = data['author'];
    final postData = data['post'];
    final pm = data['pm'];
    final List attachments = data['attachments'];
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
      level: level,
      id: data['_id'],
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

  List<UserStat> _parseUserStats(Map<String, dynamic> data) {
    return [
      DateTimeUserStat(
        label: 'Joined',
        value: DateTime.parse(data['createdDate'])
      ),
      NumberUserStat(
        label: 'Total score',
        value: data['score']
      ),
      NumberUserStat(
        label: 'Diggs given',
        value: data['diggsGiven']
      ),
      NumberUserStat(
        label: 'Post count',
        value: data['postCount'],
      ),
      NumberUserStat(
        label: 'Comment count',
        value: data['commentCount']
      )
    ];
  }
  
}