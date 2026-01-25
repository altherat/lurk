import 'dart:ui';

import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/digg.dart';
import 'package:lurk/services/api/reddit.dart';

enum Platform {
  
  reddit(
    api: RedditApi(),
    domains: ['reddit.com', 'redd.it'],
    communityPath: r'^\/r\/([^\/]+)\/?$',
    userPath: r'^\/(?:u|user)\/([^\/]+)\/?$',
    postPath: r'^\/r\/([^\/]+)\/comments\/([^\/]+)',
    galleryPath: r'^\/gallery\/([^\/]+)\/?$',
    color: Color(0xFFFF4500),
    communityLabel: 'subreddit',
    communityPrefix: 'r/',
    communityHome: 'popular',
    userPrefix: 'u/',
    postsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      [
        FeedOption('Hot', id: 'hot'),
        FeedOption('New', id: 'new'),
        FeedOption('Top', id: 'top', subGroup: _redditPostsFeedTimeOptions),
        FeedOption('Rising', id: 'rising'),
        FeedOption('Controversial', id: 'controversial', subGroup: _redditPostsFeedTimeOptions)
      ]
    ),
    postCommentsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      [
        FeedOption('Best', id: 'best'),
        FeedOption('Top', id: 'top'),
        FeedOption('New', id: 'new'),
        FeedOption('Controversial', id: 'controversial'),
        FeedOption('Old', id: 'old'),
        FeedOption('Q&A', id: 'qa')
      ],
    ),
    userFeedOptions: FeedOptionsGroup(
      FeedOptionType.type,
      [
        FeedOption('Overview', id: UserFeedType.all, subGroup: _redditUserFeedSortOptions),
        FeedOption('Posts', id: UserFeedType.posts, subGroup: _redditUserFeedSortOptions),
        FeedOption('Comments', id: UserFeedType.comments, subGroup: _redditUserFeedSortOptions)
      ]
    ),
  ),

  digg(
    api: DiggApi(),
    domains: ['digg.com'],
    communityPath: r'^\/(?!d\/)([^\/]+)\/?$',
    userPath: r'^\/@([^\/]+)\/?$',
    postPath: r'^\/(?!d\/)([^\/]+)\/([^\/]+)',
    color: Color(0xFF1F65DB),
    communityLabel: 'community',
    communityPrefix: '/',
    userPrefix: '@',
    postsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      [
        FeedOption('Trending', id: 'TRENDING'),
        FeedOption('Most dugg', id: 'MOST_DUGG'),
        FeedOption('Latest', id: 'RECENT'),
        FeedOption('Heating up', id: 'HEATING_UP'),
      ],
    ),
    postCommentsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      [
        FeedOption('Most dugg', id: {'score': 'DESC'}),
        FeedOption('Most buried', id: {'score': 'ASC'}),
        FeedOption('Newest', id: {'createdDate': 'DESC'}),
        FeedOption('Oldest', id: {'createdDate': 'ASC'})
      ],
    ),
    userFeedOptions: FeedOptionsGroup(
      FeedOptionType.type,
      [
        FeedOption(
          'Posts',
          id: UserFeedType.posts,
          subGroup: FeedOptionsGroup(
            FeedOptionType.sort,
            [
              FeedOption('Latest', id: 'RECENT'),
              FeedOption('Most dugg', id: 'MOST_DUGG'),
              FeedOption('Trending', id: 'TRENDING')
            ]
          )
        ),
        FeedOption(
          'Comments',
          id: UserFeedType.comments,
          subGroup: FeedOptionsGroup(
            FeedOptionType.sort,
            [
              FeedOption('Newest', id: {'createdDate': 'DESC'}),
              FeedOption('Oldest', id: {'createdDate': 'ASC'}),
              FeedOption('Most dugg', id: {'score': 'DESC'}),
              FeedOption('Most buried', id: {'score': 'ASC'})
            ]
          )
        )
      ]
    )
  );

  final Api api;
  final List<String> domains;
  final String communityPath;
  final String userPath;
  final String postPath;
  final String? galleryPath;
  final Color color;
  final String communityLabel;
  final String communityPrefix;
  final String? communityHome;
  final String userPrefix;
  final FeedOptionsGroup postsFeedOptions;
  final FeedOptionsGroup postCommentsFeedOptions;
  final FeedOptionsGroup userFeedOptions;

  const Platform({
    required this.api,
    required this.domains,
    required this.communityPath,
    required this.userPath,
    required this.postPath,
    this.galleryPath,
    required this.color,
    required this.communityLabel,
    required this.communityPrefix,
    this.communityHome,
    required this.userPrefix,
    required this.postsFeedOptions,
    required this.postCommentsFeedOptions,
    required this.userFeedOptions,
  });

  static Platform? forHost(String host) {
    for (var platform in Platform.values) {
      for (var domain in platform.domains) {
        if (host == domain || host.endsWith('.$domain')) {
          return platform;
        }
      }
    }
    return null;
  }

  static Platform? forUrl(String url) => forHost(Uri.parse(url).host);

  String? getCommunityName(String urlPath) => RegExp(communityPath).firstMatch(urlPath)?.group(1);
  
  String? getUserName(String urlPath) => RegExp(userPath).firstMatch(urlPath)?.group(1);

  bool isPostDetails(String urlPath) => RegExp(postPath).hasMatch(urlPath);

  bool isGallery(String urlPath) => galleryPath != null && RegExp(galleryPath!).hasMatch(urlPath);
  
}

enum UserFeedType {
  all,
  posts,
  comments
}

const _redditPostsFeedTimeOptions = FeedOptionsGroup(
  FeedOptionType.time,
  [
    FeedOption('Hour', id: 'hour', description: 'Past hour'),
    FeedOption('Day', id: 'day', description: 'Past day'),
    FeedOption('Week', id: 'week', description: 'Past week'),
    FeedOption('Month', id: 'month', description: 'Past month'),
    FeedOption('Year', id: 'year', description: 'Past year'),
    FeedOption('All time',  id: 'all', description: 'All time')
  ]
);

const _redditUserFeedSortOptions = FeedOptionsGroup(
  FeedOptionType.sort,
  [
    FeedOption('New', id: 'new'),
    FeedOption('Hot', id: 'hot'),
    FeedOption('Top', id: 'top', subGroup: _redditPostsFeedTimeOptions),
  ],
);
  

enum FeedOptionType {

  type,
  sort('Sort'),
  time('Time');

  final String? label;

  const FeedOptionType([this.label]);
  
}

class FeedOption {

  final String label;
  final String? _description;
  final dynamic id;
  final FeedOptionsGroup? subGroup;

  String get description => _description ?? label;

  const FeedOption(
    this.label, {
    this.id,
    String? description,
    this.subGroup
  }) : _description = description;

@override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedOption &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          id == other.id;

  @override
  int get hashCode => label.hashCode ^ id.hashCode;

}

class FeedOptionsGroup {

  final FeedOptionType type;
  final List<FeedOption> options;

  const FeedOptionsGroup(
    this.type,
    this.options
  );

  Map<FeedOptionType, FeedOption> get defaults {
    final Map<FeedOptionType, FeedOption> defaults = {};

    void addDefaultSelection(FeedOptionsGroup group) {
      final firstOption = group.options.first;
      defaults[group.type] = firstOption;
      if (firstOption.subGroup != null) {
        addDefaultSelection(firstOption.subGroup!);
      }
    }

    addDefaultSelection(this);
    
    return defaults;
  }

}