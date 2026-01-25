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
        FeedOption('Hot', apiValue: 'hot'),
        FeedOption('New', apiValue: 'new'),
        FeedOption('Top', apiValue: 'top', subGroup: _redditTimeFeedOptions),
        FeedOption('Rising', apiValue: 'rising'),
        FeedOption('Controversial', apiValue: 'controversial', subGroup: _redditTimeFeedOptions)
      ]
    ),
    postCommentsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      [
        FeedOption('Best', apiValue: 'best'),
        FeedOption('Top', apiValue: 'top'),
        FeedOption('New', apiValue: 'new'),
        FeedOption('Controversial', apiValue: 'controversial'),
        FeedOption('Old', apiValue: 'old'),
        FeedOption('Q&A', apiValue: 'qa')
      ],
    ),
    userFeedOptions: FeedOptionsGroup(
      FeedOptionType.type,
      [
        FeedOption('Overview', subGroup: _redditUserFeedOptions),
        FeedOption('Posts', apiValue: 'submitted', subGroup: _redditUserFeedOptions),
        FeedOption('Comments', apiValue: 'comments', subGroup: _redditUserFeedOptions)
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
        FeedOption('Trending', apiValue: 'TRENDING'),
        FeedOption('Most dugg', apiValue: 'MOST_DUGG'),
        FeedOption('Latest', apiValue: 'RECENT'),
        FeedOption('Heating up', apiValue: 'HEATING_UP'),
      ],
    ),
    postCommentsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      [
        FeedOption('Most dugg', apiValue: {'score': 'DESC'}),
        FeedOption('Most buried', apiValue: {'score': 'ASC'}),
        FeedOption('Newest', apiValue: {'createdDate': 'DESC'}),
        FeedOption('Oldest', apiValue: {'createdDate': 'ASC'})
      ],
    ),
    userFeedOptions: FeedOptionsGroup(
      FeedOptionType.type,
      [
        FeedOption(
          'Posts',
          apiValue: DiggUserFeedType.posts,
          subGroup: FeedOptionsGroup(
            FeedOptionType.sort,
            [
              FeedOption('Latest', apiValue: 'RECENT'),
              FeedOption('Most dugg', apiValue: 'MOST_DUGG'),
              FeedOption('Trending', apiValue: 'TRENDING')
            ]
          )
        ),
        FeedOption(
          'Comments',
          apiValue: DiggUserFeedType.comments,
          subGroup: FeedOptionsGroup(
            FeedOptionType.sort,
            [
              FeedOption('Newest', apiValue: {'createdDate': 'DESC'}),
              FeedOption('Oldest', apiValue: {'createdDate': 'ASC'}),
              FeedOption('Most dugg', apiValue: {'score': 'DESC'}),
              FeedOption('Most buried', apiValue: {'score': 'ASC'})
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

enum DiggUserFeedType {
  posts,
  comments
}

const _redditTimeFeedOptions = FeedOptionsGroup(
  FeedOptionType.time,
  [
    FeedOption('Hour', description: 'Past hour', apiValue: 'hour'),
    FeedOption('Day', description: 'Past day', apiValue: 'day'),
    FeedOption('Week', description: 'Past week', apiValue: 'week'),
    FeedOption('Month', description: 'Past month', apiValue: 'month'),
    FeedOption('Year', description: 'Past year', apiValue: 'year'),
    FeedOption('All time', description: 'All time', apiValue: 'all')
  ]
);

const _redditUserFeedOptions = FeedOptionsGroup(
  FeedOptionType.sort,
  [
    FeedOption('New', apiValue: 'new'),
    FeedOption('Hot', apiValue: 'hot'),
    FeedOption('Top', apiValue: 'top', subGroup: _redditTimeFeedOptions),
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
  final dynamic apiValue;
  final FeedOptionsGroup? subGroup;

  String get description => _description ?? label;

  const FeedOption(
    this.label, {
    String? description,
    this.apiValue,
    this.subGroup
  }) : _description = description;

@override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedOption &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          apiValue == other.apiValue;

  @override
  int get hashCode => label.hashCode ^ apiValue.hashCode;

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