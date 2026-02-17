// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CookiesTable extends Cookies with TableInfo<$CookiesTable, Cookie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CookiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expirationTimeMeta = const VerificationMeta(
    'expirationTime',
  );
  @override
  late final GeneratedColumn<DateTime> expirationTime =
      GeneratedColumn<DateTime>(
        'expiration_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [key, value, expirationTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cookies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cookie> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('expiration_time')) {
      context.handle(
        _expirationTimeMeta,
        expirationTime.isAcceptableOrUnknown(
          data['expiration_time']!,
          _expirationTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Cookie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cookie(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      expirationTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiration_time'],
      ),
    );
  }

  @override
  $CookiesTable createAlias(String alias) {
    return $CookiesTable(attachedDatabase, alias);
  }
}

class Cookie extends DataClass implements Insertable<Cookie> {
  final String key;
  final String value;
  final DateTime? expirationTime;
  const Cookie({required this.key, required this.value, this.expirationTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || expirationTime != null) {
      map['expiration_time'] = Variable<DateTime>(expirationTime);
    }
    return map;
  }

  CookiesCompanion toCompanion(bool nullToAbsent) {
    return CookiesCompanion(
      key: Value(key),
      value: Value(value),
      expirationTime: expirationTime == null && nullToAbsent
          ? const Value.absent()
          : Value(expirationTime),
    );
  }

  factory Cookie.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cookie(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      expirationTime: serializer.fromJson<DateTime?>(json['expirationTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'expirationTime': serializer.toJson<DateTime?>(expirationTime),
    };
  }

  Cookie copyWith({
    String? key,
    String? value,
    Value<DateTime?> expirationTime = const Value.absent(),
  }) => Cookie(
    key: key ?? this.key,
    value: value ?? this.value,
    expirationTime: expirationTime.present
        ? expirationTime.value
        : this.expirationTime,
  );
  Cookie copyWithCompanion(CookiesCompanion data) {
    return Cookie(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      expirationTime: data.expirationTime.present
          ? data.expirationTime.value
          : this.expirationTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cookie(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('expirationTime: $expirationTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, expirationTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cookie &&
          other.key == this.key &&
          other.value == this.value &&
          other.expirationTime == this.expirationTime);
}

class CookiesCompanion extends UpdateCompanion<Cookie> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime?> expirationTime;
  final Value<int> rowid;
  const CookiesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.expirationTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CookiesCompanion.insert({
    required String key,
    required String value,
    this.expirationTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Cookie> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? expirationTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (expirationTime != null) 'expiration_time': expirationTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CookiesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime?>? expirationTime,
    Value<int>? rowid,
  }) {
    return CookiesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      expirationTime: expirationTime ?? this.expirationTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (expirationTime.present) {
      map['expiration_time'] = Variable<DateTime>(expirationTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CookiesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('expirationTime: $expirationTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Platform?, String>
  homeCommunityPlatform = GeneratedColumn<String>(
    'home_community_platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Platform?>($SettingsTable.$converterhomeCommunityPlatformn);
  static const VerificationMeta _homeCommunityNameMeta = const VerificationMeta(
    'homeCommunityName',
  );
  @override
  late final GeneratedColumn<String> homeCommunityName =
      GeneratedColumn<String>(
        'home_community_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _showCommentImagesMeta = const VerificationMeta(
    'showCommentImages',
  );
  @override
  late final GeneratedColumn<bool> showCommentImages = GeneratedColumn<bool>(
    'show_comment_images',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_comment_images" IN (0, 1))',
    ),
    defaultValue: const Constant(Constants.defaultShowCommentImages),
  );
  static const VerificationMeta _autoplayVideosMeta = const VerificationMeta(
    'autoplayVideos',
  );
  @override
  late final GeneratedColumn<bool> autoplayVideos = GeneratedColumn<bool>(
    'autoplay_videos',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("autoplay_videos" IN (0, 1))',
    ),
    defaultValue: const Constant(Constants.defaultAutoplayVideos),
  );
  static const VerificationMeta _swipePostsToVoteMeta = const VerificationMeta(
    'swipePostsToVote',
  );
  @override
  late final GeneratedColumn<bool> swipePostsToVote = GeneratedColumn<bool>(
    'swipe_posts_to_vote',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("swipe_posts_to_vote" IN (0, 1))',
    ),
    defaultValue: const Constant(Constants.defaultSwipePostsToVote),
  );
  static const VerificationMeta _swipeCommentsToVoteMeta =
      const VerificationMeta('swipeCommentsToVote');
  @override
  late final GeneratedColumn<bool> swipeCommentsToVote = GeneratedColumn<bool>(
    'swipe_comments_to_vote',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("swipe_comments_to_vote" IN (0, 1))',
    ),
    defaultValue: const Constant(Constants.defaultSwipeCommentsToVote),
  );
  static const VerificationMeta _showCommentVotingEdgesMeta =
      const VerificationMeta('showCommentVotingEdges');
  @override
  late final GeneratedColumn<bool> showCommentVotingEdges =
      GeneratedColumn<bool>(
        'show_comment_voting_edges',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_comment_voting_edges" IN (0, 1))',
        ),
        defaultValue: const Constant(Constants.defaultShowCommentVotingEdges),
      );
  @override
  late final GeneratedColumnWithTypeConverter<CommentBehavior, String>
  commentTapBehavior = GeneratedColumn<String>(
    'comment_tap_behavior',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(Constants.defaultCommentTapBehavior.name),
  ).withConverter<CommentBehavior>($SettingsTable.$convertercommentTapBehavior);
  @override
  late final GeneratedColumnWithTypeConverter<CommentBehavior, String>
  commentLongPressBehavior =
      GeneratedColumn<String>(
        'comment_long_press_behavior',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(Constants.defaultCommentLongPressBehavior.name),
      ).withConverter<CommentBehavior>(
        $SettingsTable.$convertercommentLongPressBehavior,
      );
  static const VerificationMeta _appBarColorMeta = const VerificationMeta(
    'appBarColor',
  );
  @override
  late final GeneratedColumn<int> appBarColor = GeneratedColumn<int>(
    'app_bar_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _useBottomBarMeta = const VerificationMeta(
    'useBottomBar',
  );
  @override
  late final GeneratedColumn<bool> useBottomBar = GeneratedColumn<bool>(
    'use_bottom_bar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_bottom_bar" IN (0, 1))',
    ),
    defaultValue: const Constant(Constants.defaultUseBottomBar),
  );
  static const VerificationMeta _reverseCommunityListMeta =
      const VerificationMeta('reverseCommunityList');
  @override
  late final GeneratedColumn<bool> reverseCommunityList = GeneratedColumn<bool>(
    'reverse_community_list',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reverse_community_list" IN (0, 1))',
    ),
    defaultValue: const Constant(Constants.defaultReverseCommunityList),
  );
  static const VerificationMeta _backOnHomeScreenShowCommunityListMeta =
      const VerificationMeta('backOnHomeScreenShowCommunityList');
  @override
  late final GeneratedColumn<bool> backOnHomeScreenShowCommunityList =
      GeneratedColumn<bool>(
        'back_on_home_screen_show_community_list',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("back_on_home_screen_show_community_list" IN (0, 1))',
        ),
        defaultValue: const Constant(
          Constants.defaultBackOnHomeScreenShowCommunityList,
        ),
      );
  static const VerificationMeta _showPlatformColorAccentsMeta =
      const VerificationMeta('showPlatformColorAccents');
  @override
  late final GeneratedColumn<bool> showPlatformColorAccents =
      GeneratedColumn<bool>(
        'show_platform_color_accents',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_platform_color_accents" IN (0, 1))',
        ),
        defaultValue: const Constant(Constants.defaultShowPlatformColorAccents),
      );
  static const VerificationMeta _showPlatformColorTextAccentsMeta =
      const VerificationMeta('showPlatformColorTextAccents');
  @override
  late final GeneratedColumn<bool> showPlatformColorTextAccents =
      GeneratedColumn<bool>(
        'show_platform_color_text_accents',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_platform_color_text_accents" IN (0, 1))',
        ),
        defaultValue: const Constant(
          Constants.defaultShowPlatformColorTextAccents,
        ),
      );
  static const VerificationMeta _redditCopyOldRedditLinksMeta =
      const VerificationMeta('redditCopyOldRedditLinks');
  @override
  late final GeneratedColumn<bool> redditCopyOldRedditLinks =
      GeneratedColumn<bool>(
        'reddit_copy_old_reddit_links',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reddit_copy_old_reddit_links" IN (0, 1))',
        ),
        defaultValue: const Constant(Constants.defaultRedditCopyOldRedditLinks),
      );
  static const VerificationMeta _redditClientIdMeta = const VerificationMeta(
    'redditClientId',
  );
  @override
  late final GeneratedColumn<String> redditClientId = GeneratedColumn<String>(
    'reddit_client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _redditRedirectUriMeta = const VerificationMeta(
    'redditRedirectUri',
  );
  @override
  late final GeneratedColumn<String> redditRedirectUri =
      GeneratedColumn<String>(
        'reddit_redirect_uri',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _redditDeviceIdMeta = const VerificationMeta(
    'redditDeviceId',
  );
  @override
  late final GeneratedColumn<String> redditDeviceId = GeneratedColumn<String>(
    'reddit_device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _redditUserAgentMeta = const VerificationMeta(
    'redditUserAgent',
  );
  @override
  late final GeneratedColumn<String> redditUserAgent = GeneratedColumn<String>(
    'reddit_user_agent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diggPostsFetchDepthMeta =
      const VerificationMeta('diggPostsFetchDepth');
  @override
  late final GeneratedColumn<int> diggPostsFetchDepth = GeneratedColumn<int>(
    'digg_posts_fetch_depth',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(Constants.diggPostsFetchDepth),
  );
  static const VerificationMeta _diggUserAgentMeta = const VerificationMeta(
    'diggUserAgent',
  );
  @override
  late final GeneratedColumn<String> diggUserAgent = GeneratedColumn<String>(
    'digg_user_agent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SearchType?, String> searchType =
      GeneratedColumn<String>(
        'search_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SearchType?>($SettingsTable.$convertersearchTypen);
  static const VerificationMeta _activeUserIdMeta = const VerificationMeta(
    'activeUserId',
  );
  @override
  late final GeneratedColumn<String> activeUserId = GeneratedColumn<String>(
    'active_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeCommunityPlatform,
    homeCommunityName,
    showCommentImages,
    autoplayVideos,
    swipePostsToVote,
    swipeCommentsToVote,
    showCommentVotingEdges,
    commentTapBehavior,
    commentLongPressBehavior,
    appBarColor,
    useBottomBar,
    reverseCommunityList,
    backOnHomeScreenShowCommunityList,
    showPlatformColorAccents,
    showPlatformColorTextAccents,
    redditCopyOldRedditLinks,
    redditClientId,
    redditRedirectUri,
    redditDeviceId,
    redditUserAgent,
    diggPostsFetchDepth,
    diggUserAgent,
    searchType,
    activeUserId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('home_community_name')) {
      context.handle(
        _homeCommunityNameMeta,
        homeCommunityName.isAcceptableOrUnknown(
          data['home_community_name']!,
          _homeCommunityNameMeta,
        ),
      );
    }
    if (data.containsKey('show_comment_images')) {
      context.handle(
        _showCommentImagesMeta,
        showCommentImages.isAcceptableOrUnknown(
          data['show_comment_images']!,
          _showCommentImagesMeta,
        ),
      );
    }
    if (data.containsKey('autoplay_videos')) {
      context.handle(
        _autoplayVideosMeta,
        autoplayVideos.isAcceptableOrUnknown(
          data['autoplay_videos']!,
          _autoplayVideosMeta,
        ),
      );
    }
    if (data.containsKey('swipe_posts_to_vote')) {
      context.handle(
        _swipePostsToVoteMeta,
        swipePostsToVote.isAcceptableOrUnknown(
          data['swipe_posts_to_vote']!,
          _swipePostsToVoteMeta,
        ),
      );
    }
    if (data.containsKey('swipe_comments_to_vote')) {
      context.handle(
        _swipeCommentsToVoteMeta,
        swipeCommentsToVote.isAcceptableOrUnknown(
          data['swipe_comments_to_vote']!,
          _swipeCommentsToVoteMeta,
        ),
      );
    }
    if (data.containsKey('show_comment_voting_edges')) {
      context.handle(
        _showCommentVotingEdgesMeta,
        showCommentVotingEdges.isAcceptableOrUnknown(
          data['show_comment_voting_edges']!,
          _showCommentVotingEdgesMeta,
        ),
      );
    }
    if (data.containsKey('app_bar_color')) {
      context.handle(
        _appBarColorMeta,
        appBarColor.isAcceptableOrUnknown(
          data['app_bar_color']!,
          _appBarColorMeta,
        ),
      );
    }
    if (data.containsKey('use_bottom_bar')) {
      context.handle(
        _useBottomBarMeta,
        useBottomBar.isAcceptableOrUnknown(
          data['use_bottom_bar']!,
          _useBottomBarMeta,
        ),
      );
    }
    if (data.containsKey('reverse_community_list')) {
      context.handle(
        _reverseCommunityListMeta,
        reverseCommunityList.isAcceptableOrUnknown(
          data['reverse_community_list']!,
          _reverseCommunityListMeta,
        ),
      );
    }
    if (data.containsKey('back_on_home_screen_show_community_list')) {
      context.handle(
        _backOnHomeScreenShowCommunityListMeta,
        backOnHomeScreenShowCommunityList.isAcceptableOrUnknown(
          data['back_on_home_screen_show_community_list']!,
          _backOnHomeScreenShowCommunityListMeta,
        ),
      );
    }
    if (data.containsKey('show_platform_color_accents')) {
      context.handle(
        _showPlatformColorAccentsMeta,
        showPlatformColorAccents.isAcceptableOrUnknown(
          data['show_platform_color_accents']!,
          _showPlatformColorAccentsMeta,
        ),
      );
    }
    if (data.containsKey('show_platform_color_text_accents')) {
      context.handle(
        _showPlatformColorTextAccentsMeta,
        showPlatformColorTextAccents.isAcceptableOrUnknown(
          data['show_platform_color_text_accents']!,
          _showPlatformColorTextAccentsMeta,
        ),
      );
    }
    if (data.containsKey('reddit_copy_old_reddit_links')) {
      context.handle(
        _redditCopyOldRedditLinksMeta,
        redditCopyOldRedditLinks.isAcceptableOrUnknown(
          data['reddit_copy_old_reddit_links']!,
          _redditCopyOldRedditLinksMeta,
        ),
      );
    }
    if (data.containsKey('reddit_client_id')) {
      context.handle(
        _redditClientIdMeta,
        redditClientId.isAcceptableOrUnknown(
          data['reddit_client_id']!,
          _redditClientIdMeta,
        ),
      );
    }
    if (data.containsKey('reddit_redirect_uri')) {
      context.handle(
        _redditRedirectUriMeta,
        redditRedirectUri.isAcceptableOrUnknown(
          data['reddit_redirect_uri']!,
          _redditRedirectUriMeta,
        ),
      );
    }
    if (data.containsKey('reddit_device_id')) {
      context.handle(
        _redditDeviceIdMeta,
        redditDeviceId.isAcceptableOrUnknown(
          data['reddit_device_id']!,
          _redditDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('reddit_user_agent')) {
      context.handle(
        _redditUserAgentMeta,
        redditUserAgent.isAcceptableOrUnknown(
          data['reddit_user_agent']!,
          _redditUserAgentMeta,
        ),
      );
    }
    if (data.containsKey('digg_posts_fetch_depth')) {
      context.handle(
        _diggPostsFetchDepthMeta,
        diggPostsFetchDepth.isAcceptableOrUnknown(
          data['digg_posts_fetch_depth']!,
          _diggPostsFetchDepthMeta,
        ),
      );
    }
    if (data.containsKey('digg_user_agent')) {
      context.handle(
        _diggUserAgentMeta,
        diggUserAgent.isAcceptableOrUnknown(
          data['digg_user_agent']!,
          _diggUserAgentMeta,
        ),
      );
    }
    if (data.containsKey('active_user_id')) {
      context.handle(
        _activeUserIdMeta,
        activeUserId.isAcceptableOrUnknown(
          data['active_user_id']!,
          _activeUserIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      homeCommunityPlatform: $SettingsTable.$converterhomeCommunityPlatformn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}home_community_platform'],
            ),
          ),
      homeCommunityName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_community_name'],
      ),
      showCommentImages: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_comment_images'],
      )!,
      autoplayVideos: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}autoplay_videos'],
      )!,
      swipePostsToVote: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}swipe_posts_to_vote'],
      )!,
      swipeCommentsToVote: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}swipe_comments_to_vote'],
      )!,
      showCommentVotingEdges: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_comment_voting_edges'],
      )!,
      commentTapBehavior: $SettingsTable.$convertercommentTapBehavior.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}comment_tap_behavior'],
        )!,
      ),
      commentLongPressBehavior: $SettingsTable
          .$convertercommentLongPressBehavior
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}comment_long_press_behavior'],
            )!,
          ),
      appBarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}app_bar_color'],
      ),
      useBottomBar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_bottom_bar'],
      )!,
      reverseCommunityList: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reverse_community_list'],
      )!,
      backOnHomeScreenShowCommunityList: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}back_on_home_screen_show_community_list'],
      )!,
      showPlatformColorAccents: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_platform_color_accents'],
      )!,
      showPlatformColorTextAccents: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_platform_color_text_accents'],
      )!,
      redditCopyOldRedditLinks: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reddit_copy_old_reddit_links'],
      )!,
      redditClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reddit_client_id'],
      ),
      redditRedirectUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reddit_redirect_uri'],
      ),
      redditDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reddit_device_id'],
      ),
      redditUserAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reddit_user_agent'],
      ),
      diggPostsFetchDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}digg_posts_fetch_depth'],
      )!,
      diggUserAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}digg_user_agent'],
      ),
      searchType: $SettingsTable.$convertersearchTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}search_type'],
        ),
      ),
      activeUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_user_id'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Platform, String, String>
  $converterhomeCommunityPlatform = const EnumNameConverter<Platform>(
    Platform.values,
  );
  static JsonTypeConverter2<Platform?, String?, String?>
  $converterhomeCommunityPlatformn = JsonTypeConverter2.asNullable(
    $converterhomeCommunityPlatform,
  );
  static JsonTypeConverter2<CommentBehavior, String, String>
  $convertercommentTapBehavior = const EnumNameConverter<CommentBehavior>(
    CommentBehavior.values,
  );
  static JsonTypeConverter2<CommentBehavior, String, String>
  $convertercommentLongPressBehavior = const EnumNameConverter<CommentBehavior>(
    CommentBehavior.values,
  );
  static JsonTypeConverter2<SearchType, String, String> $convertersearchType =
      const EnumNameConverter<SearchType>(SearchType.values);
  static JsonTypeConverter2<SearchType?, String?, String?>
  $convertersearchTypen = JsonTypeConverter2.asNullable($convertersearchType);
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final Platform? homeCommunityPlatform;
  final String? homeCommunityName;
  final bool showCommentImages;
  final bool autoplayVideos;
  final bool swipePostsToVote;
  final bool swipeCommentsToVote;
  final bool showCommentVotingEdges;
  final CommentBehavior commentTapBehavior;
  final CommentBehavior commentLongPressBehavior;
  final int? appBarColor;
  final bool useBottomBar;
  final bool reverseCommunityList;
  final bool backOnHomeScreenShowCommunityList;
  final bool showPlatformColorAccents;
  final bool showPlatformColorTextAccents;
  final bool redditCopyOldRedditLinks;
  final String? redditClientId;
  final String? redditRedirectUri;
  final String? redditDeviceId;
  final String? redditUserAgent;
  final int diggPostsFetchDepth;
  final String? diggUserAgent;
  final SearchType? searchType;
  final String? activeUserId;
  const Setting({
    required this.id,
    this.homeCommunityPlatform,
    this.homeCommunityName,
    required this.showCommentImages,
    required this.autoplayVideos,
    required this.swipePostsToVote,
    required this.swipeCommentsToVote,
    required this.showCommentVotingEdges,
    required this.commentTapBehavior,
    required this.commentLongPressBehavior,
    this.appBarColor,
    required this.useBottomBar,
    required this.reverseCommunityList,
    required this.backOnHomeScreenShowCommunityList,
    required this.showPlatformColorAccents,
    required this.showPlatformColorTextAccents,
    required this.redditCopyOldRedditLinks,
    this.redditClientId,
    this.redditRedirectUri,
    this.redditDeviceId,
    this.redditUserAgent,
    required this.diggPostsFetchDepth,
    this.diggUserAgent,
    this.searchType,
    this.activeUserId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || homeCommunityPlatform != null) {
      map['home_community_platform'] = Variable<String>(
        $SettingsTable.$converterhomeCommunityPlatformn.toSql(
          homeCommunityPlatform,
        ),
      );
    }
    if (!nullToAbsent || homeCommunityName != null) {
      map['home_community_name'] = Variable<String>(homeCommunityName);
    }
    map['show_comment_images'] = Variable<bool>(showCommentImages);
    map['autoplay_videos'] = Variable<bool>(autoplayVideos);
    map['swipe_posts_to_vote'] = Variable<bool>(swipePostsToVote);
    map['swipe_comments_to_vote'] = Variable<bool>(swipeCommentsToVote);
    map['show_comment_voting_edges'] = Variable<bool>(showCommentVotingEdges);
    {
      map['comment_tap_behavior'] = Variable<String>(
        $SettingsTable.$convertercommentTapBehavior.toSql(commentTapBehavior),
      );
    }
    {
      map['comment_long_press_behavior'] = Variable<String>(
        $SettingsTable.$convertercommentLongPressBehavior.toSql(
          commentLongPressBehavior,
        ),
      );
    }
    if (!nullToAbsent || appBarColor != null) {
      map['app_bar_color'] = Variable<int>(appBarColor);
    }
    map['use_bottom_bar'] = Variable<bool>(useBottomBar);
    map['reverse_community_list'] = Variable<bool>(reverseCommunityList);
    map['back_on_home_screen_show_community_list'] = Variable<bool>(
      backOnHomeScreenShowCommunityList,
    );
    map['show_platform_color_accents'] = Variable<bool>(
      showPlatformColorAccents,
    );
    map['show_platform_color_text_accents'] = Variable<bool>(
      showPlatformColorTextAccents,
    );
    map['reddit_copy_old_reddit_links'] = Variable<bool>(
      redditCopyOldRedditLinks,
    );
    if (!nullToAbsent || redditClientId != null) {
      map['reddit_client_id'] = Variable<String>(redditClientId);
    }
    if (!nullToAbsent || redditRedirectUri != null) {
      map['reddit_redirect_uri'] = Variable<String>(redditRedirectUri);
    }
    if (!nullToAbsent || redditDeviceId != null) {
      map['reddit_device_id'] = Variable<String>(redditDeviceId);
    }
    if (!nullToAbsent || redditUserAgent != null) {
      map['reddit_user_agent'] = Variable<String>(redditUserAgent);
    }
    map['digg_posts_fetch_depth'] = Variable<int>(diggPostsFetchDepth);
    if (!nullToAbsent || diggUserAgent != null) {
      map['digg_user_agent'] = Variable<String>(diggUserAgent);
    }
    if (!nullToAbsent || searchType != null) {
      map['search_type'] = Variable<String>(
        $SettingsTable.$convertersearchTypen.toSql(searchType),
      );
    }
    if (!nullToAbsent || activeUserId != null) {
      map['active_user_id'] = Variable<String>(activeUserId);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      homeCommunityPlatform: homeCommunityPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(homeCommunityPlatform),
      homeCommunityName: homeCommunityName == null && nullToAbsent
          ? const Value.absent()
          : Value(homeCommunityName),
      showCommentImages: Value(showCommentImages),
      autoplayVideos: Value(autoplayVideos),
      swipePostsToVote: Value(swipePostsToVote),
      swipeCommentsToVote: Value(swipeCommentsToVote),
      showCommentVotingEdges: Value(showCommentVotingEdges),
      commentTapBehavior: Value(commentTapBehavior),
      commentLongPressBehavior: Value(commentLongPressBehavior),
      appBarColor: appBarColor == null && nullToAbsent
          ? const Value.absent()
          : Value(appBarColor),
      useBottomBar: Value(useBottomBar),
      reverseCommunityList: Value(reverseCommunityList),
      backOnHomeScreenShowCommunityList: Value(
        backOnHomeScreenShowCommunityList,
      ),
      showPlatformColorAccents: Value(showPlatformColorAccents),
      showPlatformColorTextAccents: Value(showPlatformColorTextAccents),
      redditCopyOldRedditLinks: Value(redditCopyOldRedditLinks),
      redditClientId: redditClientId == null && nullToAbsent
          ? const Value.absent()
          : Value(redditClientId),
      redditRedirectUri: redditRedirectUri == null && nullToAbsent
          ? const Value.absent()
          : Value(redditRedirectUri),
      redditDeviceId: redditDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(redditDeviceId),
      redditUserAgent: redditUserAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(redditUserAgent),
      diggPostsFetchDepth: Value(diggPostsFetchDepth),
      diggUserAgent: diggUserAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(diggUserAgent),
      searchType: searchType == null && nullToAbsent
          ? const Value.absent()
          : Value(searchType),
      activeUserId: activeUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeUserId),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      homeCommunityPlatform: $SettingsTable.$converterhomeCommunityPlatformn
          .fromJson(
            serializer.fromJson<String?>(json['homeCommunityPlatform']),
          ),
      homeCommunityName: serializer.fromJson<String?>(
        json['homeCommunityName'],
      ),
      showCommentImages: serializer.fromJson<bool>(json['showCommentImages']),
      autoplayVideos: serializer.fromJson<bool>(json['autoplayVideos']),
      swipePostsToVote: serializer.fromJson<bool>(json['swipePostsToVote']),
      swipeCommentsToVote: serializer.fromJson<bool>(
        json['swipeCommentsToVote'],
      ),
      showCommentVotingEdges: serializer.fromJson<bool>(
        json['showCommentVotingEdges'],
      ),
      commentTapBehavior: $SettingsTable.$convertercommentTapBehavior.fromJson(
        serializer.fromJson<String>(json['commentTapBehavior']),
      ),
      commentLongPressBehavior: $SettingsTable
          .$convertercommentLongPressBehavior
          .fromJson(
            serializer.fromJson<String>(json['commentLongPressBehavior']),
          ),
      appBarColor: serializer.fromJson<int?>(json['appBarColor']),
      useBottomBar: serializer.fromJson<bool>(json['useBottomBar']),
      reverseCommunityList: serializer.fromJson<bool>(
        json['reverseCommunityList'],
      ),
      backOnHomeScreenShowCommunityList: serializer.fromJson<bool>(
        json['backOnHomeScreenShowCommunityList'],
      ),
      showPlatformColorAccents: serializer.fromJson<bool>(
        json['showPlatformColorAccents'],
      ),
      showPlatformColorTextAccents: serializer.fromJson<bool>(
        json['showPlatformColorTextAccents'],
      ),
      redditCopyOldRedditLinks: serializer.fromJson<bool>(
        json['redditCopyOldRedditLinks'],
      ),
      redditClientId: serializer.fromJson<String?>(json['redditClientId']),
      redditRedirectUri: serializer.fromJson<String?>(
        json['redditRedirectUri'],
      ),
      redditDeviceId: serializer.fromJson<String?>(json['redditDeviceId']),
      redditUserAgent: serializer.fromJson<String?>(json['redditUserAgent']),
      diggPostsFetchDepth: serializer.fromJson<int>(
        json['diggPostsFetchDepth'],
      ),
      diggUserAgent: serializer.fromJson<String?>(json['diggUserAgent']),
      searchType: $SettingsTable.$convertersearchTypen.fromJson(
        serializer.fromJson<String?>(json['searchType']),
      ),
      activeUserId: serializer.fromJson<String?>(json['activeUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'homeCommunityPlatform': serializer.toJson<String?>(
        $SettingsTable.$converterhomeCommunityPlatformn.toJson(
          homeCommunityPlatform,
        ),
      ),
      'homeCommunityName': serializer.toJson<String?>(homeCommunityName),
      'showCommentImages': serializer.toJson<bool>(showCommentImages),
      'autoplayVideos': serializer.toJson<bool>(autoplayVideos),
      'swipePostsToVote': serializer.toJson<bool>(swipePostsToVote),
      'swipeCommentsToVote': serializer.toJson<bool>(swipeCommentsToVote),
      'showCommentVotingEdges': serializer.toJson<bool>(showCommentVotingEdges),
      'commentTapBehavior': serializer.toJson<String>(
        $SettingsTable.$convertercommentTapBehavior.toJson(commentTapBehavior),
      ),
      'commentLongPressBehavior': serializer.toJson<String>(
        $SettingsTable.$convertercommentLongPressBehavior.toJson(
          commentLongPressBehavior,
        ),
      ),
      'appBarColor': serializer.toJson<int?>(appBarColor),
      'useBottomBar': serializer.toJson<bool>(useBottomBar),
      'reverseCommunityList': serializer.toJson<bool>(reverseCommunityList),
      'backOnHomeScreenShowCommunityList': serializer.toJson<bool>(
        backOnHomeScreenShowCommunityList,
      ),
      'showPlatformColorAccents': serializer.toJson<bool>(
        showPlatformColorAccents,
      ),
      'showPlatformColorTextAccents': serializer.toJson<bool>(
        showPlatformColorTextAccents,
      ),
      'redditCopyOldRedditLinks': serializer.toJson<bool>(
        redditCopyOldRedditLinks,
      ),
      'redditClientId': serializer.toJson<String?>(redditClientId),
      'redditRedirectUri': serializer.toJson<String?>(redditRedirectUri),
      'redditDeviceId': serializer.toJson<String?>(redditDeviceId),
      'redditUserAgent': serializer.toJson<String?>(redditUserAgent),
      'diggPostsFetchDepth': serializer.toJson<int>(diggPostsFetchDepth),
      'diggUserAgent': serializer.toJson<String?>(diggUserAgent),
      'searchType': serializer.toJson<String?>(
        $SettingsTable.$convertersearchTypen.toJson(searchType),
      ),
      'activeUserId': serializer.toJson<String?>(activeUserId),
    };
  }

  Setting copyWith({
    int? id,
    Value<Platform?> homeCommunityPlatform = const Value.absent(),
    Value<String?> homeCommunityName = const Value.absent(),
    bool? showCommentImages,
    bool? autoplayVideos,
    bool? swipePostsToVote,
    bool? swipeCommentsToVote,
    bool? showCommentVotingEdges,
    CommentBehavior? commentTapBehavior,
    CommentBehavior? commentLongPressBehavior,
    Value<int?> appBarColor = const Value.absent(),
    bool? useBottomBar,
    bool? reverseCommunityList,
    bool? backOnHomeScreenShowCommunityList,
    bool? showPlatformColorAccents,
    bool? showPlatformColorTextAccents,
    bool? redditCopyOldRedditLinks,
    Value<String?> redditClientId = const Value.absent(),
    Value<String?> redditRedirectUri = const Value.absent(),
    Value<String?> redditDeviceId = const Value.absent(),
    Value<String?> redditUserAgent = const Value.absent(),
    int? diggPostsFetchDepth,
    Value<String?> diggUserAgent = const Value.absent(),
    Value<SearchType?> searchType = const Value.absent(),
    Value<String?> activeUserId = const Value.absent(),
  }) => Setting(
    id: id ?? this.id,
    homeCommunityPlatform: homeCommunityPlatform.present
        ? homeCommunityPlatform.value
        : this.homeCommunityPlatform,
    homeCommunityName: homeCommunityName.present
        ? homeCommunityName.value
        : this.homeCommunityName,
    showCommentImages: showCommentImages ?? this.showCommentImages,
    autoplayVideos: autoplayVideos ?? this.autoplayVideos,
    swipePostsToVote: swipePostsToVote ?? this.swipePostsToVote,
    swipeCommentsToVote: swipeCommentsToVote ?? this.swipeCommentsToVote,
    showCommentVotingEdges:
        showCommentVotingEdges ?? this.showCommentVotingEdges,
    commentTapBehavior: commentTapBehavior ?? this.commentTapBehavior,
    commentLongPressBehavior:
        commentLongPressBehavior ?? this.commentLongPressBehavior,
    appBarColor: appBarColor.present ? appBarColor.value : this.appBarColor,
    useBottomBar: useBottomBar ?? this.useBottomBar,
    reverseCommunityList: reverseCommunityList ?? this.reverseCommunityList,
    backOnHomeScreenShowCommunityList:
        backOnHomeScreenShowCommunityList ??
        this.backOnHomeScreenShowCommunityList,
    showPlatformColorAccents:
        showPlatformColorAccents ?? this.showPlatformColorAccents,
    showPlatformColorTextAccents:
        showPlatformColorTextAccents ?? this.showPlatformColorTextAccents,
    redditCopyOldRedditLinks:
        redditCopyOldRedditLinks ?? this.redditCopyOldRedditLinks,
    redditClientId: redditClientId.present
        ? redditClientId.value
        : this.redditClientId,
    redditRedirectUri: redditRedirectUri.present
        ? redditRedirectUri.value
        : this.redditRedirectUri,
    redditDeviceId: redditDeviceId.present
        ? redditDeviceId.value
        : this.redditDeviceId,
    redditUserAgent: redditUserAgent.present
        ? redditUserAgent.value
        : this.redditUserAgent,
    diggPostsFetchDepth: diggPostsFetchDepth ?? this.diggPostsFetchDepth,
    diggUserAgent: diggUserAgent.present
        ? diggUserAgent.value
        : this.diggUserAgent,
    searchType: searchType.present ? searchType.value : this.searchType,
    activeUserId: activeUserId.present ? activeUserId.value : this.activeUserId,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      homeCommunityPlatform: data.homeCommunityPlatform.present
          ? data.homeCommunityPlatform.value
          : this.homeCommunityPlatform,
      homeCommunityName: data.homeCommunityName.present
          ? data.homeCommunityName.value
          : this.homeCommunityName,
      showCommentImages: data.showCommentImages.present
          ? data.showCommentImages.value
          : this.showCommentImages,
      autoplayVideos: data.autoplayVideos.present
          ? data.autoplayVideos.value
          : this.autoplayVideos,
      swipePostsToVote: data.swipePostsToVote.present
          ? data.swipePostsToVote.value
          : this.swipePostsToVote,
      swipeCommentsToVote: data.swipeCommentsToVote.present
          ? data.swipeCommentsToVote.value
          : this.swipeCommentsToVote,
      showCommentVotingEdges: data.showCommentVotingEdges.present
          ? data.showCommentVotingEdges.value
          : this.showCommentVotingEdges,
      commentTapBehavior: data.commentTapBehavior.present
          ? data.commentTapBehavior.value
          : this.commentTapBehavior,
      commentLongPressBehavior: data.commentLongPressBehavior.present
          ? data.commentLongPressBehavior.value
          : this.commentLongPressBehavior,
      appBarColor: data.appBarColor.present
          ? data.appBarColor.value
          : this.appBarColor,
      useBottomBar: data.useBottomBar.present
          ? data.useBottomBar.value
          : this.useBottomBar,
      reverseCommunityList: data.reverseCommunityList.present
          ? data.reverseCommunityList.value
          : this.reverseCommunityList,
      backOnHomeScreenShowCommunityList:
          data.backOnHomeScreenShowCommunityList.present
          ? data.backOnHomeScreenShowCommunityList.value
          : this.backOnHomeScreenShowCommunityList,
      showPlatformColorAccents: data.showPlatformColorAccents.present
          ? data.showPlatformColorAccents.value
          : this.showPlatformColorAccents,
      showPlatformColorTextAccents: data.showPlatformColorTextAccents.present
          ? data.showPlatformColorTextAccents.value
          : this.showPlatformColorTextAccents,
      redditCopyOldRedditLinks: data.redditCopyOldRedditLinks.present
          ? data.redditCopyOldRedditLinks.value
          : this.redditCopyOldRedditLinks,
      redditClientId: data.redditClientId.present
          ? data.redditClientId.value
          : this.redditClientId,
      redditRedirectUri: data.redditRedirectUri.present
          ? data.redditRedirectUri.value
          : this.redditRedirectUri,
      redditDeviceId: data.redditDeviceId.present
          ? data.redditDeviceId.value
          : this.redditDeviceId,
      redditUserAgent: data.redditUserAgent.present
          ? data.redditUserAgent.value
          : this.redditUserAgent,
      diggPostsFetchDepth: data.diggPostsFetchDepth.present
          ? data.diggPostsFetchDepth.value
          : this.diggPostsFetchDepth,
      diggUserAgent: data.diggUserAgent.present
          ? data.diggUserAgent.value
          : this.diggUserAgent,
      searchType: data.searchType.present
          ? data.searchType.value
          : this.searchType,
      activeUserId: data.activeUserId.present
          ? data.activeUserId.value
          : this.activeUserId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('homeCommunityPlatform: $homeCommunityPlatform, ')
          ..write('homeCommunityName: $homeCommunityName, ')
          ..write('showCommentImages: $showCommentImages, ')
          ..write('autoplayVideos: $autoplayVideos, ')
          ..write('swipePostsToVote: $swipePostsToVote, ')
          ..write('swipeCommentsToVote: $swipeCommentsToVote, ')
          ..write('showCommentVotingEdges: $showCommentVotingEdges, ')
          ..write('commentTapBehavior: $commentTapBehavior, ')
          ..write('commentLongPressBehavior: $commentLongPressBehavior, ')
          ..write('appBarColor: $appBarColor, ')
          ..write('useBottomBar: $useBottomBar, ')
          ..write('reverseCommunityList: $reverseCommunityList, ')
          ..write(
            'backOnHomeScreenShowCommunityList: $backOnHomeScreenShowCommunityList, ',
          )
          ..write('showPlatformColorAccents: $showPlatformColorAccents, ')
          ..write(
            'showPlatformColorTextAccents: $showPlatformColorTextAccents, ',
          )
          ..write('redditCopyOldRedditLinks: $redditCopyOldRedditLinks, ')
          ..write('redditClientId: $redditClientId, ')
          ..write('redditRedirectUri: $redditRedirectUri, ')
          ..write('redditDeviceId: $redditDeviceId, ')
          ..write('redditUserAgent: $redditUserAgent, ')
          ..write('diggPostsFetchDepth: $diggPostsFetchDepth, ')
          ..write('diggUserAgent: $diggUserAgent, ')
          ..write('searchType: $searchType, ')
          ..write('activeUserId: $activeUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    homeCommunityPlatform,
    homeCommunityName,
    showCommentImages,
    autoplayVideos,
    swipePostsToVote,
    swipeCommentsToVote,
    showCommentVotingEdges,
    commentTapBehavior,
    commentLongPressBehavior,
    appBarColor,
    useBottomBar,
    reverseCommunityList,
    backOnHomeScreenShowCommunityList,
    showPlatformColorAccents,
    showPlatformColorTextAccents,
    redditCopyOldRedditLinks,
    redditClientId,
    redditRedirectUri,
    redditDeviceId,
    redditUserAgent,
    diggPostsFetchDepth,
    diggUserAgent,
    searchType,
    activeUserId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.homeCommunityPlatform == this.homeCommunityPlatform &&
          other.homeCommunityName == this.homeCommunityName &&
          other.showCommentImages == this.showCommentImages &&
          other.autoplayVideos == this.autoplayVideos &&
          other.swipePostsToVote == this.swipePostsToVote &&
          other.swipeCommentsToVote == this.swipeCommentsToVote &&
          other.showCommentVotingEdges == this.showCommentVotingEdges &&
          other.commentTapBehavior == this.commentTapBehavior &&
          other.commentLongPressBehavior == this.commentLongPressBehavior &&
          other.appBarColor == this.appBarColor &&
          other.useBottomBar == this.useBottomBar &&
          other.reverseCommunityList == this.reverseCommunityList &&
          other.backOnHomeScreenShowCommunityList ==
              this.backOnHomeScreenShowCommunityList &&
          other.showPlatformColorAccents == this.showPlatformColorAccents &&
          other.showPlatformColorTextAccents ==
              this.showPlatformColorTextAccents &&
          other.redditCopyOldRedditLinks == this.redditCopyOldRedditLinks &&
          other.redditClientId == this.redditClientId &&
          other.redditRedirectUri == this.redditRedirectUri &&
          other.redditDeviceId == this.redditDeviceId &&
          other.redditUserAgent == this.redditUserAgent &&
          other.diggPostsFetchDepth == this.diggPostsFetchDepth &&
          other.diggUserAgent == this.diggUserAgent &&
          other.searchType == this.searchType &&
          other.activeUserId == this.activeUserId);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<Platform?> homeCommunityPlatform;
  final Value<String?> homeCommunityName;
  final Value<bool> showCommentImages;
  final Value<bool> autoplayVideos;
  final Value<bool> swipePostsToVote;
  final Value<bool> swipeCommentsToVote;
  final Value<bool> showCommentVotingEdges;
  final Value<CommentBehavior> commentTapBehavior;
  final Value<CommentBehavior> commentLongPressBehavior;
  final Value<int?> appBarColor;
  final Value<bool> useBottomBar;
  final Value<bool> reverseCommunityList;
  final Value<bool> backOnHomeScreenShowCommunityList;
  final Value<bool> showPlatformColorAccents;
  final Value<bool> showPlatformColorTextAccents;
  final Value<bool> redditCopyOldRedditLinks;
  final Value<String?> redditClientId;
  final Value<String?> redditRedirectUri;
  final Value<String?> redditDeviceId;
  final Value<String?> redditUserAgent;
  final Value<int> diggPostsFetchDepth;
  final Value<String?> diggUserAgent;
  final Value<SearchType?> searchType;
  final Value<String?> activeUserId;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.homeCommunityPlatform = const Value.absent(),
    this.homeCommunityName = const Value.absent(),
    this.showCommentImages = const Value.absent(),
    this.autoplayVideos = const Value.absent(),
    this.swipePostsToVote = const Value.absent(),
    this.swipeCommentsToVote = const Value.absent(),
    this.showCommentVotingEdges = const Value.absent(),
    this.commentTapBehavior = const Value.absent(),
    this.commentLongPressBehavior = const Value.absent(),
    this.appBarColor = const Value.absent(),
    this.useBottomBar = const Value.absent(),
    this.reverseCommunityList = const Value.absent(),
    this.backOnHomeScreenShowCommunityList = const Value.absent(),
    this.showPlatformColorAccents = const Value.absent(),
    this.showPlatformColorTextAccents = const Value.absent(),
    this.redditCopyOldRedditLinks = const Value.absent(),
    this.redditClientId = const Value.absent(),
    this.redditRedirectUri = const Value.absent(),
    this.redditDeviceId = const Value.absent(),
    this.redditUserAgent = const Value.absent(),
    this.diggPostsFetchDepth = const Value.absent(),
    this.diggUserAgent = const Value.absent(),
    this.searchType = const Value.absent(),
    this.activeUserId = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.homeCommunityPlatform = const Value.absent(),
    this.homeCommunityName = const Value.absent(),
    this.showCommentImages = const Value.absent(),
    this.autoplayVideos = const Value.absent(),
    this.swipePostsToVote = const Value.absent(),
    this.swipeCommentsToVote = const Value.absent(),
    this.showCommentVotingEdges = const Value.absent(),
    this.commentTapBehavior = const Value.absent(),
    this.commentLongPressBehavior = const Value.absent(),
    this.appBarColor = const Value.absent(),
    this.useBottomBar = const Value.absent(),
    this.reverseCommunityList = const Value.absent(),
    this.backOnHomeScreenShowCommunityList = const Value.absent(),
    this.showPlatformColorAccents = const Value.absent(),
    this.showPlatformColorTextAccents = const Value.absent(),
    this.redditCopyOldRedditLinks = const Value.absent(),
    this.redditClientId = const Value.absent(),
    this.redditRedirectUri = const Value.absent(),
    this.redditDeviceId = const Value.absent(),
    this.redditUserAgent = const Value.absent(),
    this.diggPostsFetchDepth = const Value.absent(),
    this.diggUserAgent = const Value.absent(),
    this.searchType = const Value.absent(),
    this.activeUserId = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? homeCommunityPlatform,
    Expression<String>? homeCommunityName,
    Expression<bool>? showCommentImages,
    Expression<bool>? autoplayVideos,
    Expression<bool>? swipePostsToVote,
    Expression<bool>? swipeCommentsToVote,
    Expression<bool>? showCommentVotingEdges,
    Expression<String>? commentTapBehavior,
    Expression<String>? commentLongPressBehavior,
    Expression<int>? appBarColor,
    Expression<bool>? useBottomBar,
    Expression<bool>? reverseCommunityList,
    Expression<bool>? backOnHomeScreenShowCommunityList,
    Expression<bool>? showPlatformColorAccents,
    Expression<bool>? showPlatformColorTextAccents,
    Expression<bool>? redditCopyOldRedditLinks,
    Expression<String>? redditClientId,
    Expression<String>? redditRedirectUri,
    Expression<String>? redditDeviceId,
    Expression<String>? redditUserAgent,
    Expression<int>? diggPostsFetchDepth,
    Expression<String>? diggUserAgent,
    Expression<String>? searchType,
    Expression<String>? activeUserId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeCommunityPlatform != null)
        'home_community_platform': homeCommunityPlatform,
      if (homeCommunityName != null) 'home_community_name': homeCommunityName,
      if (showCommentImages != null) 'show_comment_images': showCommentImages,
      if (autoplayVideos != null) 'autoplay_videos': autoplayVideos,
      if (swipePostsToVote != null) 'swipe_posts_to_vote': swipePostsToVote,
      if (swipeCommentsToVote != null)
        'swipe_comments_to_vote': swipeCommentsToVote,
      if (showCommentVotingEdges != null)
        'show_comment_voting_edges': showCommentVotingEdges,
      if (commentTapBehavior != null)
        'comment_tap_behavior': commentTapBehavior,
      if (commentLongPressBehavior != null)
        'comment_long_press_behavior': commentLongPressBehavior,
      if (appBarColor != null) 'app_bar_color': appBarColor,
      if (useBottomBar != null) 'use_bottom_bar': useBottomBar,
      if (reverseCommunityList != null)
        'reverse_community_list': reverseCommunityList,
      if (backOnHomeScreenShowCommunityList != null)
        'back_on_home_screen_show_community_list':
            backOnHomeScreenShowCommunityList,
      if (showPlatformColorAccents != null)
        'show_platform_color_accents': showPlatformColorAccents,
      if (showPlatformColorTextAccents != null)
        'show_platform_color_text_accents': showPlatformColorTextAccents,
      if (redditCopyOldRedditLinks != null)
        'reddit_copy_old_reddit_links': redditCopyOldRedditLinks,
      if (redditClientId != null) 'reddit_client_id': redditClientId,
      if (redditRedirectUri != null) 'reddit_redirect_uri': redditRedirectUri,
      if (redditDeviceId != null) 'reddit_device_id': redditDeviceId,
      if (redditUserAgent != null) 'reddit_user_agent': redditUserAgent,
      if (diggPostsFetchDepth != null)
        'digg_posts_fetch_depth': diggPostsFetchDepth,
      if (diggUserAgent != null) 'digg_user_agent': diggUserAgent,
      if (searchType != null) 'search_type': searchType,
      if (activeUserId != null) 'active_user_id': activeUserId,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<Platform?>? homeCommunityPlatform,
    Value<String?>? homeCommunityName,
    Value<bool>? showCommentImages,
    Value<bool>? autoplayVideos,
    Value<bool>? swipePostsToVote,
    Value<bool>? swipeCommentsToVote,
    Value<bool>? showCommentVotingEdges,
    Value<CommentBehavior>? commentTapBehavior,
    Value<CommentBehavior>? commentLongPressBehavior,
    Value<int?>? appBarColor,
    Value<bool>? useBottomBar,
    Value<bool>? reverseCommunityList,
    Value<bool>? backOnHomeScreenShowCommunityList,
    Value<bool>? showPlatformColorAccents,
    Value<bool>? showPlatformColorTextAccents,
    Value<bool>? redditCopyOldRedditLinks,
    Value<String?>? redditClientId,
    Value<String?>? redditRedirectUri,
    Value<String?>? redditDeviceId,
    Value<String?>? redditUserAgent,
    Value<int>? diggPostsFetchDepth,
    Value<String?>? diggUserAgent,
    Value<SearchType?>? searchType,
    Value<String?>? activeUserId,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      homeCommunityPlatform:
          homeCommunityPlatform ?? this.homeCommunityPlatform,
      homeCommunityName: homeCommunityName ?? this.homeCommunityName,
      showCommentImages: showCommentImages ?? this.showCommentImages,
      autoplayVideos: autoplayVideos ?? this.autoplayVideos,
      swipePostsToVote: swipePostsToVote ?? this.swipePostsToVote,
      swipeCommentsToVote: swipeCommentsToVote ?? this.swipeCommentsToVote,
      showCommentVotingEdges:
          showCommentVotingEdges ?? this.showCommentVotingEdges,
      commentTapBehavior: commentTapBehavior ?? this.commentTapBehavior,
      commentLongPressBehavior:
          commentLongPressBehavior ?? this.commentLongPressBehavior,
      appBarColor: appBarColor ?? this.appBarColor,
      useBottomBar: useBottomBar ?? this.useBottomBar,
      reverseCommunityList: reverseCommunityList ?? this.reverseCommunityList,
      backOnHomeScreenShowCommunityList:
          backOnHomeScreenShowCommunityList ??
          this.backOnHomeScreenShowCommunityList,
      showPlatformColorAccents:
          showPlatformColorAccents ?? this.showPlatformColorAccents,
      showPlatformColorTextAccents:
          showPlatformColorTextAccents ?? this.showPlatformColorTextAccents,
      redditCopyOldRedditLinks:
          redditCopyOldRedditLinks ?? this.redditCopyOldRedditLinks,
      redditClientId: redditClientId ?? this.redditClientId,
      redditRedirectUri: redditRedirectUri ?? this.redditRedirectUri,
      redditDeviceId: redditDeviceId ?? this.redditDeviceId,
      redditUserAgent: redditUserAgent ?? this.redditUserAgent,
      diggPostsFetchDepth: diggPostsFetchDepth ?? this.diggPostsFetchDepth,
      diggUserAgent: diggUserAgent ?? this.diggUserAgent,
      searchType: searchType ?? this.searchType,
      activeUserId: activeUserId ?? this.activeUserId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (homeCommunityPlatform.present) {
      map['home_community_platform'] = Variable<String>(
        $SettingsTable.$converterhomeCommunityPlatformn.toSql(
          homeCommunityPlatform.value,
        ),
      );
    }
    if (homeCommunityName.present) {
      map['home_community_name'] = Variable<String>(homeCommunityName.value);
    }
    if (showCommentImages.present) {
      map['show_comment_images'] = Variable<bool>(showCommentImages.value);
    }
    if (autoplayVideos.present) {
      map['autoplay_videos'] = Variable<bool>(autoplayVideos.value);
    }
    if (swipePostsToVote.present) {
      map['swipe_posts_to_vote'] = Variable<bool>(swipePostsToVote.value);
    }
    if (swipeCommentsToVote.present) {
      map['swipe_comments_to_vote'] = Variable<bool>(swipeCommentsToVote.value);
    }
    if (showCommentVotingEdges.present) {
      map['show_comment_voting_edges'] = Variable<bool>(
        showCommentVotingEdges.value,
      );
    }
    if (commentTapBehavior.present) {
      map['comment_tap_behavior'] = Variable<String>(
        $SettingsTable.$convertercommentTapBehavior.toSql(
          commentTapBehavior.value,
        ),
      );
    }
    if (commentLongPressBehavior.present) {
      map['comment_long_press_behavior'] = Variable<String>(
        $SettingsTable.$convertercommentLongPressBehavior.toSql(
          commentLongPressBehavior.value,
        ),
      );
    }
    if (appBarColor.present) {
      map['app_bar_color'] = Variable<int>(appBarColor.value);
    }
    if (useBottomBar.present) {
      map['use_bottom_bar'] = Variable<bool>(useBottomBar.value);
    }
    if (reverseCommunityList.present) {
      map['reverse_community_list'] = Variable<bool>(
        reverseCommunityList.value,
      );
    }
    if (backOnHomeScreenShowCommunityList.present) {
      map['back_on_home_screen_show_community_list'] = Variable<bool>(
        backOnHomeScreenShowCommunityList.value,
      );
    }
    if (showPlatformColorAccents.present) {
      map['show_platform_color_accents'] = Variable<bool>(
        showPlatformColorAccents.value,
      );
    }
    if (showPlatformColorTextAccents.present) {
      map['show_platform_color_text_accents'] = Variable<bool>(
        showPlatformColorTextAccents.value,
      );
    }
    if (redditCopyOldRedditLinks.present) {
      map['reddit_copy_old_reddit_links'] = Variable<bool>(
        redditCopyOldRedditLinks.value,
      );
    }
    if (redditClientId.present) {
      map['reddit_client_id'] = Variable<String>(redditClientId.value);
    }
    if (redditRedirectUri.present) {
      map['reddit_redirect_uri'] = Variable<String>(redditRedirectUri.value);
    }
    if (redditDeviceId.present) {
      map['reddit_device_id'] = Variable<String>(redditDeviceId.value);
    }
    if (redditUserAgent.present) {
      map['reddit_user_agent'] = Variable<String>(redditUserAgent.value);
    }
    if (diggPostsFetchDepth.present) {
      map['digg_posts_fetch_depth'] = Variable<int>(diggPostsFetchDepth.value);
    }
    if (diggUserAgent.present) {
      map['digg_user_agent'] = Variable<String>(diggUserAgent.value);
    }
    if (searchType.present) {
      map['search_type'] = Variable<String>(
        $SettingsTable.$convertersearchTypen.toSql(searchType.value),
      );
    }
    if (activeUserId.present) {
      map['active_user_id'] = Variable<String>(activeUserId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('homeCommunityPlatform: $homeCommunityPlatform, ')
          ..write('homeCommunityName: $homeCommunityName, ')
          ..write('showCommentImages: $showCommentImages, ')
          ..write('autoplayVideos: $autoplayVideos, ')
          ..write('swipePostsToVote: $swipePostsToVote, ')
          ..write('swipeCommentsToVote: $swipeCommentsToVote, ')
          ..write('showCommentVotingEdges: $showCommentVotingEdges, ')
          ..write('commentTapBehavior: $commentTapBehavior, ')
          ..write('commentLongPressBehavior: $commentLongPressBehavior, ')
          ..write('appBarColor: $appBarColor, ')
          ..write('useBottomBar: $useBottomBar, ')
          ..write('reverseCommunityList: $reverseCommunityList, ')
          ..write(
            'backOnHomeScreenShowCommunityList: $backOnHomeScreenShowCommunityList, ',
          )
          ..write('showPlatformColorAccents: $showPlatformColorAccents, ')
          ..write(
            'showPlatformColorTextAccents: $showPlatformColorTextAccents, ',
          )
          ..write('redditCopyOldRedditLinks: $redditCopyOldRedditLinks, ')
          ..write('redditClientId: $redditClientId, ')
          ..write('redditRedirectUri: $redditRedirectUri, ')
          ..write('redditDeviceId: $redditDeviceId, ')
          ..write('redditUserAgent: $redditUserAgent, ')
          ..write('diggPostsFetchDepth: $diggPostsFetchDepth, ')
          ..write('diggUserAgent: $diggUserAgent, ')
          ..write('searchType: $searchType, ')
          ..write('activeUserId: $activeUserId')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, LoggedInUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<Platform, String> platform =
      GeneratedColumn<String>(
        'platform',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Platform>($UsersTable.$converterplatform);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inboxCountMeta = const VerificationMeta(
    'inboxCount',
  );
  @override
  late final GeneratedColumn<int> inboxCount = GeneratedColumn<int>(
    'inbox_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    platform,
    id,
    name,
    iconUrl,
    inboxCount,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoggedInUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_iconUrlMeta);
    }
    if (data.containsKey('inbox_count')) {
      context.handle(
        _inboxCountMeta,
        inboxCount.isAcceptableOrUnknown(data['inbox_count']!, _inboxCountMeta),
      );
    } else if (isInserting) {
      context.missing(_inboxCountMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {platform, id};
  @override
  LoggedInUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoggedInUser(
      platform: $UsersTable.$converterplatform.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}platform'],
        )!,
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      )!,
      inboxCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}inbox_count'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Platform, String, String> $converterplatform =
      const EnumNameConverter<Platform>(Platform.values);
}

class UsersCompanion extends UpdateCompanion<LoggedInUser> {
  final Value<Platform> platform;
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconUrl;
  final Value<int> inboxCount;
  final Value<int> score;
  final Value<int> rowid;
  const UsersCompanion({
    this.platform = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.inboxCount = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required Platform platform,
    required String id,
    required String name,
    required String iconUrl,
    required int inboxCount,
    required int score,
    this.rowid = const Value.absent(),
  }) : platform = Value(platform),
       id = Value(id),
       name = Value(name),
       iconUrl = Value(iconUrl),
       inboxCount = Value(inboxCount),
       score = Value(score);
  static Insertable<LoggedInUser> custom({
    Expression<String>? platform,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconUrl,
    Expression<int>? inboxCount,
    Expression<int>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (platform != null) 'platform': platform,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (inboxCount != null) 'inbox_count': inboxCount,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<Platform>? platform,
    Value<String>? id,
    Value<String>? name,
    Value<String>? iconUrl,
    Value<int>? inboxCount,
    Value<int>? score,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      platform: platform ?? this.platform,
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      inboxCount: inboxCount ?? this.inboxCount,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (platform.present) {
      map['platform'] = Variable<String>(
        $UsersTable.$converterplatform.toSql(platform.value),
      );
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (inboxCount.present) {
      map['inbox_count'] = Variable<int>(inboxCount.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('platform: $platform, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('inboxCount: $inboxCount, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCommunitiesTable extends UserCommunities
    with TableInfo<$UserCommunitiesTable, UserCommunity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCommunitiesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<Platform, String> platform =
      GeneratedColumn<String>(
        'platform',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Platform>($UserCommunitiesTable.$converterplatform);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _communityNameMeta = const VerificationMeta(
    'communityName',
  );
  @override
  late final GeneratedColumn<String> communityName = GeneratedColumn<String>(
    'community_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [platform, userId, communityName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_communities';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserCommunity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('community_name')) {
      context.handle(
        _communityNameMeta,
        communityName.isAcceptableOrUnknown(
          data['community_name']!,
          _communityNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_communityNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {platform, userId, communityName};
  @override
  UserCommunity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCommunity(
      platform: $UserCommunitiesTable.$converterplatform.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}platform'],
        )!,
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      communityName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}community_name'],
      )!,
    );
  }

  @override
  $UserCommunitiesTable createAlias(String alias) {
    return $UserCommunitiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Platform, String, String> $converterplatform =
      const EnumNameConverter<Platform>(Platform.values);
}

class UserCommunity extends DataClass implements Insertable<UserCommunity> {
  final Platform platform;
  final String userId;
  final String communityName;
  const UserCommunity({
    required this.platform,
    required this.userId,
    required this.communityName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['platform'] = Variable<String>(
        $UserCommunitiesTable.$converterplatform.toSql(platform),
      );
    }
    map['user_id'] = Variable<String>(userId);
    map['community_name'] = Variable<String>(communityName);
    return map;
  }

  UserCommunitiesCompanion toCompanion(bool nullToAbsent) {
    return UserCommunitiesCompanion(
      platform: Value(platform),
      userId: Value(userId),
      communityName: Value(communityName),
    );
  }

  factory UserCommunity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCommunity(
      platform: $UserCommunitiesTable.$converterplatform.fromJson(
        serializer.fromJson<String>(json['platform']),
      ),
      userId: serializer.fromJson<String>(json['userId']),
      communityName: serializer.fromJson<String>(json['communityName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'platform': serializer.toJson<String>(
        $UserCommunitiesTable.$converterplatform.toJson(platform),
      ),
      'userId': serializer.toJson<String>(userId),
      'communityName': serializer.toJson<String>(communityName),
    };
  }

  UserCommunity copyWith({
    Platform? platform,
    String? userId,
    String? communityName,
  }) => UserCommunity(
    platform: platform ?? this.platform,
    userId: userId ?? this.userId,
    communityName: communityName ?? this.communityName,
  );
  UserCommunity copyWithCompanion(UserCommunitiesCompanion data) {
    return UserCommunity(
      platform: data.platform.present ? data.platform.value : this.platform,
      userId: data.userId.present ? data.userId.value : this.userId,
      communityName: data.communityName.present
          ? data.communityName.value
          : this.communityName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCommunity(')
          ..write('platform: $platform, ')
          ..write('userId: $userId, ')
          ..write('communityName: $communityName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(platform, userId, communityName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCommunity &&
          other.platform == this.platform &&
          other.userId == this.userId &&
          other.communityName == this.communityName);
}

class UserCommunitiesCompanion extends UpdateCompanion<UserCommunity> {
  final Value<Platform> platform;
  final Value<String> userId;
  final Value<String> communityName;
  final Value<int> rowid;
  const UserCommunitiesCompanion({
    this.platform = const Value.absent(),
    this.userId = const Value.absent(),
    this.communityName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCommunitiesCompanion.insert({
    required Platform platform,
    required String userId,
    required String communityName,
    this.rowid = const Value.absent(),
  }) : platform = Value(platform),
       userId = Value(userId),
       communityName = Value(communityName);
  static Insertable<UserCommunity> custom({
    Expression<String>? platform,
    Expression<String>? userId,
    Expression<String>? communityName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (platform != null) 'platform': platform,
      if (userId != null) 'user_id': userId,
      if (communityName != null) 'community_name': communityName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCommunitiesCompanion copyWith({
    Value<Platform>? platform,
    Value<String>? userId,
    Value<String>? communityName,
    Value<int>? rowid,
  }) {
    return UserCommunitiesCompanion(
      platform: platform ?? this.platform,
      userId: userId ?? this.userId,
      communityName: communityName ?? this.communityName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (platform.present) {
      map['platform'] = Variable<String>(
        $UserCommunitiesTable.$converterplatform.toSql(platform.value),
      );
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (communityName.present) {
      map['community_name'] = Variable<String>(communityName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCommunitiesCompanion(')
          ..write('platform: $platform, ')
          ..write('userId: $userId, ')
          ..write('communityName: $communityName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommunitiesTable extends Communities
    with TableInfo<$CommunitiesTable, Community> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommunitiesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<Platform, String> platform =
      GeneratedColumn<String>(
        'platform',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Platform>($CommunitiesTable.$converterplatform);
  @override
  late final GeneratedColumnWithTypeConverter<String?, String> name =
      GeneratedColumn<String>(
        'name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<String?>($CommunitiesTable.$convertername);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [platform, name, id, isFavorite];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'communities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Community> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {platform, name};
  @override
  Community map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Community(
      platform: $CommunitiesTable.$converterplatform.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}platform'],
        )!,
      ),
      name: $CommunitiesTable.$convertername.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}name'],
        )!,
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $CommunitiesTable createAlias(String alias) {
    return $CommunitiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Platform, String, String> $converterplatform =
      const EnumNameConverter<Platform>(Platform.values);
  static TypeConverter<String?, String> $convertername =
      const EmptyStringConverter();
}

class CommunitiesCompanion extends UpdateCompanion<Community> {
  final Value<Platform> platform;
  final Value<String?> name;
  final Value<String?> id;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const CommunitiesCompanion({
    this.platform = const Value.absent(),
    this.name = const Value.absent(),
    this.id = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommunitiesCompanion.insert({
    required Platform platform,
    required String? name,
    this.id = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : platform = Value(platform),
       name = Value(name);
  static Insertable<Community> custom({
    Expression<String>? platform,
    Expression<String>? name,
    Expression<String>? id,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (platform != null) 'platform': platform,
      if (name != null) 'name': name,
      if (id != null) 'id': id,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommunitiesCompanion copyWith({
    Value<Platform>? platform,
    Value<String?>? name,
    Value<String?>? id,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return CommunitiesCompanion(
      platform: platform ?? this.platform,
      name: name ?? this.name,
      id: id ?? this.id,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (platform.present) {
      map['platform'] = Variable<String>(
        $CommunitiesTable.$converterplatform.toSql(platform.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(
        $CommunitiesTable.$convertername.toSql(name.value),
      );
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommunitiesCompanion(')
          ..write('platform: $platform, ')
          ..write('name: $name, ')
          ..write('id: $id, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryTable extends History with TableInfo<$HistoryTable, HistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HistoryType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<HistoryType>($HistoryTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [itemId, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, type};
  @override
  HistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryData(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      type: $HistoryTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
    );
  }

  @override
  $HistoryTable createAlias(String alias) {
    return $HistoryTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<HistoryType, int, int> $convertertype =
      const EnumIndexConverter<HistoryType>(HistoryType.values);
}

class HistoryData extends DataClass implements Insertable<HistoryData> {
  final String itemId;
  final HistoryType type;
  const HistoryData({required this.itemId, required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    {
      map['type'] = Variable<int>($HistoryTable.$convertertype.toSql(type));
    }
    return map;
  }

  HistoryCompanion toCompanion(bool nullToAbsent) {
    return HistoryCompanion(itemId: Value(itemId), type: Value(type));
  }

  factory HistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryData(
      itemId: serializer.fromJson<String>(json['itemId']),
      type: $HistoryTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'type': serializer.toJson<int>($HistoryTable.$convertertype.toJson(type)),
    };
  }

  HistoryData copyWith({String? itemId, HistoryType? type}) =>
      HistoryData(itemId: itemId ?? this.itemId, type: type ?? this.type);
  HistoryData copyWithCompanion(HistoryCompanion data) {
    return HistoryData(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryData(')
          ..write('itemId: $itemId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryData &&
          other.itemId == this.itemId &&
          other.type == this.type);
}

class HistoryCompanion extends UpdateCompanion<HistoryData> {
  final Value<String> itemId;
  final Value<HistoryType> type;
  final Value<int> rowid;
  const HistoryCompanion({
    this.itemId = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryCompanion.insert({
    required String itemId,
    required HistoryType type,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       type = Value(type);
  static Insertable<HistoryData> custom({
    Expression<String>? itemId,
    Expression<int>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryCompanion copyWith({
    Value<String>? itemId,
    Value<HistoryType>? type,
    Value<int>? rowid,
  }) {
    return HistoryCompanion(
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $HistoryTable.$convertertype.toSql(type.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $CookiesTable cookies = $CookiesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $UserCommunitiesTable userCommunities = $UserCommunitiesTable(
    this,
  );
  late final $CommunitiesTable communities = $CommunitiesTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cookies,
    settings,
    users,
    userCommunities,
    communities,
    history,
  ];
}

typedef $$CookiesTableCreateCompanionBuilder =
    CookiesCompanion Function({
      required String key,
      required String value,
      Value<DateTime?> expirationTime,
      Value<int> rowid,
    });
typedef $$CookiesTableUpdateCompanionBuilder =
    CookiesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime?> expirationTime,
      Value<int> rowid,
    });

class $$CookiesTableFilterComposer extends Composer<_$Database, $CookiesTable> {
  $$CookiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expirationTime => $composableBuilder(
    column: $table.expirationTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CookiesTableOrderingComposer
    extends Composer<_$Database, $CookiesTable> {
  $$CookiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expirationTime => $composableBuilder(
    column: $table.expirationTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CookiesTableAnnotationComposer
    extends Composer<_$Database, $CookiesTable> {
  $$CookiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get expirationTime => $composableBuilder(
    column: $table.expirationTime,
    builder: (column) => column,
  );
}

class $$CookiesTableTableManager
    extends
        RootTableManager<
          _$Database,
          $CookiesTable,
          Cookie,
          $$CookiesTableFilterComposer,
          $$CookiesTableOrderingComposer,
          $$CookiesTableAnnotationComposer,
          $$CookiesTableCreateCompanionBuilder,
          $$CookiesTableUpdateCompanionBuilder,
          (Cookie, BaseReferences<_$Database, $CookiesTable, Cookie>),
          Cookie,
          PrefetchHooks Function()
        > {
  $$CookiesTableTableManager(_$Database db, $CookiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CookiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CookiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CookiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime?> expirationTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CookiesCompanion(
                key: key,
                value: value,
                expirationTime: expirationTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime?> expirationTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CookiesCompanion.insert(
                key: key,
                value: value,
                expirationTime: expirationTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CookiesTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $CookiesTable,
      Cookie,
      $$CookiesTableFilterComposer,
      $$CookiesTableOrderingComposer,
      $$CookiesTableAnnotationComposer,
      $$CookiesTableCreateCompanionBuilder,
      $$CookiesTableUpdateCompanionBuilder,
      (Cookie, BaseReferences<_$Database, $CookiesTable, Cookie>),
      Cookie,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<Platform?> homeCommunityPlatform,
      Value<String?> homeCommunityName,
      Value<bool> showCommentImages,
      Value<bool> autoplayVideos,
      Value<bool> swipePostsToVote,
      Value<bool> swipeCommentsToVote,
      Value<bool> showCommentVotingEdges,
      Value<CommentBehavior> commentTapBehavior,
      Value<CommentBehavior> commentLongPressBehavior,
      Value<int?> appBarColor,
      Value<bool> useBottomBar,
      Value<bool> reverseCommunityList,
      Value<bool> backOnHomeScreenShowCommunityList,
      Value<bool> showPlatformColorAccents,
      Value<bool> showPlatformColorTextAccents,
      Value<bool> redditCopyOldRedditLinks,
      Value<String?> redditClientId,
      Value<String?> redditRedirectUri,
      Value<String?> redditDeviceId,
      Value<String?> redditUserAgent,
      Value<int> diggPostsFetchDepth,
      Value<String?> diggUserAgent,
      Value<SearchType?> searchType,
      Value<String?> activeUserId,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<Platform?> homeCommunityPlatform,
      Value<String?> homeCommunityName,
      Value<bool> showCommentImages,
      Value<bool> autoplayVideos,
      Value<bool> swipePostsToVote,
      Value<bool> swipeCommentsToVote,
      Value<bool> showCommentVotingEdges,
      Value<CommentBehavior> commentTapBehavior,
      Value<CommentBehavior> commentLongPressBehavior,
      Value<int?> appBarColor,
      Value<bool> useBottomBar,
      Value<bool> reverseCommunityList,
      Value<bool> backOnHomeScreenShowCommunityList,
      Value<bool> showPlatformColorAccents,
      Value<bool> showPlatformColorTextAccents,
      Value<bool> redditCopyOldRedditLinks,
      Value<String?> redditClientId,
      Value<String?> redditRedirectUri,
      Value<String?> redditDeviceId,
      Value<String?> redditUserAgent,
      Value<int> diggPostsFetchDepth,
      Value<String?> diggUserAgent,
      Value<SearchType?> searchType,
      Value<String?> activeUserId,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$Database, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Platform?, Platform, String>
  get homeCommunityPlatform => $composableBuilder(
    column: $table.homeCommunityPlatform,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get homeCommunityName => $composableBuilder(
    column: $table.homeCommunityName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showCommentImages => $composableBuilder(
    column: $table.showCommentImages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoplayVideos => $composableBuilder(
    column: $table.autoplayVideos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get swipePostsToVote => $composableBuilder(
    column: $table.swipePostsToVote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get swipeCommentsToVote => $composableBuilder(
    column: $table.swipeCommentsToVote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showCommentVotingEdges => $composableBuilder(
    column: $table.showCommentVotingEdges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CommentBehavior, CommentBehavior, String>
  get commentTapBehavior => $composableBuilder(
    column: $table.commentTapBehavior,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CommentBehavior, CommentBehavior, String>
  get commentLongPressBehavior => $composableBuilder(
    column: $table.commentLongPressBehavior,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get appBarColor => $composableBuilder(
    column: $table.appBarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useBottomBar => $composableBuilder(
    column: $table.useBottomBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reverseCommunityList => $composableBuilder(
    column: $table.reverseCommunityList,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backOnHomeScreenShowCommunityList =>
      $composableBuilder(
        column: $table.backOnHomeScreenShowCommunityList,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<bool> get showPlatformColorAccents => $composableBuilder(
    column: $table.showPlatformColorAccents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showPlatformColorTextAccents => $composableBuilder(
    column: $table.showPlatformColorTextAccents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get redditCopyOldRedditLinks => $composableBuilder(
    column: $table.redditCopyOldRedditLinks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redditClientId => $composableBuilder(
    column: $table.redditClientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redditRedirectUri => $composableBuilder(
    column: $table.redditRedirectUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redditDeviceId => $composableBuilder(
    column: $table.redditDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redditUserAgent => $composableBuilder(
    column: $table.redditUserAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diggPostsFetchDepth => $composableBuilder(
    column: $table.diggPostsFetchDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diggUserAgent => $composableBuilder(
    column: $table.diggUserAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SearchType?, SearchType, String>
  get searchType => $composableBuilder(
    column: $table.searchType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get activeUserId => $composableBuilder(
    column: $table.activeUserId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$Database, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeCommunityPlatform => $composableBuilder(
    column: $table.homeCommunityPlatform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeCommunityName => $composableBuilder(
    column: $table.homeCommunityName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showCommentImages => $composableBuilder(
    column: $table.showCommentImages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoplayVideos => $composableBuilder(
    column: $table.autoplayVideos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get swipePostsToVote => $composableBuilder(
    column: $table.swipePostsToVote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get swipeCommentsToVote => $composableBuilder(
    column: $table.swipeCommentsToVote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showCommentVotingEdges => $composableBuilder(
    column: $table.showCommentVotingEdges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commentTapBehavior => $composableBuilder(
    column: $table.commentTapBehavior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commentLongPressBehavior => $composableBuilder(
    column: $table.commentLongPressBehavior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appBarColor => $composableBuilder(
    column: $table.appBarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useBottomBar => $composableBuilder(
    column: $table.useBottomBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reverseCommunityList => $composableBuilder(
    column: $table.reverseCommunityList,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backOnHomeScreenShowCommunityList =>
      $composableBuilder(
        column: $table.backOnHomeScreenShowCommunityList,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<bool> get showPlatformColorAccents => $composableBuilder(
    column: $table.showPlatformColorAccents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showPlatformColorTextAccents => $composableBuilder(
    column: $table.showPlatformColorTextAccents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get redditCopyOldRedditLinks => $composableBuilder(
    column: $table.redditCopyOldRedditLinks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redditClientId => $composableBuilder(
    column: $table.redditClientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redditRedirectUri => $composableBuilder(
    column: $table.redditRedirectUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redditDeviceId => $composableBuilder(
    column: $table.redditDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redditUserAgent => $composableBuilder(
    column: $table.redditUserAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diggPostsFetchDepth => $composableBuilder(
    column: $table.diggPostsFetchDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diggUserAgent => $composableBuilder(
    column: $table.diggUserAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchType => $composableBuilder(
    column: $table.searchType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeUserId => $composableBuilder(
    column: $table.activeUserId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$Database, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Platform?, String>
  get homeCommunityPlatform => $composableBuilder(
    column: $table.homeCommunityPlatform,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeCommunityName => $composableBuilder(
    column: $table.homeCommunityName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showCommentImages => $composableBuilder(
    column: $table.showCommentImages,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoplayVideos => $composableBuilder(
    column: $table.autoplayVideos,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get swipePostsToVote => $composableBuilder(
    column: $table.swipePostsToVote,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get swipeCommentsToVote => $composableBuilder(
    column: $table.swipeCommentsToVote,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showCommentVotingEdges => $composableBuilder(
    column: $table.showCommentVotingEdges,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CommentBehavior, String>
  get commentTapBehavior => $composableBuilder(
    column: $table.commentTapBehavior,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CommentBehavior, String>
  get commentLongPressBehavior => $composableBuilder(
    column: $table.commentLongPressBehavior,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appBarColor => $composableBuilder(
    column: $table.appBarColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useBottomBar => $composableBuilder(
    column: $table.useBottomBar,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reverseCommunityList => $composableBuilder(
    column: $table.reverseCommunityList,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backOnHomeScreenShowCommunityList =>
      $composableBuilder(
        column: $table.backOnHomeScreenShowCommunityList,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get showPlatformColorAccents => $composableBuilder(
    column: $table.showPlatformColorAccents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showPlatformColorTextAccents => $composableBuilder(
    column: $table.showPlatformColorTextAccents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get redditCopyOldRedditLinks => $composableBuilder(
    column: $table.redditCopyOldRedditLinks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get redditClientId => $composableBuilder(
    column: $table.redditClientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get redditRedirectUri => $composableBuilder(
    column: $table.redditRedirectUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get redditDeviceId => $composableBuilder(
    column: $table.redditDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get redditUserAgent => $composableBuilder(
    column: $table.redditUserAgent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diggPostsFetchDepth => $composableBuilder(
    column: $table.diggPostsFetchDepth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get diggUserAgent => $composableBuilder(
    column: $table.diggUserAgent,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SearchType?, String> get searchType =>
      $composableBuilder(
        column: $table.searchType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get activeUserId => $composableBuilder(
    column: $table.activeUserId,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$Database,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$Database, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$Database db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Platform?> homeCommunityPlatform = const Value.absent(),
                Value<String?> homeCommunityName = const Value.absent(),
                Value<bool> showCommentImages = const Value.absent(),
                Value<bool> autoplayVideos = const Value.absent(),
                Value<bool> swipePostsToVote = const Value.absent(),
                Value<bool> swipeCommentsToVote = const Value.absent(),
                Value<bool> showCommentVotingEdges = const Value.absent(),
                Value<CommentBehavior> commentTapBehavior =
                    const Value.absent(),
                Value<CommentBehavior> commentLongPressBehavior =
                    const Value.absent(),
                Value<int?> appBarColor = const Value.absent(),
                Value<bool> useBottomBar = const Value.absent(),
                Value<bool> reverseCommunityList = const Value.absent(),
                Value<bool> backOnHomeScreenShowCommunityList =
                    const Value.absent(),
                Value<bool> showPlatformColorAccents = const Value.absent(),
                Value<bool> showPlatformColorTextAccents = const Value.absent(),
                Value<bool> redditCopyOldRedditLinks = const Value.absent(),
                Value<String?> redditClientId = const Value.absent(),
                Value<String?> redditRedirectUri = const Value.absent(),
                Value<String?> redditDeviceId = const Value.absent(),
                Value<String?> redditUserAgent = const Value.absent(),
                Value<int> diggPostsFetchDepth = const Value.absent(),
                Value<String?> diggUserAgent = const Value.absent(),
                Value<SearchType?> searchType = const Value.absent(),
                Value<String?> activeUserId = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                homeCommunityPlatform: homeCommunityPlatform,
                homeCommunityName: homeCommunityName,
                showCommentImages: showCommentImages,
                autoplayVideos: autoplayVideos,
                swipePostsToVote: swipePostsToVote,
                swipeCommentsToVote: swipeCommentsToVote,
                showCommentVotingEdges: showCommentVotingEdges,
                commentTapBehavior: commentTapBehavior,
                commentLongPressBehavior: commentLongPressBehavior,
                appBarColor: appBarColor,
                useBottomBar: useBottomBar,
                reverseCommunityList: reverseCommunityList,
                backOnHomeScreenShowCommunityList:
                    backOnHomeScreenShowCommunityList,
                showPlatformColorAccents: showPlatformColorAccents,
                showPlatformColorTextAccents: showPlatformColorTextAccents,
                redditCopyOldRedditLinks: redditCopyOldRedditLinks,
                redditClientId: redditClientId,
                redditRedirectUri: redditRedirectUri,
                redditDeviceId: redditDeviceId,
                redditUserAgent: redditUserAgent,
                diggPostsFetchDepth: diggPostsFetchDepth,
                diggUserAgent: diggUserAgent,
                searchType: searchType,
                activeUserId: activeUserId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Platform?> homeCommunityPlatform = const Value.absent(),
                Value<String?> homeCommunityName = const Value.absent(),
                Value<bool> showCommentImages = const Value.absent(),
                Value<bool> autoplayVideos = const Value.absent(),
                Value<bool> swipePostsToVote = const Value.absent(),
                Value<bool> swipeCommentsToVote = const Value.absent(),
                Value<bool> showCommentVotingEdges = const Value.absent(),
                Value<CommentBehavior> commentTapBehavior =
                    const Value.absent(),
                Value<CommentBehavior> commentLongPressBehavior =
                    const Value.absent(),
                Value<int?> appBarColor = const Value.absent(),
                Value<bool> useBottomBar = const Value.absent(),
                Value<bool> reverseCommunityList = const Value.absent(),
                Value<bool> backOnHomeScreenShowCommunityList =
                    const Value.absent(),
                Value<bool> showPlatformColorAccents = const Value.absent(),
                Value<bool> showPlatformColorTextAccents = const Value.absent(),
                Value<bool> redditCopyOldRedditLinks = const Value.absent(),
                Value<String?> redditClientId = const Value.absent(),
                Value<String?> redditRedirectUri = const Value.absent(),
                Value<String?> redditDeviceId = const Value.absent(),
                Value<String?> redditUserAgent = const Value.absent(),
                Value<int> diggPostsFetchDepth = const Value.absent(),
                Value<String?> diggUserAgent = const Value.absent(),
                Value<SearchType?> searchType = const Value.absent(),
                Value<String?> activeUserId = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                homeCommunityPlatform: homeCommunityPlatform,
                homeCommunityName: homeCommunityName,
                showCommentImages: showCommentImages,
                autoplayVideos: autoplayVideos,
                swipePostsToVote: swipePostsToVote,
                swipeCommentsToVote: swipeCommentsToVote,
                showCommentVotingEdges: showCommentVotingEdges,
                commentTapBehavior: commentTapBehavior,
                commentLongPressBehavior: commentLongPressBehavior,
                appBarColor: appBarColor,
                useBottomBar: useBottomBar,
                reverseCommunityList: reverseCommunityList,
                backOnHomeScreenShowCommunityList:
                    backOnHomeScreenShowCommunityList,
                showPlatformColorAccents: showPlatformColorAccents,
                showPlatformColorTextAccents: showPlatformColorTextAccents,
                redditCopyOldRedditLinks: redditCopyOldRedditLinks,
                redditClientId: redditClientId,
                redditRedirectUri: redditRedirectUri,
                redditDeviceId: redditDeviceId,
                redditUserAgent: redditUserAgent,
                diggPostsFetchDepth: diggPostsFetchDepth,
                diggUserAgent: diggUserAgent,
                searchType: searchType,
                activeUserId: activeUserId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$Database, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required Platform platform,
      required String id,
      required String name,
      required String iconUrl,
      required int inboxCount,
      required int score,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<Platform> platform,
      Value<String> id,
      Value<String> name,
      Value<String> iconUrl,
      Value<int> inboxCount,
      Value<int> score,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$Database, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Platform, Platform, String> get platform =>
      $composableBuilder(
        column: $table.platform,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inboxCount => $composableBuilder(
    column: $table.inboxCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer extends Composer<_$Database, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inboxCount => $composableBuilder(
    column: $table.inboxCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer extends Composer<_$Database, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Platform, String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<int> get inboxCount => $composableBuilder(
    column: $table.inboxCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$Database,
          $UsersTable,
          LoggedInUser,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (LoggedInUser, BaseReferences<_$Database, $UsersTable, LoggedInUser>),
          LoggedInUser,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$Database db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Platform> platform = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<int> inboxCount = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                platform: platform,
                id: id,
                name: name,
                iconUrl: iconUrl,
                inboxCount: inboxCount,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Platform platform,
                required String id,
                required String name,
                required String iconUrl,
                required int inboxCount,
                required int score,
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                platform: platform,
                id: id,
                name: name,
                iconUrl: iconUrl,
                inboxCount: inboxCount,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $UsersTable,
      LoggedInUser,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (LoggedInUser, BaseReferences<_$Database, $UsersTable, LoggedInUser>),
      LoggedInUser,
      PrefetchHooks Function()
    >;
typedef $$UserCommunitiesTableCreateCompanionBuilder =
    UserCommunitiesCompanion Function({
      required Platform platform,
      required String userId,
      required String communityName,
      Value<int> rowid,
    });
typedef $$UserCommunitiesTableUpdateCompanionBuilder =
    UserCommunitiesCompanion Function({
      Value<Platform> platform,
      Value<String> userId,
      Value<String> communityName,
      Value<int> rowid,
    });

class $$UserCommunitiesTableFilterComposer
    extends Composer<_$Database, $UserCommunitiesTable> {
  $$UserCommunitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Platform, Platform, String> get platform =>
      $composableBuilder(
        column: $table.platform,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get communityName => $composableBuilder(
    column: $table.communityName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserCommunitiesTableOrderingComposer
    extends Composer<_$Database, $UserCommunitiesTable> {
  $$UserCommunitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get communityName => $composableBuilder(
    column: $table.communityName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserCommunitiesTableAnnotationComposer
    extends Composer<_$Database, $UserCommunitiesTable> {
  $$UserCommunitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Platform, String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get communityName => $composableBuilder(
    column: $table.communityName,
    builder: (column) => column,
  );
}

class $$UserCommunitiesTableTableManager
    extends
        RootTableManager<
          _$Database,
          $UserCommunitiesTable,
          UserCommunity,
          $$UserCommunitiesTableFilterComposer,
          $$UserCommunitiesTableOrderingComposer,
          $$UserCommunitiesTableAnnotationComposer,
          $$UserCommunitiesTableCreateCompanionBuilder,
          $$UserCommunitiesTableUpdateCompanionBuilder,
          (
            UserCommunity,
            BaseReferences<_$Database, $UserCommunitiesTable, UserCommunity>,
          ),
          UserCommunity,
          PrefetchHooks Function()
        > {
  $$UserCommunitiesTableTableManager(_$Database db, $UserCommunitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCommunitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCommunitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserCommunitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Platform> platform = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> communityName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCommunitiesCompanion(
                platform: platform,
                userId: userId,
                communityName: communityName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Platform platform,
                required String userId,
                required String communityName,
                Value<int> rowid = const Value.absent(),
              }) => UserCommunitiesCompanion.insert(
                platform: platform,
                userId: userId,
                communityName: communityName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserCommunitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $UserCommunitiesTable,
      UserCommunity,
      $$UserCommunitiesTableFilterComposer,
      $$UserCommunitiesTableOrderingComposer,
      $$UserCommunitiesTableAnnotationComposer,
      $$UserCommunitiesTableCreateCompanionBuilder,
      $$UserCommunitiesTableUpdateCompanionBuilder,
      (
        UserCommunity,
        BaseReferences<_$Database, $UserCommunitiesTable, UserCommunity>,
      ),
      UserCommunity,
      PrefetchHooks Function()
    >;
typedef $$CommunitiesTableCreateCompanionBuilder =
    CommunitiesCompanion Function({
      required Platform platform,
      required String? name,
      Value<String?> id,
      Value<bool> isFavorite,
      Value<int> rowid,
    });
typedef $$CommunitiesTableUpdateCompanionBuilder =
    CommunitiesCompanion Function({
      Value<Platform> platform,
      Value<String?> name,
      Value<String?> id,
      Value<bool> isFavorite,
      Value<int> rowid,
    });

class $$CommunitiesTableFilterComposer
    extends Composer<_$Database, $CommunitiesTable> {
  $$CommunitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Platform, Platform, String> get platform =>
      $composableBuilder(
        column: $table.platform,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<String?, String, String> get name =>
      $composableBuilder(
        column: $table.name,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommunitiesTableOrderingComposer
    extends Composer<_$Database, $CommunitiesTable> {
  $$CommunitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommunitiesTableAnnotationComposer
    extends Composer<_$Database, $CommunitiesTable> {
  $$CommunitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Platform, String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumnWithTypeConverter<String?, String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );
}

class $$CommunitiesTableTableManager
    extends
        RootTableManager<
          _$Database,
          $CommunitiesTable,
          Community,
          $$CommunitiesTableFilterComposer,
          $$CommunitiesTableOrderingComposer,
          $$CommunitiesTableAnnotationComposer,
          $$CommunitiesTableCreateCompanionBuilder,
          $$CommunitiesTableUpdateCompanionBuilder,
          (Community, BaseReferences<_$Database, $CommunitiesTable, Community>),
          Community,
          PrefetchHooks Function()
        > {
  $$CommunitiesTableTableManager(_$Database db, $CommunitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommunitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommunitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommunitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Platform> platform = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> id = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommunitiesCompanion(
                platform: platform,
                name: name,
                id: id,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Platform platform,
                required String? name,
                Value<String?> id = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommunitiesCompanion.insert(
                platform: platform,
                name: name,
                id: id,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommunitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $CommunitiesTable,
      Community,
      $$CommunitiesTableFilterComposer,
      $$CommunitiesTableOrderingComposer,
      $$CommunitiesTableAnnotationComposer,
      $$CommunitiesTableCreateCompanionBuilder,
      $$CommunitiesTableUpdateCompanionBuilder,
      (Community, BaseReferences<_$Database, $CommunitiesTable, Community>),
      Community,
      PrefetchHooks Function()
    >;
typedef $$HistoryTableCreateCompanionBuilder =
    HistoryCompanion Function({
      required String itemId,
      required HistoryType type,
      Value<int> rowid,
    });
typedef $$HistoryTableUpdateCompanionBuilder =
    HistoryCompanion Function({
      Value<String> itemId,
      Value<HistoryType> type,
      Value<int> rowid,
    });

class $$HistoryTableFilterComposer extends Composer<_$Database, $HistoryTable> {
  $$HistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HistoryType, HistoryType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$HistoryTableOrderingComposer
    extends Composer<_$Database, $HistoryTable> {
  $$HistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryTableAnnotationComposer
    extends Composer<_$Database, $HistoryTable> {
  $$HistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HistoryType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$HistoryTableTableManager
    extends
        RootTableManager<
          _$Database,
          $HistoryTable,
          HistoryData,
          $$HistoryTableFilterComposer,
          $$HistoryTableOrderingComposer,
          $$HistoryTableAnnotationComposer,
          $$HistoryTableCreateCompanionBuilder,
          $$HistoryTableUpdateCompanionBuilder,
          (HistoryData, BaseReferences<_$Database, $HistoryTable, HistoryData>),
          HistoryData,
          PrefetchHooks Function()
        > {
  $$HistoryTableTableManager(_$Database db, $HistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<HistoryType> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion(itemId: itemId, type: type, rowid: rowid),
          createCompanionCallback:
              ({
                required String itemId,
                required HistoryType type,
                Value<int> rowid = const Value.absent(),
              }) => HistoryCompanion.insert(
                itemId: itemId,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $HistoryTable,
      HistoryData,
      $$HistoryTableFilterComposer,
      $$HistoryTableOrderingComposer,
      $$HistoryTableAnnotationComposer,
      $$HistoryTableCreateCompanionBuilder,
      $$HistoryTableUpdateCompanionBuilder,
      (HistoryData, BaseReferences<_$Database, $HistoryTable, HistoryData>),
      HistoryData,
      PrefetchHooks Function()
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$CookiesTableTableManager get cookies =>
      $$CookiesTableTableManager(_db, _db.cookies);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$UserCommunitiesTableTableManager get userCommunities =>
      $$UserCommunitiesTableTableManager(_db, _db.userCommunities);
  $$CommunitiesTableTableManager get communities =>
      $$CommunitiesTableTableManager(_db, _db.communities);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db, _db.history);
}
