// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _showMorePlatformColorAccentsMeta =
      const VerificationMeta('showMorePlatformColorAccents');
  @override
  late final GeneratedColumn<bool> showMorePlatformColorAccents =
      GeneratedColumn<bool>(
        'show_more_platform_color_accents',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_more_platform_color_accents" IN (0, 1))',
        ),
        defaultValue: const Constant(
          Constants.defaultShowMorePlatformColorAccents,
        ),
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
  static const VerificationMeta _userAgentMeta = const VerificationMeta(
    'userAgent',
  );
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
    'user_agent',
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
    appBarColor,
    useBottomBar,
    showMorePlatformColorAccents,
    showPlatformColorTextAccents,
    redditClientId,
    redditRedirectUri,
    redditCopyOldRedditLinks,
    diggPostsFetchDepth,
    userAgent,
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
    if (data.containsKey('show_more_platform_color_accents')) {
      context.handle(
        _showMorePlatformColorAccentsMeta,
        showMorePlatformColorAccents.isAcceptableOrUnknown(
          data['show_more_platform_color_accents']!,
          _showMorePlatformColorAccentsMeta,
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
    if (data.containsKey('reddit_copy_old_reddit_links')) {
      context.handle(
        _redditCopyOldRedditLinksMeta,
        redditCopyOldRedditLinks.isAcceptableOrUnknown(
          data['reddit_copy_old_reddit_links']!,
          _redditCopyOldRedditLinksMeta,
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
    if (data.containsKey('user_agent')) {
      context.handle(
        _userAgentMeta,
        userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta),
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
      appBarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}app_bar_color'],
      ),
      useBottomBar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_bottom_bar'],
      )!,
      showMorePlatformColorAccents: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_more_platform_color_accents'],
      )!,
      showPlatformColorTextAccents: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_platform_color_text_accents'],
      )!,
      redditClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reddit_client_id'],
      ),
      redditRedirectUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reddit_redirect_uri'],
      ),
      redditCopyOldRedditLinks: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reddit_copy_old_reddit_links'],
      )!,
      diggPostsFetchDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}digg_posts_fetch_depth'],
      )!,
      userAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_agent'],
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
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final Platform? homeCommunityPlatform;
  final String? homeCommunityName;
  final bool showCommentImages;
  final bool autoplayVideos;
  final int? appBarColor;
  final bool useBottomBar;
  final bool showMorePlatformColorAccents;
  final bool showPlatformColorTextAccents;
  final String? redditClientId;
  final String? redditRedirectUri;
  final bool redditCopyOldRedditLinks;
  final int diggPostsFetchDepth;
  final String? userAgent;
  const Setting({
    required this.id,
    this.homeCommunityPlatform,
    this.homeCommunityName,
    required this.showCommentImages,
    required this.autoplayVideos,
    this.appBarColor,
    required this.useBottomBar,
    required this.showMorePlatformColorAccents,
    required this.showPlatformColorTextAccents,
    this.redditClientId,
    this.redditRedirectUri,
    required this.redditCopyOldRedditLinks,
    required this.diggPostsFetchDepth,
    this.userAgent,
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
    if (!nullToAbsent || appBarColor != null) {
      map['app_bar_color'] = Variable<int>(appBarColor);
    }
    map['use_bottom_bar'] = Variable<bool>(useBottomBar);
    map['show_more_platform_color_accents'] = Variable<bool>(
      showMorePlatformColorAccents,
    );
    map['show_platform_color_text_accents'] = Variable<bool>(
      showPlatformColorTextAccents,
    );
    if (!nullToAbsent || redditClientId != null) {
      map['reddit_client_id'] = Variable<String>(redditClientId);
    }
    if (!nullToAbsent || redditRedirectUri != null) {
      map['reddit_redirect_uri'] = Variable<String>(redditRedirectUri);
    }
    map['reddit_copy_old_reddit_links'] = Variable<bool>(
      redditCopyOldRedditLinks,
    );
    map['digg_posts_fetch_depth'] = Variable<int>(diggPostsFetchDepth);
    if (!nullToAbsent || userAgent != null) {
      map['user_agent'] = Variable<String>(userAgent);
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
      appBarColor: appBarColor == null && nullToAbsent
          ? const Value.absent()
          : Value(appBarColor),
      useBottomBar: Value(useBottomBar),
      showMorePlatformColorAccents: Value(showMorePlatformColorAccents),
      showPlatformColorTextAccents: Value(showPlatformColorTextAccents),
      redditClientId: redditClientId == null && nullToAbsent
          ? const Value.absent()
          : Value(redditClientId),
      redditRedirectUri: redditRedirectUri == null && nullToAbsent
          ? const Value.absent()
          : Value(redditRedirectUri),
      redditCopyOldRedditLinks: Value(redditCopyOldRedditLinks),
      diggPostsFetchDepth: Value(diggPostsFetchDepth),
      userAgent: userAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgent),
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
      appBarColor: serializer.fromJson<int?>(json['appBarColor']),
      useBottomBar: serializer.fromJson<bool>(json['useBottomBar']),
      showMorePlatformColorAccents: serializer.fromJson<bool>(
        json['showMorePlatformColorAccents'],
      ),
      showPlatformColorTextAccents: serializer.fromJson<bool>(
        json['showPlatformColorTextAccents'],
      ),
      redditClientId: serializer.fromJson<String?>(json['redditClientId']),
      redditRedirectUri: serializer.fromJson<String?>(
        json['redditRedirectUri'],
      ),
      redditCopyOldRedditLinks: serializer.fromJson<bool>(
        json['redditCopyOldRedditLinks'],
      ),
      diggPostsFetchDepth: serializer.fromJson<int>(
        json['diggPostsFetchDepth'],
      ),
      userAgent: serializer.fromJson<String?>(json['userAgent']),
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
      'appBarColor': serializer.toJson<int?>(appBarColor),
      'useBottomBar': serializer.toJson<bool>(useBottomBar),
      'showMorePlatformColorAccents': serializer.toJson<bool>(
        showMorePlatformColorAccents,
      ),
      'showPlatformColorTextAccents': serializer.toJson<bool>(
        showPlatformColorTextAccents,
      ),
      'redditClientId': serializer.toJson<String?>(redditClientId),
      'redditRedirectUri': serializer.toJson<String?>(redditRedirectUri),
      'redditCopyOldRedditLinks': serializer.toJson<bool>(
        redditCopyOldRedditLinks,
      ),
      'diggPostsFetchDepth': serializer.toJson<int>(diggPostsFetchDepth),
      'userAgent': serializer.toJson<String?>(userAgent),
    };
  }

  Setting copyWith({
    int? id,
    Value<Platform?> homeCommunityPlatform = const Value.absent(),
    Value<String?> homeCommunityName = const Value.absent(),
    bool? showCommentImages,
    bool? autoplayVideos,
    Value<int?> appBarColor = const Value.absent(),
    bool? useBottomBar,
    bool? showMorePlatformColorAccents,
    bool? showPlatformColorTextAccents,
    Value<String?> redditClientId = const Value.absent(),
    Value<String?> redditRedirectUri = const Value.absent(),
    bool? redditCopyOldRedditLinks,
    int? diggPostsFetchDepth,
    Value<String?> userAgent = const Value.absent(),
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
    appBarColor: appBarColor.present ? appBarColor.value : this.appBarColor,
    useBottomBar: useBottomBar ?? this.useBottomBar,
    showMorePlatformColorAccents:
        showMorePlatformColorAccents ?? this.showMorePlatformColorAccents,
    showPlatformColorTextAccents:
        showPlatformColorTextAccents ?? this.showPlatformColorTextAccents,
    redditClientId: redditClientId.present
        ? redditClientId.value
        : this.redditClientId,
    redditRedirectUri: redditRedirectUri.present
        ? redditRedirectUri.value
        : this.redditRedirectUri,
    redditCopyOldRedditLinks:
        redditCopyOldRedditLinks ?? this.redditCopyOldRedditLinks,
    diggPostsFetchDepth: diggPostsFetchDepth ?? this.diggPostsFetchDepth,
    userAgent: userAgent.present ? userAgent.value : this.userAgent,
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
      appBarColor: data.appBarColor.present
          ? data.appBarColor.value
          : this.appBarColor,
      useBottomBar: data.useBottomBar.present
          ? data.useBottomBar.value
          : this.useBottomBar,
      showMorePlatformColorAccents: data.showMorePlatformColorAccents.present
          ? data.showMorePlatformColorAccents.value
          : this.showMorePlatformColorAccents,
      showPlatformColorTextAccents: data.showPlatformColorTextAccents.present
          ? data.showPlatformColorTextAccents.value
          : this.showPlatformColorTextAccents,
      redditClientId: data.redditClientId.present
          ? data.redditClientId.value
          : this.redditClientId,
      redditRedirectUri: data.redditRedirectUri.present
          ? data.redditRedirectUri.value
          : this.redditRedirectUri,
      redditCopyOldRedditLinks: data.redditCopyOldRedditLinks.present
          ? data.redditCopyOldRedditLinks.value
          : this.redditCopyOldRedditLinks,
      diggPostsFetchDepth: data.diggPostsFetchDepth.present
          ? data.diggPostsFetchDepth.value
          : this.diggPostsFetchDepth,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
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
          ..write('appBarColor: $appBarColor, ')
          ..write('useBottomBar: $useBottomBar, ')
          ..write(
            'showMorePlatformColorAccents: $showMorePlatformColorAccents, ',
          )
          ..write(
            'showPlatformColorTextAccents: $showPlatformColorTextAccents, ',
          )
          ..write('redditClientId: $redditClientId, ')
          ..write('redditRedirectUri: $redditRedirectUri, ')
          ..write('redditCopyOldRedditLinks: $redditCopyOldRedditLinks, ')
          ..write('diggPostsFetchDepth: $diggPostsFetchDepth, ')
          ..write('userAgent: $userAgent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    homeCommunityPlatform,
    homeCommunityName,
    showCommentImages,
    autoplayVideos,
    appBarColor,
    useBottomBar,
    showMorePlatformColorAccents,
    showPlatformColorTextAccents,
    redditClientId,
    redditRedirectUri,
    redditCopyOldRedditLinks,
    diggPostsFetchDepth,
    userAgent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.homeCommunityPlatform == this.homeCommunityPlatform &&
          other.homeCommunityName == this.homeCommunityName &&
          other.showCommentImages == this.showCommentImages &&
          other.autoplayVideos == this.autoplayVideos &&
          other.appBarColor == this.appBarColor &&
          other.useBottomBar == this.useBottomBar &&
          other.showMorePlatformColorAccents ==
              this.showMorePlatformColorAccents &&
          other.showPlatformColorTextAccents ==
              this.showPlatformColorTextAccents &&
          other.redditClientId == this.redditClientId &&
          other.redditRedirectUri == this.redditRedirectUri &&
          other.redditCopyOldRedditLinks == this.redditCopyOldRedditLinks &&
          other.diggPostsFetchDepth == this.diggPostsFetchDepth &&
          other.userAgent == this.userAgent);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<Platform?> homeCommunityPlatform;
  final Value<String?> homeCommunityName;
  final Value<bool> showCommentImages;
  final Value<bool> autoplayVideos;
  final Value<int?> appBarColor;
  final Value<bool> useBottomBar;
  final Value<bool> showMorePlatformColorAccents;
  final Value<bool> showPlatformColorTextAccents;
  final Value<String?> redditClientId;
  final Value<String?> redditRedirectUri;
  final Value<bool> redditCopyOldRedditLinks;
  final Value<int> diggPostsFetchDepth;
  final Value<String?> userAgent;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.homeCommunityPlatform = const Value.absent(),
    this.homeCommunityName = const Value.absent(),
    this.showCommentImages = const Value.absent(),
    this.autoplayVideos = const Value.absent(),
    this.appBarColor = const Value.absent(),
    this.useBottomBar = const Value.absent(),
    this.showMorePlatformColorAccents = const Value.absent(),
    this.showPlatformColorTextAccents = const Value.absent(),
    this.redditClientId = const Value.absent(),
    this.redditRedirectUri = const Value.absent(),
    this.redditCopyOldRedditLinks = const Value.absent(),
    this.diggPostsFetchDepth = const Value.absent(),
    this.userAgent = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.homeCommunityPlatform = const Value.absent(),
    this.homeCommunityName = const Value.absent(),
    this.showCommentImages = const Value.absent(),
    this.autoplayVideos = const Value.absent(),
    this.appBarColor = const Value.absent(),
    this.useBottomBar = const Value.absent(),
    this.showMorePlatformColorAccents = const Value.absent(),
    this.showPlatformColorTextAccents = const Value.absent(),
    this.redditClientId = const Value.absent(),
    this.redditRedirectUri = const Value.absent(),
    this.redditCopyOldRedditLinks = const Value.absent(),
    this.diggPostsFetchDepth = const Value.absent(),
    this.userAgent = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? homeCommunityPlatform,
    Expression<String>? homeCommunityName,
    Expression<bool>? showCommentImages,
    Expression<bool>? autoplayVideos,
    Expression<int>? appBarColor,
    Expression<bool>? useBottomBar,
    Expression<bool>? showMorePlatformColorAccents,
    Expression<bool>? showPlatformColorTextAccents,
    Expression<String>? redditClientId,
    Expression<String>? redditRedirectUri,
    Expression<bool>? redditCopyOldRedditLinks,
    Expression<int>? diggPostsFetchDepth,
    Expression<String>? userAgent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeCommunityPlatform != null)
        'home_community_platform': homeCommunityPlatform,
      if (homeCommunityName != null) 'home_community_name': homeCommunityName,
      if (showCommentImages != null) 'show_comment_images': showCommentImages,
      if (autoplayVideos != null) 'autoplay_videos': autoplayVideos,
      if (appBarColor != null) 'app_bar_color': appBarColor,
      if (useBottomBar != null) 'use_bottom_bar': useBottomBar,
      if (showMorePlatformColorAccents != null)
        'show_more_platform_color_accents': showMorePlatformColorAccents,
      if (showPlatformColorTextAccents != null)
        'show_platform_color_text_accents': showPlatformColorTextAccents,
      if (redditClientId != null) 'reddit_client_id': redditClientId,
      if (redditRedirectUri != null) 'reddit_redirect_uri': redditRedirectUri,
      if (redditCopyOldRedditLinks != null)
        'reddit_copy_old_reddit_links': redditCopyOldRedditLinks,
      if (diggPostsFetchDepth != null)
        'digg_posts_fetch_depth': diggPostsFetchDepth,
      if (userAgent != null) 'user_agent': userAgent,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<Platform?>? homeCommunityPlatform,
    Value<String?>? homeCommunityName,
    Value<bool>? showCommentImages,
    Value<bool>? autoplayVideos,
    Value<int?>? appBarColor,
    Value<bool>? useBottomBar,
    Value<bool>? showMorePlatformColorAccents,
    Value<bool>? showPlatformColorTextAccents,
    Value<String?>? redditClientId,
    Value<String?>? redditRedirectUri,
    Value<bool>? redditCopyOldRedditLinks,
    Value<int>? diggPostsFetchDepth,
    Value<String?>? userAgent,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      homeCommunityPlatform:
          homeCommunityPlatform ?? this.homeCommunityPlatform,
      homeCommunityName: homeCommunityName ?? this.homeCommunityName,
      showCommentImages: showCommentImages ?? this.showCommentImages,
      autoplayVideos: autoplayVideos ?? this.autoplayVideos,
      appBarColor: appBarColor ?? this.appBarColor,
      useBottomBar: useBottomBar ?? this.useBottomBar,
      showMorePlatformColorAccents:
          showMorePlatformColorAccents ?? this.showMorePlatformColorAccents,
      showPlatformColorTextAccents:
          showPlatformColorTextAccents ?? this.showPlatformColorTextAccents,
      redditClientId: redditClientId ?? this.redditClientId,
      redditRedirectUri: redditRedirectUri ?? this.redditRedirectUri,
      redditCopyOldRedditLinks:
          redditCopyOldRedditLinks ?? this.redditCopyOldRedditLinks,
      diggPostsFetchDepth: diggPostsFetchDepth ?? this.diggPostsFetchDepth,
      userAgent: userAgent ?? this.userAgent,
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
    if (appBarColor.present) {
      map['app_bar_color'] = Variable<int>(appBarColor.value);
    }
    if (useBottomBar.present) {
      map['use_bottom_bar'] = Variable<bool>(useBottomBar.value);
    }
    if (showMorePlatformColorAccents.present) {
      map['show_more_platform_color_accents'] = Variable<bool>(
        showMorePlatformColorAccents.value,
      );
    }
    if (showPlatformColorTextAccents.present) {
      map['show_platform_color_text_accents'] = Variable<bool>(
        showPlatformColorTextAccents.value,
      );
    }
    if (redditClientId.present) {
      map['reddit_client_id'] = Variable<String>(redditClientId.value);
    }
    if (redditRedirectUri.present) {
      map['reddit_redirect_uri'] = Variable<String>(redditRedirectUri.value);
    }
    if (redditCopyOldRedditLinks.present) {
      map['reddit_copy_old_reddit_links'] = Variable<bool>(
        redditCopyOldRedditLinks.value,
      );
    }
    if (diggPostsFetchDepth.present) {
      map['digg_posts_fetch_depth'] = Variable<int>(diggPostsFetchDepth.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
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
          ..write('appBarColor: $appBarColor, ')
          ..write('useBottomBar: $useBottomBar, ')
          ..write(
            'showMorePlatformColorAccents: $showMorePlatformColorAccents, ',
          )
          ..write(
            'showPlatformColorTextAccents: $showPlatformColorTextAccents, ',
          )
          ..write('redditClientId: $redditClientId, ')
          ..write('redditRedirectUri: $redditRedirectUri, ')
          ..write('redditCopyOldRedditLinks: $redditCopyOldRedditLinks, ')
          ..write('diggPostsFetchDepth: $diggPostsFetchDepth, ')
          ..write('userAgent: $userAgent')
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
  List<GeneratedColumn> get $columns => [platform, name, isFavorite];
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
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const CommunitiesCompanion({
    this.platform = const Value.absent(),
    this.name = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommunitiesCompanion.insert({
    required Platform platform,
    required String? name,
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : platform = Value(platform),
       name = Value(name);
  static Insertable<Community> custom({
    Expression<String>? platform,
    Expression<String>? name,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (platform != null) 'platform': platform,
      if (name != null) 'name': name,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommunitiesCompanion copyWith({
    Value<Platform>? platform,
    Value<String?>? name,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return CommunitiesCompanion(
      platform: platform ?? this.platform,
      name: name ?? this.name,
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
  late final $SettingsTable settings = $SettingsTable(this);
  late final $CommunitiesTable communities = $CommunitiesTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    communities,
    history,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<Platform?> homeCommunityPlatform,
      Value<String?> homeCommunityName,
      Value<bool> showCommentImages,
      Value<bool> autoplayVideos,
      Value<int?> appBarColor,
      Value<bool> useBottomBar,
      Value<bool> showMorePlatformColorAccents,
      Value<bool> showPlatformColorTextAccents,
      Value<String?> redditClientId,
      Value<String?> redditRedirectUri,
      Value<bool> redditCopyOldRedditLinks,
      Value<int> diggPostsFetchDepth,
      Value<String?> userAgent,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<Platform?> homeCommunityPlatform,
      Value<String?> homeCommunityName,
      Value<bool> showCommentImages,
      Value<bool> autoplayVideos,
      Value<int?> appBarColor,
      Value<bool> useBottomBar,
      Value<bool> showMorePlatformColorAccents,
      Value<bool> showPlatformColorTextAccents,
      Value<String?> redditClientId,
      Value<String?> redditRedirectUri,
      Value<bool> redditCopyOldRedditLinks,
      Value<int> diggPostsFetchDepth,
      Value<String?> userAgent,
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

  ColumnFilters<int> get appBarColor => $composableBuilder(
    column: $table.appBarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useBottomBar => $composableBuilder(
    column: $table.useBottomBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showMorePlatformColorAccents => $composableBuilder(
    column: $table.showMorePlatformColorAccents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showPlatformColorTextAccents => $composableBuilder(
    column: $table.showPlatformColorTextAccents,
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

  ColumnFilters<bool> get redditCopyOldRedditLinks => $composableBuilder(
    column: $table.redditCopyOldRedditLinks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diggPostsFetchDepth => $composableBuilder(
    column: $table.diggPostsFetchDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
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

  ColumnOrderings<int> get appBarColor => $composableBuilder(
    column: $table.appBarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useBottomBar => $composableBuilder(
    column: $table.useBottomBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showMorePlatformColorAccents => $composableBuilder(
    column: $table.showMorePlatformColorAccents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showPlatformColorTextAccents => $composableBuilder(
    column: $table.showPlatformColorTextAccents,
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

  ColumnOrderings<bool> get redditCopyOldRedditLinks => $composableBuilder(
    column: $table.redditCopyOldRedditLinks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diggPostsFetchDepth => $composableBuilder(
    column: $table.diggPostsFetchDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAgent => $composableBuilder(
    column: $table.userAgent,
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

  GeneratedColumn<int> get appBarColor => $composableBuilder(
    column: $table.appBarColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useBottomBar => $composableBuilder(
    column: $table.useBottomBar,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showMorePlatformColorAccents => $composableBuilder(
    column: $table.showMorePlatformColorAccents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showPlatformColorTextAccents => $composableBuilder(
    column: $table.showPlatformColorTextAccents,
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

  GeneratedColumn<bool> get redditCopyOldRedditLinks => $composableBuilder(
    column: $table.redditCopyOldRedditLinks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diggPostsFetchDepth => $composableBuilder(
    column: $table.diggPostsFetchDepth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userAgent =>
      $composableBuilder(column: $table.userAgent, builder: (column) => column);
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
                Value<int?> appBarColor = const Value.absent(),
                Value<bool> useBottomBar = const Value.absent(),
                Value<bool> showMorePlatformColorAccents = const Value.absent(),
                Value<bool> showPlatformColorTextAccents = const Value.absent(),
                Value<String?> redditClientId = const Value.absent(),
                Value<String?> redditRedirectUri = const Value.absent(),
                Value<bool> redditCopyOldRedditLinks = const Value.absent(),
                Value<int> diggPostsFetchDepth = const Value.absent(),
                Value<String?> userAgent = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                homeCommunityPlatform: homeCommunityPlatform,
                homeCommunityName: homeCommunityName,
                showCommentImages: showCommentImages,
                autoplayVideos: autoplayVideos,
                appBarColor: appBarColor,
                useBottomBar: useBottomBar,
                showMorePlatformColorAccents: showMorePlatformColorAccents,
                showPlatformColorTextAccents: showPlatformColorTextAccents,
                redditClientId: redditClientId,
                redditRedirectUri: redditRedirectUri,
                redditCopyOldRedditLinks: redditCopyOldRedditLinks,
                diggPostsFetchDepth: diggPostsFetchDepth,
                userAgent: userAgent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Platform?> homeCommunityPlatform = const Value.absent(),
                Value<String?> homeCommunityName = const Value.absent(),
                Value<bool> showCommentImages = const Value.absent(),
                Value<bool> autoplayVideos = const Value.absent(),
                Value<int?> appBarColor = const Value.absent(),
                Value<bool> useBottomBar = const Value.absent(),
                Value<bool> showMorePlatformColorAccents = const Value.absent(),
                Value<bool> showPlatformColorTextAccents = const Value.absent(),
                Value<String?> redditClientId = const Value.absent(),
                Value<String?> redditRedirectUri = const Value.absent(),
                Value<bool> redditCopyOldRedditLinks = const Value.absent(),
                Value<int> diggPostsFetchDepth = const Value.absent(),
                Value<String?> userAgent = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                homeCommunityPlatform: homeCommunityPlatform,
                homeCommunityName: homeCommunityName,
                showCommentImages: showCommentImages,
                autoplayVideos: autoplayVideos,
                appBarColor: appBarColor,
                useBottomBar: useBottomBar,
                showMorePlatformColorAccents: showMorePlatformColorAccents,
                showPlatformColorTextAccents: showPlatformColorTextAccents,
                redditClientId: redditClientId,
                redditRedirectUri: redditRedirectUri,
                redditCopyOldRedditLinks: redditCopyOldRedditLinks,
                diggPostsFetchDepth: diggPostsFetchDepth,
                userAgent: userAgent,
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
typedef $$CommunitiesTableCreateCompanionBuilder =
    CommunitiesCompanion Function({
      required Platform platform,
      required String? name,
      Value<bool> isFavorite,
      Value<int> rowid,
    });
typedef $$CommunitiesTableUpdateCompanionBuilder =
    CommunitiesCompanion Function({
      Value<Platform> platform,
      Value<String?> name,
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
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommunitiesCompanion(
                platform: platform,
                name: name,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Platform platform,
                required String? name,
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommunitiesCompanion.insert(
                platform: platform,
                name: name,
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
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$CommunitiesTableTableManager get communities =>
      $$CommunitiesTableTableManager(_db, _db.communities);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db, _db.history);
}
