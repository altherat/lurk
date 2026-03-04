import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database/database.dart' as db;
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/flavors.dart';

class Settings {

  static late final SettingNotifier<Platform> homeCommunityPlatform;
  static late final SettingNotifier<String> homeCommunityHost;
  static late final SettingNotifier<String?> homeCommunityName;
  static late final SettingNotifier<bool> showCommentImages;
  static late final SettingNotifier<bool> autoplayVideos;
  static late final SettingNotifier<bool> swipePostsToVote;
  static late final SettingNotifier<bool> swipeCommentsToVote;
  static late final SettingNotifier<bool> showCommentVotingEdges;
  static late final SettingNotifier<CommentBehavior> commentTapBehavior;
  static late final SettingNotifier<CommentBehavior> commentLongPressBehavior;
  static late final SettingNotifier<Color> appBarColor;
  static late final SettingNotifier<bool> useBottomBar;
  static late final SettingNotifier<bool> reverseCommunityList;
  static late final SettingNotifier<bool> backOnHomeScreenShowCommunityList;
  static late final SettingNotifier<bool> showPlatformColorAccents;
  static late final SettingNotifier<bool> showPlatformColorTextAccents;

  static late final SettingNotifier<bool> redditCopyOldRedditLinks;
  static late final SettingNotifier<String?> redditClientId;
  static late final SettingNotifier<String?> redditRedirectUri;
  static late final SettingNotifier<String?> redditUserAgent;
  static late final Setting<String?> redditDeviceId;
  
  static late final SettingNotifier<int> diggPostsFetchDepth;
  static late final SettingNotifier<String?> diggUserAgent;

  static late final SettingNotifier<String?> lemmyUserAgent;

  static late final Setting<SearchType?> searchType;

  static void init(Database db, db.Setting dbSettings, List<ActiveUser> activeUsers) {

    homeCommunityPlatform = SettingNotifier(
      db: db,
      initialValue: dbSettings.homeCommunityPlatform,
      companionBuilder: (value) => SettingsCompanion(homeCommunityPlatform: Value(value)),
      defaultValue: F.appFlavor.defaultCommunities.first.platform,
    );

    homeCommunityHost = SettingNotifier(
      db: db,
      initialValue: dbSettings.homeCommunityHost,
      companionBuilder: (value) => SettingsCompanion(homeCommunityHost: Value(value)),
      defaultValue: F.appFlavor.defaultCommunities.first.host,
    );

    homeCommunityName = SettingNotifier(
      db: db,
      initialValue: dbSettings.homeCommunityName,
      companionBuilder: (value) => SettingsCompanion(homeCommunityName: Value(value)),
      defaultValue: activeUsers.any((user) => user.platform == homeCommunityPlatform.value) ? null : F.appFlavor.defaultCommunities.first.name
    );

    showCommentImages = SettingNotifier(
      db: db,
      initialValue: dbSettings.showCommentImages,
      companionBuilder: (value) => SettingsCompanion(showCommentImages: Value(value)),
      defaultValue: Constants.defaultShowCommentImages,
    );

    autoplayVideos = SettingNotifier(
      db: db,
      initialValue: dbSettings.autoplayVideos,
      companionBuilder: (value) => SettingsCompanion(autoplayVideos: Value(value)),
      defaultValue: Constants.defaultAutoplayVideos,
    );

    swipePostsToVote = SettingNotifier(
      db: db,
      initialValue: dbSettings.swipePostsToVote,
      companionBuilder: (value) => SettingsCompanion(swipePostsToVote: Value(value)),
      defaultValue: Constants.defaultSwipePostsToVote,
    );

    swipeCommentsToVote = SettingNotifier(
      db: db,
      initialValue: dbSettings.swipeCommentsToVote,
      companionBuilder: (value) => SettingsCompanion(swipeCommentsToVote: Value(value)),
      defaultValue: Constants.defaultSwipeCommentsToVote,
    );

    showCommentVotingEdges = SettingNotifier(
      db: db,
      initialValue: dbSettings.showCommentVotingEdges,
      companionBuilder: (value) => SettingsCompanion(showCommentVotingEdges: Value(value)),
      defaultValue: Constants.defaultShowCommentVotingEdges,
    );

    commentTapBehavior = SettingNotifier(
      db: db,
      initialValue: dbSettings.commentTapBehavior,
      companionBuilder: (value) => SettingsCompanion(commentTapBehavior: Value(value)),
      defaultValue: Constants.defaultCommentTapBehavior
    );

    commentLongPressBehavior = SettingNotifier(
      db: db,
      initialValue: dbSettings.commentLongPressBehavior,
      companionBuilder: (value) => SettingsCompanion(commentLongPressBehavior: Value(value)),
      defaultValue: Constants.defaultCommentLongPressBehavior
    );

    appBarColor = SettingNotifier(
      db: db,
      initialValue: dbSettings.appBarColor != null ? Color(dbSettings.appBarColor!) : null,
      nullableCompanionBuilder: (value) => SettingsCompanion(appBarColor: Value(value?.toARGB32())),
      defaultValue: Constants.defaultAppBarColor,
    );

    useBottomBar = SettingNotifier(
      db: db,
      initialValue: dbSettings.useBottomBar,
      companionBuilder: (value) => SettingsCompanion(useBottomBar: Value(value)),
      defaultValue: Constants.defaultUseBottomBar,
    );

    reverseCommunityList = SettingNotifier(
      db: db,
      initialValue: dbSettings.reverseCommunityList,
      companionBuilder: (value) => SettingsCompanion(reverseCommunityList: Value(value)),
      defaultValue: Constants.defaultReverseCommunityList,
    );

    backOnHomeScreenShowCommunityList = SettingNotifier(
      db: db,
      initialValue: dbSettings.backOnHomeScreenShowCommunityList,
      companionBuilder: (value) => SettingsCompanion(backOnHomeScreenShowCommunityList: Value(value)),
      defaultValue: Constants.defaultBackOnHomeScreenShowCommunityList,
    );

    showPlatformColorAccents = SettingNotifier(
      db: db,
      initialValue: dbSettings.showPlatformColorAccents,
      companionBuilder: (value) => SettingsCompanion(showPlatformColorAccents: Value(value)),
      defaultValue: Constants.defaultShowPlatformColorAccents,
    );

    showPlatformColorTextAccents = SettingNotifier(
      db: db,
      initialValue: dbSettings.showPlatformColorTextAccents,
      companionBuilder: (value) => SettingsCompanion(showPlatformColorTextAccents: Value(value)),
      defaultValue: Constants.defaultShowPlatformColorTextAccents,
    );

    redditCopyOldRedditLinks = SettingNotifier(
      db: db,
      initialValue: dbSettings.redditCopyOldRedditLinks,
      companionBuilder: (value) => SettingsCompanion(redditCopyOldRedditLinks: Value(value)),
      defaultValue: Constants.defaultRedditCopyOldRedditLinks,
    );

    redditClientId = SettingNotifier(
      db: db,
      initialValue: dbSettings.redditClientId,
      companionBuilder: (value) => SettingsCompanion(redditClientId: Value(value)),
      onChanged: (value) => Platform.destroyPlatformSessions(Platform.reddit),
    );

    redditRedirectUri = SettingNotifier(
      db: db,
      initialValue: dbSettings.redditRedirectUri,
      companionBuilder: (value) => SettingsCompanion(redditRedirectUri: Value(value)),
    );

    redditUserAgent = SettingNotifier(
      db: db,
      initialValue: dbSettings.redditUserAgent,
      companionBuilder: (value) => SettingsCompanion(redditUserAgent: Value(value)),
    );

    redditDeviceId = Setting(
      db: db,
      initialValue: dbSettings.redditDeviceId,
      companionBuilder: (value) => SettingsCompanion(redditDeviceId: Value(value)),
    );

    diggPostsFetchDepth = SettingNotifier(
      db: db,
      initialValue: dbSettings.diggPostsFetchDepth,
      companionBuilder: (value) => SettingsCompanion(diggPostsFetchDepth: Value(value)),
      defaultValue: Constants.defaultDiggPostsFetchDepth,
    );

    diggUserAgent = SettingNotifier(
      db: db,
      initialValue: dbSettings.diggUserAgent,
      companionBuilder: (value) => SettingsCompanion(diggUserAgent: Value(value)),
    );

    lemmyUserAgent = SettingNotifier(
      db: db,
      initialValue: dbSettings.lemmyUserAgent,
      companionBuilder: (value) => SettingsCompanion(lemmyUserAgent: Value(value)),
    );

    searchType = Setting(
      db: db,
      initialValue: dbSettings.searchType,
      companionBuilder: (value) => SettingsCompanion(searchType: Value(value)),
    );

  }

}

class Setting<T> {

  final Database _db;
  final SettingsCompanion Function(T) companionBuilder;
  T _value;
  T? _defaultValue;
  bool hasSavedValue;

  Setting({
    required Database db,
    required T? initialValue,
    required this.companionBuilder,
    T? defaultValue,
  })  : _db = db,
        _value = initialValue ?? defaultValue as T,
        _defaultValue = defaultValue,
        hasSavedValue = initialValue != null;

  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue ?? _defaultValue as T;
    _db.updateSettings(companionBuilder(newValue));
    hasSavedValue = true;
  }

  T? get defaultValue => _defaultValue;

  set defaultValue(T? newValue) {
    _defaultValue = newValue;
    if (!hasSavedValue) {
      value = newValue as T;
    }
  }

}

class SettingNotifier<T> extends ValueNotifier<T> {

  final Database _db;
  final SettingsCompanion Function(T value)? companionBuilder;
  final SettingsCompanion Function(T? value)? nullableCompanionBuilder;
  T? _defaultValue;
  bool hasSavedValue;
  void Function(T value)? onChanged;

  SettingNotifier({
    required Database db,
    required T? initialValue,
    this.companionBuilder,
    this.nullableCompanionBuilder,
    T? defaultValue,
    this.onChanged
  })  : assert(companionBuilder != null || nullableCompanionBuilder != null),
        _db = db,
        _defaultValue = defaultValue,
        hasSavedValue = initialValue != null,
        super(initialValue ?? defaultValue as T);

  @override
  set value(T? newValue) {
    final T finalValue = newValue ?? _defaultValue as T;
    if (super.value == finalValue && hasSavedValue == (newValue != null)) return;
    final SettingsCompanion companion;
    if (newValue == null) {
      hasSavedValue = false;
      companion = nullableCompanionBuilder?.call(null) ?? companionBuilder!(newValue as T);
    }
    else {
      hasSavedValue = true;
      companion = companionBuilder?.call(newValue) ?? nullableCompanionBuilder!(newValue);
    }
    super.value = finalValue;
    _db.updateSettings(companion);
    onChanged?.call(finalValue);
  }
  
  T? get defaultValue => _defaultValue;

  set defaultValue(T? newValue) {
    _defaultValue = newValue;
    if (!hasSavedValue) {
      super.value = newValue as T;
    }
  }
  
}