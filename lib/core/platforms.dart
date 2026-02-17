import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/services/api.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/digg.dart';
import 'package:lurk/services/api/reddit.dart';

enum Platform {
  
  reddit(
    api: RedditApi(),
    domains: ['reddit.com', 'redd.it'],
    color: Color(0xFFFF4500),
    communityLabel: 'subreddit',
    communityPrefix: 'r/',
    homeCommunityName: 'popular',
    rootCommunityName: 'Front page',
    aggregateCommunityNames: {null, 'all', 'popular'},
    canSearchWithinCommunities: true,
    userPrefix: 'u/',
    communityPath: r'^\/r\/([^\/]+)\/?$',
    userPath: r'^\/(?:u|user)\/([^\/]+)\/?$',
    postPath: r'^\/r\/([^\/]+)\/comments\/[^\/]+(?:\/([^\/]+))?\/?$',
    galleryPath: r'^\/gallery\/([^\/]+)\/?$',
    unresolvedPath: r'^\/r\/[^\/]+\/s\/[^\/]+\/?$',
    communityNameAllowedChars: '_',
    userNameAllowedChars: '_-',
    communityNameValidation: r'^(?=.{3,21}$)[a-zA-Z0-9]([a-zA-Z0-9_]*[a-zA-Z0-9])?$',
    userNameValidation: r'^(?=.{3,20}$)[a-zA-Z0-9][a-zA-Z0-9_-]*$',
    rootPostsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      [
        FeedOption('Best', id: 'best'),
        ..._redditPostFeedOptions
      ]
    ),
    postsFeedOptions: FeedOptionsGroup(
      FeedOptionType.sort,
      _redditPostFeedOptions
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
      FeedOptionType.category,
      [
        FeedOption('Overview', id: UserFeedType.all, subGroup: _redditUserFeedSortOptions),
        FeedOption('Posts', id: UserFeedType.posts, subGroup: _redditUserFeedSortOptions),
        FeedOption('Comments', id: UserFeedType.comments, subGroup: _redditUserFeedSortOptions)
      ]
    ),
    searchFeedOptions: FeedOptionsGroup(
      FeedOptionType.category,
      [
        FeedOption(
          'Posts',
          subGroup: FeedOptionsGroup(
            FeedOptionType.sort,
            [
              FeedOption('Relevance', id: 'relevance'),
              FeedOption('Hot', id: 'hot'),
              FeedOption('Top', id: 'top', subGroup: _redditPostsFeedTimeOptions),
              FeedOption('New', id: 'new'),
              FeedOption('Comments', id: 'comments'),
            ],
          )
        ),
        FeedOption('Subreddits', id: SearchFeedType.communities),
        FeedOption('Users', id: SearchFeedType.users)
      ]
    ),
  ),

  digg(
    api: DiggApi(),
    domains: ['digg.com'],
    color: Color(0xFF1F65DB),
    communityLabel: 'community',
    communityPrefix: '/',
    homeCommunityName: null,
    rootCommunityName: null,
    aggregateCommunityNames: {null},
    canSearchWithinCommunities: false,
    userPrefix: '@',
    communityPath: r'^\/(?![d@]\/|@)([^\/]+)\/?$',
    userPath: r'^\/@([^\/]+)\/?$',
    postPath: r'^\/(?!d\/)([^\/]+)\/[^\/]+(?:\/([^\/]+))?\/?$',
    communityNameAllowedChars: '-',
    userNameAllowedChars: '_-',
    communityNameValidation: r'^$|^(?=.{3,24}$)[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$',
    userNameValidation: r'^[a-zA-Z0-9_-]{2,24}$',
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
      FeedOptionType.category,
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
    ),
    searchFeedOptions: FeedOptionsGroup(
      FeedOptionType.category,
      [
        FeedOption('Posts', id: SearchFeedType.posts),
        FeedOption('Communities', id: SearchFeedType.communities),
        FeedOption('Users', id: SearchFeedType.users)
      ]
    )
  
  );


  static final Map<(Platform, String?), ApiService> _apiServices = {};

  final Api _api;
  final List<String> domains;
  final Color color;
  final String communityLabel;
  final String communityPrefix;
  final String? homeCommunityName;
  final String? rootCommunityName;
  final Set<String?> aggregateCommunityNames;
  final bool canSearchWithinCommunities;
  final String userPrefix;
  final String communityPath;
  final String userPath;
  final String postPath;
  final String? unresolvedPath;
  final String? galleryPath;
  final String communityNameAllowedChars;
  final String userNameAllowedChars;
  final String communityNameValidation;
  final String userNameValidation;
  final FeedOptionsGroup? rootPostsFeedOptions;
  final FeedOptionsGroup postsFeedOptions;
  final FeedOptionsGroup postCommentsFeedOptions;
  final FeedOptionsGroup userFeedOptions;
  final FeedOptionsGroup searchFeedOptions;

  const Platform({
    required Api api,
    required this.domains,
    required this.color,
    required this.communityPrefix,
    required this.homeCommunityName,
    required this.rootCommunityName,
    required this.aggregateCommunityNames,
    required this.canSearchWithinCommunities,
    required this.userPrefix,
    required this.communityPath,
    required this.userPath,
    required this.postPath,
    this.unresolvedPath,
    this.galleryPath,
    required this.communityNameAllowedChars,
    required this.userNameAllowedChars,
    required this.communityNameValidation,
    required this.userNameValidation,
    required this.communityLabel,
    this.rootPostsFeedOptions,
    required this.postsFeedOptions,
    required this.postCommentsFeedOptions,
    required this.userFeedOptions,
    required this.searchFeedOptions
  })  : _api = api;

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

  ApiService getApi(String? userId) {
    final key = (this, userId);
    final existing = _apiServices[key];
    if (existing != null) {
      if (existing.isValid) {
        return existing;
      }
      _apiServices.remove(key)?.dispose();
    }
    final api = ApiService(_api, userId);
    _apiServices[key] = api;
    return api;
  }

  void destroySession(String? userId) {
    _apiServices.remove((this, userId))?.dispose();
  }

  void destroyAllSessions() {
    _apiServices.removeWhere((key, service) {
      if (key.$1 == this) {
        service.dispose();
        return true;
      }
      return false;
    });
  }

  bool get hasLogin => _api.hasLogin;

  String get savedOrDefaultUserAgent => _api.savedOrDefaultUserAgent;

  String getPostDetailsUrl(Post post) => _api.getPostDetailsUrl(post);

  String getCommentUrl(Comment comment) => _api.getCommentUrl(comment);

  String getPrefixedCommunityName(String communityName) => '$communityPrefix$communityName';

  String getPrefixedUsername(String username) => '$userPrefix$username';

  static Platform? forUrl(String url) => forHost(Uri.parse(url).host);

  String? getCommunityNameFromPath(String urlPath) => RegExp(communityPath).firstMatch(urlPath)?.group(1);
  
  String? getUserNameFromPath(String urlPath) => RegExp(userPath).firstMatch(urlPath)?.group(1);

  PostUrlInfo? getPostUrlInfoFromPath(String urlPath) {
    final match = RegExp(postPath).firstMatch(urlPath);
    if (match != null && match.groupCount >= 1) {
      final titleSlug = match.group(2);
      return PostUrlInfo(
        communityName: match.group(1)!.toLowerCase(),
        inferredTitle: titleSlug != null ? titleSlug[0].toUpperCase() + titleSlug.substring(1).replaceAll(RegExp(r'[_-]+'), ' ') : null 
      );
    }
    return null;
  }

  bool isGallery(String urlPath) => galleryPath != null && RegExp(galleryPath!).hasMatch(urlPath);

  bool isUnresolved(String urlPath) => unresolvedPath != null && RegExp(unresolvedPath!).hasMatch(urlPath);

  List<TextInputFormatter> get communityNameInputFormatters => _getNameInputFormatters(communityNameAllowedChars);

  List<TextInputFormatter> get userNameInputFormatters => _getNameInputFormatters(userNameAllowedChars);

  List<TextInputFormatter> _getNameInputFormatters(String allowedChars) => [
    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9${RegExp.escape(allowedChars)}]')),
    _NameInputFormatter(allowedChars)
  ];

}

enum UserFeedType {
  all,
  posts,
  comments
}

enum SearchFeedType {
  posts,
  communities,
  users,
}

const _redditPostFeedOptions = [
  FeedOption('Hot', id: 'hot'),
  FeedOption('New', id: 'new'),
  FeedOption('Top', id: 'top', subGroup: _redditPostsFeedTimeOptions),
  FeedOption('Rising', id: 'rising'),
  FeedOption('Controversial', id: 'controversial', subGroup: _redditPostsFeedTimeOptions)
];

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

  category,
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

enum SearchType {

  community(Icons.groups_2_rounded),
  user(Icons.person_rounded),
  withinCommunity(Icons.public),
  all(Icons.public);

  final IconData icon;

  const SearchType(this.icon);

}

class _NameInputFormatter extends TextInputFormatter {

  final String allowedChars;

  _NameInputFormatter(this.allowedChars);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (allowedChars.isNotEmpty) {
      final escapedChars = RegExp.escape(allowedChars);
      if (RegExp('[$escapedChars]{2,}').hasMatch(text)) {
        return oldValue;
      }
    }
    return text.isNotEmpty && RegExp('[${RegExp.escape(allowedChars)}]').hasMatch(text[0]) ? oldValue : newValue;
  }

}

class PostUrlInfo {

  final String communityName;
  final String? inferredTitle;

  PostUrlInfo({
    required this.communityName,
    required this.inferredTitle
  });

}

enum CommentBehavior {

  expandOrCollapse('Expand/collapse'),
  showToolbar('Show toolbar'),
  showOptions('Show options');

  final String label;

  const CommentBehavior(this.label);

}