import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/user.dart';

import '../core/database/database.dart' as tbl;

class Settings {

  static late final RelationalListSettingNotifier<LoggedInUser> loggedInUsers;
  static late final SettingNotifier<LoggedInUser?> activeUser;

  static late final SettingNotifier<Platform> homeCommunityPlatform;
  static late final SettingNotifier<String?> homeCommunityName;
  static late final SettingNotifier<bool> showCommentImages;
  static late final SettingNotifier<bool> autoplayVideos;
  static late final SettingNotifier<bool> swipeCommentsToVote;
  static late final SettingNotifier<bool> showCommentVotingEdges;
  static late final SettingNotifier<CommentBehavior> commentTapBehavior;
  static late final SettingNotifier<CommentBehavior> commentLongPressBehavior;
  static late final SettingNotifier<Color> appBarColor;
  static late final SettingNotifier<bool> useBottomBar;
  static late final SettingNotifier<bool> reverseCommunityList;
  static late final SettingNotifier<bool> showPlatformColorAccents;
  static late final SettingNotifier<bool> showPlatformColorTextAccents;

  static late final SettingNotifier<bool> redditCopyOldRedditLinks;
  static late final SettingNotifier<String?> redditClientId;
  static late final SettingNotifier<String?> redditRedirectUri;
  static late final SettingNotifier<String?> redditUserAgent;
  static late final Setting<String?> redditDeviceId;
  
  static late final SettingNotifier<int> diggPostsFetchDepth;
  static late final SettingNotifier<String?> diggUserAgent;

  static late final Setting<SearchType?> searchType;

  static late final RelationalListSettingNotifier<Community> communities;

  static Future<void> init() async {

    final db = Database.instance;
    final [dbSettings as tbl.Setting, dbLoggedInUseres as List<LoggedInUser>, dbCommunities as List<Community>] = await Future.wait([db.getAllSettings(), db.getAllLoggedInUsers(), db.getAllCommunities()]);
    
    loggedInUsers = RelationalListSettingNotifier(
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

    homeCommunityName = SettingNotifier(
      initialValue: dbSettings.homeCommunityName,
      companionBuilder: (value) => SettingsCompanion(homeCommunityName: Value(value)),
      defaultValue: activeUserId == null ? homeCommunityPlatform.value.homeCommunityName : null,
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

    searchType = Setting(
      initialValue: dbSettings.searchType,
      companionBuilder: (value) => SettingsCompanion(searchType: Value(value)),
    );

    communities = RelationalListSettingNotifier<Community>(
      dbCommunities,
      save: db.saveCommunity,
      saveAll: db.saveAllCommunities,
      delete: db.deleteCommunity,
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

  SettingNotifier({
    required T? initialValue,
    this.companionBuilder,
    this.nullableCompanionBuilder,
    T? defaultValue,
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
  }
  
  T? get defaultValue => _defaultValue;

  set defaultValue(T? newValue) {
    _defaultValue = newValue;
    if (!hasSavedValue) {
      super.value = newValue as T;
    }
  }
  
}

class RelationalListSettingNotifier<T> extends ChangeNotifier implements ValueListenable<List<T>> {

  List<T> _value;
  final Future<void> Function(T item) _save;
  final Future<void> Function(Iterable<T> items)? _saveAll;
  final Future<void> Function(T item) _delete;

  RelationalListSettingNotifier(
    List<T> initialValue, {
    required Future<void> Function(T) save,
    Future<void> Function(Iterable<T> items)? saveAll,
    required Future<void> Function(T) delete,
  }) :  _value = List.unmodifiable(initialValue),
        _save = save,
        _saveAll = saveAll,
        _delete = delete;

  @override
  List<T> get value => _value;

  Future<void> add(T item) async {
    if (_value.contains(item)) return;
    _value = List.unmodifiable([..._value, item]);
    notifyListeners();
    await _save(item);
  }

  Future<void> addAll(Iterable<T> items) async {
    final newItems = items.where((item) => !_value.contains(item)).toList();
    if (newItems.isEmpty) return;
    _value = List.unmodifiable([..._value, ...newItems]);
    notifyListeners();
    await _saveAll?.call(newItems);
  }

  Future<void> remove(T item) async {
    if (!_value.contains(item)) return;
    _value = List.unmodifiable(_value.where((x) => x != item));
    notifyListeners();
    await _delete(item);
  }

  Future<void> update(T item) async {
    final index = _value.indexOf(item);
    if (index != -1) {
      final newList = List<T>.from(_value);
      newList[index] = item;
      _value = List.unmodifiable(newList);
      notifyListeners();
      await _save(item);
    }
  }

  void sort(int Function(T a, T b) compare) {
    final newList = List<T>.from(_value);
    newList.sort(compare);
    _value = List.unmodifiable(newList);
    notifyListeners();
  }

}