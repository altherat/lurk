import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database_list_notifier.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/user.dart';

import '../core/database/database.dart' as tbl;

class Settings {

  static late final DatabaseListNotifier<LoggedInUser> loggedInUsers;
  static late final SettingNotifier<LoggedInUser?> activeUser;

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

  static void Function(Platform platform)? onSessionsInvalidated;

  static Future<void> init() async {
    
    final db = Database.instance;
    final [dbSettings as tbl.Setting, dbLoggedInUseres as List<LoggedInUser>] = await Future.wait([db.getAllSettings(), db.getAllLoggedInUsers()]);
    
    loggedInUsers = DatabaseListNotifier(
      dbLoggedInUseres,
      save: db.saveLoggedInUser,
      delete: db.deleteLoggedInUser
    );
    
    final activeUserId = dbSettings.activeUserId;
    activeUser = SettingNotifier(
      initialValue: activeUserId != null ? loggedInUsers.value.firstWhere((user) => user.id == activeUserId) : null,
      companionBuilder: (user) => SettingsCompanion(activeUserId: Value(user?.id)),
    );

    homeCommunityPlatform = SettingNotifier(
      initialValue: dbSettings.homeCommunityPlatform,
      companionBuilder: (value) => SettingsCompanion(homeCommunityPlatform: Value(value)),
      defaultValue: F.appFlavor.defaultCommunities.first.platform,
    );

    homeCommunityHost = SettingNotifier(
      initialValue: dbSettings.homeCommunityHost,
      companionBuilder: (value) => SettingsCompanion(homeCommunityHost: Value(value)),
      defaultValue: F.appFlavor.defaultCommunities.first.host,
    );

    homeCommunityName = SettingNotifier(
      initialValue: dbSettings.homeCommunityName,
      companionBuilder: (value) => SettingsCompanion(homeCommunityName: Value(value)),
      defaultValue: F.appFlavor.defaultCommunities.first.name
    );

    showCommentImages = SettingNotifier(
      initialValue: dbSettings.showCommentImages,
      companionBuilder: (value) => SettingsCompanion(showCommentImages: Value(value)),
      defaultValue: Constants.defaultShowCommentImages,
    );

    autoplayVideos = SettingNotifier(
      initialValue: dbSettings.autoplayVideos,
      companionBuilder: (value) => SettingsCompanion(autoplayVideos: Value(value)),
      defaultValue: Constants.defaultAutoplayVideos,
    );

    swipePostsToVote = SettingNotifier(
      initialValue: dbSettings.swipePostsToVote,
      companionBuilder: (value) => SettingsCompanion(swipePostsToVote: Value(value)),
      defaultValue: Constants.defaultSwipePostsToVote,
    );

    swipeCommentsToVote = SettingNotifier(
      initialValue: dbSettings.swipeCommentsToVote,
      companionBuilder: (value) => SettingsCompanion(swipeCommentsToVote: Value(value)),
      defaultValue: Constants.defaultSwipeCommentsToVote,
    );

    showCommentVotingEdges = SettingNotifier(
      initialValue: dbSettings.showCommentVotingEdges,
      companionBuilder: (value) => SettingsCompanion(showCommentVotingEdges: Value(value)),
      defaultValue: Constants.defaultShowCommentVotingEdges,
    );

    commentTapBehavior = SettingNotifier(
      initialValue: dbSettings.commentTapBehavior,
      companionBuilder: (value) => SettingsCompanion(commentTapBehavior: Value(value)),
      defaultValue: Constants.defaultCommentTapBehavior
    );

    commentLongPressBehavior = SettingNotifier(
      initialValue: dbSettings.commentLongPressBehavior,
      companionBuilder: (value) => SettingsCompanion(commentLongPressBehavior: Value(value)),
      defaultValue: Constants.defaultCommentLongPressBehavior
    );

    appBarColor = SettingNotifier(
      initialValue: dbSettings.appBarColor != null ? Color(dbSettings.appBarColor!) : null,
      nullableCompanionBuilder: (value) => SettingsCompanion(appBarColor: Value(value?.toARGB32())),
      defaultValue: Constants.defaultAppBarColor,
    );

    useBottomBar = SettingNotifier(
      initialValue: dbSettings.useBottomBar,
      companionBuilder: (value) => SettingsCompanion(useBottomBar: Value(value)),
      defaultValue: Constants.defaultUseBottomBar,
    );

    reverseCommunityList = SettingNotifier(
      initialValue: dbSettings.reverseCommunityList,
      companionBuilder: (value) => SettingsCompanion(reverseCommunityList: Value(value)),
      defaultValue: Constants.defaultReverseCommunityList,
    );

    backOnHomeScreenShowCommunityList = SettingNotifier(
      initialValue: dbSettings.backOnHomeScreenShowCommunityList,
      companionBuilder: (value) => SettingsCompanion(backOnHomeScreenShowCommunityList: Value(value)),
      defaultValue: Constants.defaultBackOnHomeScreenShowCommunityList,
    );

    showPlatformColorAccents = SettingNotifier(
      initialValue: dbSettings.showPlatformColorAccents,
      companionBuilder: (value) => SettingsCompanion(showPlatformColorAccents: Value(value)),
      defaultValue: Constants.defaultShowPlatformColorAccents,
    );

    showPlatformColorTextAccents = SettingNotifier(
      initialValue: dbSettings.showPlatformColorTextAccents,
      companionBuilder: (value) => SettingsCompanion(showPlatformColorTextAccents: Value(value)),
      defaultValue: Constants.defaultShowPlatformColorTextAccents,
    );

    redditCopyOldRedditLinks = SettingNotifier(
      initialValue: dbSettings.redditCopyOldRedditLinks,
      companionBuilder: (value) => SettingsCompanion(redditCopyOldRedditLinks: Value(value)),
      defaultValue: Constants.defaultRedditCopyOldRedditLinks,
    );

    redditClientId = SettingNotifier(
      initialValue: dbSettings.redditClientId,
      companionBuilder: (value) => SettingsCompanion(redditClientId: Value(value)),
      onChanged: (value) {
        if (value == null) {
          loggedInUsers.clear();
          activeUser.value = null;
          onSessionsInvalidated?.call(Platform.reddit);
        }
      }
    );

    redditRedirectUri = SettingNotifier(
      initialValue: dbSettings.redditRedirectUri,
      companionBuilder: (value) => SettingsCompanion(redditRedirectUri: Value(value)),
    );

    redditUserAgent = SettingNotifier(
      initialValue: dbSettings.redditUserAgent,
      companionBuilder: (value) => SettingsCompanion(redditUserAgent: Value(value)),
    );

    redditDeviceId = Setting(
      initialValue: dbSettings.redditDeviceId,
      companionBuilder: (value) => SettingsCompanion(redditDeviceId: Value(value)),
    );

    diggPostsFetchDepth = SettingNotifier(
      initialValue: dbSettings.diggPostsFetchDepth,
      companionBuilder: (value) => SettingsCompanion(diggPostsFetchDepth: Value(value)),
      defaultValue: Constants.defaultDiggPostsFetchDepth,
    );

    diggUserAgent = SettingNotifier(
      initialValue: dbSettings.diggUserAgent,
      companionBuilder: (value) => SettingsCompanion(diggUserAgent: Value(value)),
    );

    lemmyUserAgent = SettingNotifier(
      initialValue: dbSettings.lemmyUserAgent,
      companionBuilder: (value) => SettingsCompanion(lemmyUserAgent: Value(value)),
    );

    searchType = Setting(
      initialValue: dbSettings.searchType,
      companionBuilder: (value) => SettingsCompanion(searchType: Value(value)),
    );

  } 

}

class Setting<T> {

  final SettingsCompanion Function(T) companionBuilder;
  T _value;
  T? _defaultValue;
  bool hasSavedValue;

  Setting({
    required T? initialValue,
    required this.companionBuilder,
    T? defaultValue,
  })  : _value = initialValue ?? defaultValue as T,
        _defaultValue = defaultValue,
        hasSavedValue = initialValue != null;

  T get value => _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue ?? _defaultValue as T;
    Database.instance.updateSettings(companionBuilder(newValue));
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

  final SettingsCompanion Function(T value)? companionBuilder;
  final SettingsCompanion Function(T? value)? nullableCompanionBuilder;
  T? _defaultValue;
  bool hasSavedValue;
  void Function(T value)? onChanged;

  SettingNotifier({
    required T? initialValue,
    this.companionBuilder,
    this.nullableCompanionBuilder,
    T? defaultValue,
    this.onChanged
  })  : assert(companionBuilder != null || nullableCompanionBuilder != null),
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
    Database.instance.updateSettings(companion);
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