import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/models/comment.dart';
import 'package:lurk/models/login.dart';
import 'package:lurk/models/platform_context.dart';
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
    host: 'www.reddit.com',
    color: Color(0xFFFF4500),
    communityLabel: 'subreddit',
    communityPrefixes: ['r/'],
    userPrefix: 'u/',
    homeCommunityName: 'popular',
    rootCommunityName: 'Front page',
    aggregateCommunityNames: {'all', 'popular'},
    canSearchWithinCommunities: true,
    commentImagesAHrefHosts: ['i.redd.it', 'preview.redd.it'],
    communityPathRegex: r'^\/r\/([^\/]+)\/?$',
    userPathRegex: r'^\/(?:u|user)\/([^\/]+)\/?$',
    postPathRegex: r'^\/r\/([^\/]+)\/comments\/[^\/]+(?:\/([^\/]+))?\/?$',
    galleryPathRegex: r'^\/gallery\/([^\/]+)\/?$',
    unresolvedPathRegex: r'^\/r\/[^\/]+\/s\/[^\/]+\/?$',
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
    host: 'digg.com',
    color: Color(0xFF1F65DB),
    communityLabel: 'community',
    communityPrefixes: ['/'],
    userPrefix: '@',
    canSearchWithinCommunities: false,
    communityPathRegex: r'^\/(?![d@]\/|@)([^\/]+)\/?$',
    userPathRegex: r'^\/@([^\/]+)\/?$',
    postPathRegex: r'^\/(?!d\/)([^\/]+)\/[^\/]+(?:\/([^\/]+))?\/?$',
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
    communityPathRegex: r'^\/c\/([^\/]+)\/?$',
    userPathRegex: r'^\/u\/([^\/]+)\/?$',
    postPathRegex: r'^\/post\/([0-9]+)\/?$',
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


  static final Map<(PlatformContext, String?), ApiService> _apiServices = {};

  final Api _api;
  final String? host;
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
  final String communityPathRegex;
  final String userPathRegex;
  final String postPathRegex;
  final String? unresolvedPathRegex;
  final String? galleryPathRegex;
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
    this.host,
    required this.color,
    required this.communityPrefixes,
    required this.userPrefix,
    this.homeCommunityHost,
    this.homeCommunityName,
    this.rootCommunityName,
    this.aggregateCommunityNames,
    required this.canSearchWithinCommunities,
    this.commentImagesAHrefHosts,
    required this.communityPathRegex,
    required this.userPathRegex,
    required this.postPathRegex,
    this.unresolvedPathRegex,
    this.galleryPathRegex,
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

  static ApiService getApi(PlatformContext platformContext, LoggedInUser? activeUser) {
    final activeContext = activeUser?.platformContext ?? platformContext;
    final key = (activeContext, activeUser?.id);
    final existing = _apiServices[key];
    if (existing != null) {
      if (existing.isValid) {
        return existing;
      }
      _apiServices.remove(key)?.dispose();
    }
    final api = ApiService(activeContext.platform, activeContext.host, activeContext.platform._api, activeUser?.id);
    _apiServices[key] = api;
    return api;
  }

  static void destroySession(PlatformContext platformContext, LoggedInUser? activeUser) {
    _apiServices.remove((activeUser?.platformContext ?? platformContext, activeUser?.id))?.dispose();
  }

  static void destroyPlatformSessions(Platform platform) {
    _apiServices.removeWhere((key, service) {
      if (key.$1.platform == platform) {
        service.dispose();
        return true;
      }
      return false;
    });
  }

  String get preferredCommunityPrefix => communityPrefixes.first;

  bool get hasLogin => _api.loginFields != null; 

  List<LoginField>? get loginFields => _api.loginFields;

  String get savedOrDefaultUserAgent => _api.savedOrDefaultUserAgent;

  bool get supportsMultipleHosts => host == null;

  String? getHostFromCommunityName(String? communityName) => communityName != null && hostAndNameFromSearchQueryRegex != null ? RegExp(hostAndNameFromSearchQueryRegex!).firstMatch(communityName)?.group(1) : null;

  String getPostDetailsUrl(Post post) => _api.getPostDetailsUrl(post);

  String getCommentUrl(Comment comment) => _api.getCommentUrl(comment);

  String getFullCommunityName(String host, String? communityName) => _getFullName(host, preferredCommunityPrefix, communityName ?? '');

  String getFullUserName(String host, String userName) => _getFullName(host, userPrefix, userName);

  String getPrefixedUsername(String username) => '$userPrefix$username';

  String? getCommunityNameFromPath(String urlPath) => RegExp(communityPathRegex).firstMatch(urlPath)?.group(1);
  
  String? getUserNameFromPath(String urlPath) => RegExp(userPathRegex).firstMatch(urlPath)?.group(1);

  PostUrlInfo? getPostUrlInfoFromPath(String urlPath) {
    final match = RegExp(postPathRegex).firstMatch(urlPath);
    if (match != null && match.groupCount >= 1) {
      final titleSlug = match.group(2);
      return PostUrlInfo(
        communityName: match.group(1)!,
        inferredTitle: titleSlug != null ? titleSlug[0].toUpperCase() + titleSlug.substring(1).replaceAll(RegExp(r'[_-]+'), ' ') : null 
      );
    }
    return null;
  }

  bool isGallery(String urlPath) => galleryPathRegex != null && RegExp(galleryPathRegex!).hasMatch(urlPath);

  bool isUnresolved(String urlPath) => unresolvedPathRegex != null && RegExp(unresolvedPathRegex!).hasMatch(urlPath);

  String _getFullName(String host, String prefix, String name) => '$prefix$name${supportsMultipleHosts ? '@$host' : ''}';

  List<TextInputFormatter> get communityNameInputFormatters => _getNameInputFormatters(communityNameTypingRegex);

  List<TextInputFormatter> get userNameInputFormatters => _getNameInputFormatters(userNameTypingRegex);

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