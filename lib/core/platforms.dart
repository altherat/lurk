import 'package:flutter/material.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/login.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/services/api.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/services/api/digg.dart';
import 'package:lurk/services/api/lemmy.dart';
import 'package:lurk/services/api/reddit.dart';

enum Platform {
  
  reddit(
    api: RedditApi(),
    hosts: ['www.reddit.com', 'old.reddit.com', 'reddit.com'],
    color: Color(0xFFFF4500),
    communityLabel: 'subreddit',
    communityPrefixes: ['r/'],
    userPrefix: 'u/',
    homeCommunityName: 'popular',
    rootCommunityName: 'Front page',
    aggregateCommunityNames: {'all', 'popular'},
    canSearchWithinCommunities: true,
    commentImagesAHrefHosts: ['i.redd.it', 'preview.redd.it'],
    communityUrlRegex: r'^https:\/\/((www|old)\.)?reddit\.com\/r\/(?<communityName>[a-zA-Z0-9_]{3,})\/?$',
    communityPathRegex: r'^\/r\/(?<communityName>[a-zA-Z0-9_]{3,})\/?$',
    postDetailsUrlRegex: r'^https:\/\/((www|old)\.)?reddit\.com\/r\/(?<communityName>[a-zA-Z0-9_]{3,})\/comments\/(?<postId>[a-z0-9]+)(?:\/(?<slug>[a-z0-9_]*))?(?:\/(?<commentId>[a-z0-9]+))?\/?$',
    postDetailsPathRegex: r'^\/r\/(?<communityName>[a-zA-Z0-9_]{3,})\/comments\/(?<postId>[a-z0-9]+)(?:\/(?<slug>[a-z0-9_]*))?(?:\/(?<commentId>[a-z0-9]+))?\/?$',
    userDetailsUrlRegex: r'^https:\/\/((www|old)\.)?reddit\.com\/(?:user|u)\/(?<userName>[a-zA-Z0-9_-]{3,20})\/?$',
    userDetailsPathRegex: r'^\/(?:user|u)\/(?<userName>[a-zA-Z0-9_-]{3,20})\/?$',
    imageGalleryUrlRegex: r'^https:\/\/((www|old)\.)?reddit\.com\/gallery\/(?<postId>[a-z0-9]+)\/?$',
    imageGalleryPathRegex: r'^\/gallery\/(?<postId>[a-z0-9]+)\/?$',
    imageUrlRegex: r'^https:\/\/(i|preview)\.redd\.it\/.*$',
    videoUrlRegex: r'^https:\/\/v\.redd\.it\/.*$',
    unresolvedPostDetailsUrlRegex: r'^https:\/\/www.reddit\.com\/r\/(?<communityName>[a-zA-Z0-9_]{3,})\/s\/[a-zA-Z0-9]+\/?$',
    unresolvedPostDetailsPathRegex: r'^\/r\/(?<communityName>[a-zA-Z0-9_]{3,})\/s\/[a-zA-Z0-9]+\/?$',
    communityNameCleaningRegexReplacements: [(r'[^a-zA-Z0-9_]', ''), (r'_{2,}', '_'), (r'^_', '')],
    userNameCleaningRegexReplacements: [(r'[^a-zA-Z0-9_-]', ''), (r'_{2,}', '_'), (r'^_', '')],
    communityNameTypingRegex: r'^(?!_)(?!.*_{2,})[a-z0-9_]*$',
    userNameTypingRegex: r'^(?![_-])(?!.*[_-]{2,})[a-z0-9_-]*$',
    communityNameValidationRegex: r'^(?=.{3,21}$)[a-zA-Z0-9]([a-zA-Z0-9_]*[a-zA-Z0-9])?$',
    userNameValidationRegex: r'^(?=.{3,20}$)[a-zA-Z0-9][a-zA-Z0-9_-]*$',
    loginRequiredSettingKeys: ['redditClientId', 'redditRedirectUri'],
    curatedPostsFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.sort,
      options: [
        FeedOption('Best', id: 'best'),
        ..._redditPostsSortFeedOptions
      ]
    ),
    postsFeedOptions: _redditPostsFeedOptionsGroup,
    postCommentsFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.sort,
      options: [
        FeedOption('Best', id: 'best'),
        FeedOption('Top', id: 'top'),
        FeedOption('New', id: 'new'),
        FeedOption('Controversial', id: 'controversial'),
        FeedOption('Old', id: 'old'),
        FeedOption('Q&A', id: 'qa')
      ]
    ),
    userFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.category,
      options: [
        FeedOption('Overview', id: UserFeedType.all, subGroup: _redditUserSortFeedOptionsGroup),
        FeedOption('Posts', id: UserFeedType.posts, subGroup: _redditUserSortFeedOptionsGroup),
        FeedOption('Comments', id: UserFeedType.comments, subGroup: _redditUserSortFeedOptionsGroup)
      ]
    ),
    searchFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.category,
      options: [
        FeedOption(
          'Posts',
          subGroup: FeedOptionsGroup(
            type: FeedOptionType.sort,
            options: [
              FeedOption('Relevance', id: 'relevance'),
              FeedOption('Hot', id: 'hot'),
              FeedOption('Top', id: 'top', subGroup: _redditPostsTimeFeedOptions),
              FeedOption('New', id: 'new'),
              FeedOption('Comments', id: 'comments'),
            ],
          )
        ),
        FeedOption('Subreddits', id: SearchFeedType.communities),
        FeedOption('Users', id: SearchFeedType.users)
      ]
    ),
    searchWithinCommunityFeedOptions: _redditPostsFeedOptionsGroup,
  ),

  digg(
    api: DiggApi(),
    hosts: ['digg.com'],
    color: Color(0xFF1F65DB),
    communityLabel: 'community',
    communityPrefixes: ['/'],
    userPrefix: '@',
    canSearchWithinCommunities: false,
    communityUrlRegex: r'^^https:\/\/digg\.com\/(?!d\/)(?<communityName>[a-z0-9-]{3,24})\/?$',
    communityPathRegex: r'^\/(?!d\/)(?<communityName>[a-z0-9-]{3,24})\/?$',
    postDetailsUrlRegex: r'^https:\/\/digg\.com\/(?!d\/)(?<communityName>[a-z0-9-]{3,24})\/(?<postId>[a-zA-Z0-9]+)(?:\/(?:comment\/(?<commentId>[a-z0-9]+)|(?<slug>[a-z0-9-]+)))?\/?$',
    postDetailsPathRegex: r'^\/(?!d\/)(?<communityName>[a-z0-9-]{3,24})\/(?<postId>[a-zA-Z0-9]+)(?:\/(?:comment\/(?<commentId>[a-z0-9]+)|(?<slug>[a-z0-9-]+)))?\/?$',
    userDetailsUrlRegex: r'^https:\/\/digg\.com\/@(?<userName>[a-zA-Z0-9_-]{2,24})\/?$',
    userDetailsPathRegex: r'^\/@(?<userName>[a-zA-Z0-9_-]{2,24})\/?$',
    imageUrlRegex: r'^https:\/\/digg-posts-prod-\d+\.imgix\.net\/(?<communityName>[a-z-]{3,24})-(?<postId>[a-zA-Z]+)\/.*$',
    communityNameCleaningRegexReplacements: [(r'[^a-zA-Z0-9-]', ''), (r'^-', ''), (r'-$', '')],
    userNameCleaningRegexReplacements: [(r'[^a-zA-Z0-9_-]', '')],
    communityNameTypingRegex: r'^(?!-)(?!.*-{2,})[a-z0-9-]*$',
    userNameTypingRegex: r'^(?![_-])(?!.*[_-]{2,})[a-z0-9_-]*$',
    communityNameValidationRegex: r'^$|^(?=.{3,24}$)[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$',
    userNameValidationRegex: r'^[a-zA-Z0-9_-]{2,24}$',
    postsFeedOptions: _diggPostsSortFeedOptionsGroup,
    postCommentsFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.sort,
      options: [
        FeedOption('Most dugg', id: {'score': 'DESC'}),
        FeedOption('Most buried', id: {'score': 'ASC'}),
        FeedOption('Newest', id: {'createdDate': 'DESC'}),
        FeedOption('Oldest', id: {'createdDate': 'ASC'})
      ],
    ),
    userFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.category,
      options: [
        FeedOption(
          'Posts',
          id: UserFeedType.posts,
          subGroup: FeedOptionsGroup(
            type: FeedOptionType.sort,
            options: [
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
            type: FeedOptionType.sort,
            options: [
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
      type: FeedOptionType.category,
      options: [
        FeedOption('Posts', id: SearchFeedType.posts),
        FeedOption('Communities', id: SearchFeedType.communities),
        FeedOption('Users', id: SearchFeedType.users)
      ]
    ),
    searchWithinCommunityFeedOptions: _diggPostsSortFeedOptionsGroup,
  ),

  lemmy(
    api: LemmyApi(),
    color: Color(0xFF0CAD09),
    communityLabel: 'community',
    communityPrefixes: ['!', 'c/'],
    userPrefix: 'u/',
    homeCommunityHost: 'lemmy.world',
    canSearchWithinCommunities: true,
    communityPathRegex: r'^\/c\/(?<communityName>[a-z0-9._-]+)(?:@(?<communityHostName>[a-z0-9.-]+))?\/?$',
    userDetailsPathRegex: r'^\/u\/(?<userName>[a-z0-9._-]+)(?:@(?<userHostName>[a-z0-9.-]+))?\/?$',
    postDetailsPathRegex: r'^\/post\/(?<postId>[0-9]+)\/?$',
    communityNameCleaningRegexReplacements: [(r'[^a-zA-Z0-9._@-]', ''), (r'^[.-@]', ''), (r'@{2,}', '@'), (r'\.{2,}', '.')],
    userNameCleaningRegexReplacements: [(r'[^a-zA-Z0-9._@-]', ''), (r'^[.-@]', ''), (r'@{2,}', '@'), (r'\.{2,}', '.')],
    communityNameTypingRegex: r'^(?!.*@{2,})(?!.*\.{2,})[a-z0-9_]*(@[a-z0-9._-]*)?$',
    userNameTypingRegex: r'^(?!.*\.{2,})[a-z0-9_]+(@[a-z0-9._-]*)?$',
    communityNameValidationRegex: r'^([a-z0-9_]*)@([a-z0-9.-]+\.[a-z]{2,})$',
    userNameValidationRegex: r'^(?=.{3,}$)[a-zA-Z0-9][a-zA-Z0-9_-]*(?:@[a-zA-Z0-9.-]+\.[a-z]{2,})?$',
    hostAndNameFromSearchQueryRegex: r'^([a-z0-9_]*)@([a-z0-9.-]+\.[a-z]{2,})$',
    curatedPostsFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.type,
      options: [
        FeedOption('All', id: 'All', subGroup: _lemmyPostsSortFeedOptionsGroup),
        FeedOption('Local', id: 'Local', subGroup: _lemmyPostsSortFeedOptionsGroup),
        FeedOption('Subscribed', id: 'Subscribed', requiresLogin: true, subGroup: _lemmyPostsSortFeedOptionsGroup),
      ],
    ),
    postsFeedOptions: _lemmyPostsSortFeedOptionsGroup,
    postCommentsFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.sort,
      options: [
        FeedOption('Top', id: 'Top'),
        FeedOption('Hot', id: 'Hot'),
        FeedOption('New', id: 'New'),
        FeedOption('Old', id: 'Old'),
        FeedOption('Controversial', id: 'Controversial'),
      ],
    ),
    userFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.category,
      options: [
        FeedOption('Overview', id: UserFeedType.all, subGroup: _lemmyUserAndSearchSortFeedOptionsGroup),
        FeedOption('Posts', id: UserFeedType.posts, subGroup: _lemmyUserAndSearchSortFeedOptionsGroup),
        FeedOption('Comments', id: UserFeedType.comments, subGroup: _lemmyUserAndSearchSortFeedOptionsGroup)
      ]
    ),
    searchFeedOptions: FeedOptionsGroup(
      type: FeedOptionType.category,
      options: [
        FeedOption('All', id: 'All', subGroup: _lemmySearchTypeFeedOptionsGroup),
        FeedOption('Posts', id: 'Posts', subGroup: _lemmySearchTypeFeedOptionsGroup),
        FeedOption('Comments', id: 'Comments', subGroup: _lemmySearchTypeFeedOptionsGroup),
        FeedOption('Communities', id: 'Communities', subGroup: _lemmySearchTypeFeedOptionsGroup),
        FeedOption('Users', id: 'Users', subGroup: _lemmySearchTypeFeedOptionsGroup),
      ]
    ),
    searchWithinCommunityFeedOptions: _lemmyPostsSortFeedOptionsGroup,
  );

  // key: (platform, host, userId)
  static final Map<(Platform, String, String?), ApiService> _apiServices = {};

  final Api _api;
  final List<String>? hosts;
  final Color color;
  final String communityLabel;
  final List<String> communityPrefixes;
  final String userPrefix;
  final String? homeCommunityHost;
  final String? homeCommunityName;
  final String? rootCommunityName;
  final Set<String>? aggregateCommunityNames;
  final bool canSearchWithinCommunities;
  final List<String>? commentImagesAHrefHosts;
  final String? communityUrlRegex;
  final String communityPathRegex;
  final String? postDetailsUrlRegex;
  final String postDetailsPathRegex;
  final String? userDetailsUrlRegex;
  final String userDetailsPathRegex;
  final String? imageGalleryUrlRegex;
  final String? imageGalleryPathRegex;
  final String? imageUrlRegex;
  final String? videoUrlRegex;
  final String? unresolvedPostDetailsUrlRegex;
  final String? unresolvedPostDetailsPathRegex;
  final List<(String, String)> communityNameCleaningRegexReplacements;
  final List<(String, String)> userNameCleaningRegexReplacements;
  final String communityNameTypingRegex;
  final String userNameTypingRegex;
  final String communityNameValidationRegex;
  final String userNameValidationRegex;
  final String? hostAndNameFromSearchQueryRegex;
  final List<String>? loginRequiredSettingKeys;
  final FeedOptionsGroup? curatedPostsFeedOptions;
  final FeedOptionsGroup postsFeedOptions;
  final FeedOptionsGroup postCommentsFeedOptions;
  final FeedOptionsGroup userFeedOptions;
  final FeedOptionsGroup searchFeedOptions;
  final FeedOptionsGroup searchWithinCommunityFeedOptions;

  const Platform({
    required Api api,
    this.hosts,
    required this.color,
    required this.communityPrefixes,
    required this.userPrefix,
    this.homeCommunityHost,
    this.homeCommunityName,
    this.rootCommunityName,
    this.aggregateCommunityNames,
    required this.canSearchWithinCommunities,
    this.commentImagesAHrefHosts, 
    this.communityUrlRegex,
    this.postDetailsUrlRegex,
    this.userDetailsUrlRegex,
    this.imageGalleryUrlRegex,
    this.imageGalleryPathRegex,
    this.imageUrlRegex,
    this.videoUrlRegex,
    this.unresolvedPostDetailsUrlRegex,
    this.unresolvedPostDetailsPathRegex,
    required this.communityPathRegex,
    required this.userDetailsPathRegex,
    required this.postDetailsPathRegex,
    required this.communityNameCleaningRegexReplacements,
    required this.userNameCleaningRegexReplacements,
    required this.communityNameTypingRegex,
    required this.userNameTypingRegex,
    required this.communityNameValidationRegex,
    required this.userNameValidationRegex,
    this.hostAndNameFromSearchQueryRegex,
    required this.communityLabel,
    this.loginRequiredSettingKeys,
    this.curatedPostsFeedOptions,
    required this.postsFeedOptions,
    required this.postCommentsFeedOptions,
    required this.userFeedOptions,
    required this.searchFeedOptions,
    required this.searchWithinCommunityFeedOptions,
  })  : _api = api;

  static ApiService getApi(Platform platform, String host, String? userId) {
    final key = (platform, host, userId);
    final existing = _apiServices[key];
    if (existing != null) {
      if (existing.isValid) {
        return existing;
      }
      _apiServices.remove(key)?.dispose();
    }
    final api = ApiService(platform, host, platform._api, userId);
    _apiServices[key] = api;
    return api;
  }

  static void destroySession(Platform platform, String host, LoggedInUser? activeUser) {
    _apiServices.remove(activeUser != null ? (activeUser.platform, activeUser.host, activeUser.id) : (platform, host, null))?.dispose();
  }

  static void destroyPlatformSessions(Platform platform) {
    _apiServices.removeWhere((key, service) {
      if (key.$1 == platform) {
        service.dispose();
        return true;
      }
      return false;
    });
  }

  String? get preferredHost => hosts?.first;

  String get preferredCommunityPrefix => communityPrefixes.first;

  bool get hasLogin => _api.loginFields != null; 

  List<LoginField>? get loginFields => _api.loginFields;

  String get savedOrDefaultUserAgent => _api.savedOrDefaultUserAgent;

  bool get supportsMultipleHosts => preferredHost == null;

  String? getHostFromCommunityName(String? communityName) => communityName != null && hostAndNameFromSearchQueryRegex != null ? RegExp(hostAndNameFromSearchQueryRegex!).firstMatch(communityName)?.group(1) : null;

  String getPostDetailsUrl(Post post) => _api.getPostDetailsUrl(post);

  String getCommentUrl(Comment comment) => _api.getCommentUrl(comment);

  String getPrefixedCommunityName(String? communityName) => _getPrefixedName(preferredCommunityPrefix, communityName);

  String? getCommunityNameAndMaybeHost(String host, String? communityName) => _getNameAndMaybeHost(host, communityName);

  String getPrefixedCommunityNameAndMaybeHost(String host, String? communityName) => _getPrefixedNameAndMaybeHost(host, preferredCommunityPrefix, communityName);

  String getPrefixedUserName(String username) => _getPrefixedName(userPrefix, username);

  String getUserNameAndMaybeHost(String host, String userName) => '$userName${supportsMultipleHosts ? '@$host' : ''}';

  String getPrefixedUserNameAndMaybeHost(String host, String userName) => _getPrefixedNameAndMaybeHost(host, userPrefix, userName);

  String _getPrefixedName(String prefix, String? name) => '$prefix${name ?? ''}';

  String? _getNameAndMaybeHost(String host, String? name) => supportsMultipleHosts ? '${name ?? ''}@$host' : name;

  String _getPrefixedNameAndMaybeHost(String host, String prefix, String? name) => '$prefix${_getNameAndMaybeHost(host, name)}';

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

const _redditPostsFeedOptionsGroup = FeedOptionsGroup(
  type: FeedOptionType.sort,
  options: _redditPostsSortFeedOptions
);

const _redditPostsSortFeedOptions = [
  FeedOption('Hot', id: 'hot'),
  FeedOption('New', id: 'new'),
  FeedOption('Top', id: 'top', subGroup: _redditPostsTimeFeedOptions),
  FeedOption('Rising', id: 'rising'),
  FeedOption('Controversial', id: 'controversial', subGroup: _redditPostsTimeFeedOptions)
];

const _redditPostsTimeFeedOptions = FeedOptionsGroup(
  type: FeedOptionType.time,
  options: [
    FeedOption('Hour', id: 'hour', description: 'Past hour'),
    FeedOption('Day', id: 'day', description: 'Past day'),
    FeedOption('Week', id: 'week', description: 'Past week'),
    FeedOption('Month', id: 'month', description: 'Past month'),
    FeedOption('Year', id: 'year', description: 'Past year'),
    FeedOption('All time',  id: 'all', description: 'All time')
  ]
);

const _redditUserSortFeedOptionsGroup = FeedOptionsGroup(
  type: FeedOptionType.sort,
  options: [
    FeedOption('New', id: 'new'),
    FeedOption('Hot', id: 'hot'),
    FeedOption('Top', id: 'top', subGroup: _redditPostsTimeFeedOptions),
  ],
);

const _diggPostsSortFeedOptionsGroup = FeedOptionsGroup(
  type: FeedOptionType.sort,
  options: [
    FeedOption('Trending', id: 'TRENDING'),
    FeedOption('Most dugg', id: 'MOST_DUGG'),
    FeedOption('Latest', id: 'RECENT'),
    FeedOption('Heating up', id: 'HEATING_UP'),
  ],
);

const _lemmySearchTypeFeedOptionsGroup = FeedOptionsGroup(
  type: FeedOptionType.type,
  options: [
    FeedOption('Local', id: 'Local', subGroup: _lemmyUserAndSearchSortFeedOptionsGroup),
    FeedOption('All', id: 'All', subGroup: _lemmyUserAndSearchSortFeedOptionsGroup),
    FeedOption('Subscribed', id: 'Subscribed', requiresLogin: true, subGroup: _lemmyUserAndSearchSortFeedOptionsGroup),
  ],
);

const _lemmyPostsSortFeedOptionsGroup = FeedOptionsGroup(
  type: FeedOptionType.sort,
  options: [
    FeedOption('Active', id: 'Active'),
    FeedOption('Hot', id: 'Hot'),
    FeedOption('Scaled', id: 'Scaled'),
    FeedOption('Controversial', id: 'Controversial'),
    FeedOption('New', id: 'New'),
    FeedOption('Old', id: 'Old'),
    FeedOption('Most comments', id: 'MostComments'),
    FeedOption('New comments', id: 'NewComments'),
    FeedOption('Top', id: 'Top', subGroup: _lemmyTimeFeedOptionsGroup),
  ]
);

const _lemmyUserAndSearchSortFeedOptionsGroup = FeedOptionsGroup(
  type: FeedOptionType.sort,
  options: [
    FeedOption('New', id: 'New'),
    FeedOption('Old', id: 'Old'),
    FeedOption('Controlversial', id: 'Controversial'),
    FeedOption('Top', id: 'Top', subGroup: _lemmyTimeFeedOptionsGroup),
  ],
);

const _lemmyTimeFeedOptionsGroup = FeedOptionsGroup(
  type: FeedOptionType.time,
  options: [
    FeedOption('Hour', id: 'TopHour'),
    FeedOption('6 hours', id: 'TopSixHour'),
    FeedOption('12 hours', id: 'TopTwelveHour'),
    FeedOption('Day', id: 'TopDay'),
    FeedOption('Week', id: 'TopWeek'),
    FeedOption('Month', id: 'TopMonth'),
    FeedOption('3 months', id: 'TopThreeMonths'),
    FeedOption('6 months', id: 'TopSixMonths'),
    FeedOption('9 months', id: 'TopNineMonths'),
    FeedOption('Year', id: 'TopYear'),
    FeedOption('All', id: 'TopAll'),
  ]
);

enum FeedOptionType {

  category,
  type('Type'),
  sort('Sort'),
  time('Time');

  final String? label;

  const FeedOptionType([this.label]);
  
}

class FeedOption {

  final String label;
  final String? _description;
  final dynamic id;
  final bool requiresLogin;
  final FeedOptionsGroup? subGroup;

  const FeedOption(
    this.label, {
    this.id,
    String? description,
    this.requiresLogin = false,
    this.subGroup,
  }) : _description = description;

  String get description => _description ?? label;

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

  const FeedOptionsGroup({
    required this.type,
    required this.options,
  });

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

enum CommentBehavior {

  expandOrCollapse('Expand/collapse'),
  showToolbar('Show toolbar'),
  showOptions('Show options');

  final String label;

  const CommentBehavior(this.label);

}