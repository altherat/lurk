import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';

import '../core/database/database.dart' as tbl;

class Settings {

  static late final SettingNotifier<Platform> homeCommunityPlatform;
  static late final SettingNotifier<String?> homeCommunityName;
  static late final SettingNotifier<bool> showCommentImages;
  static late final SettingNotifier<bool> autoplayVideos;
  static late final SettingNotifier<Color> appBarColor;
  static late final SettingNotifier<bool> useBottomBar;
  static late final SettingNotifier<bool> showPlatformColorAccents;
  static late final SettingNotifier<bool> showPlatformColorTextAccents;

  static late final SettingNotifier<bool> redditCopyOldRedditLinks;
  static late final SettingNotifier<String?> redditClientId;
  static late final SettingNotifier<String?> redditRedirectUri;
  
  static late final SettingNotifier<int> diggPostsFetchDepth;

  static late final SettingNotifier<String?> customUserAgent;

  static late final Setting<SearchType?> searchType;
  static late final Setting<Platform?> searchPlatform;

  static late final RelationalListSettingNotifier<Community> communities;

  static bool isInitialized = false;

  static Future<void> init() async {

    final db = Database.instance;
    final [dbSettings as tbl.Setting, dbCommunities as List<Community>] = await Future.wait([db.getAllSettings(), db.getAllCommunities()]);

    homeCommunityPlatform = SettingNotifier(dbSettings.homeCommunityPlatform, (value) => SettingsCompanion(homeCommunityPlatform: Value(value)), F.appFlavor.defaultCommunities.first.platform);
    homeCommunityName = SettingNotifier(dbSettings.homeCommunityName, (value) => SettingsCompanion(homeCommunityName: Value(value)), homeCommunityPlatform.value.communityHome);
    showCommentImages = SettingNotifier(dbSettings.showCommentImages, (value) => SettingsCompanion(showCommentImages: Value(value)), Constants.defaultShowCommentImages);
    autoplayVideos = SettingNotifier(dbSettings.autoplayVideos, (value) => SettingsCompanion(autoplayVideos: Value(value)), Constants.defaultAutoplayVideos);
    appBarColor = SettingNotifier(dbSettings.appBarColor != null ? Color(dbSettings.appBarColor!) : null, (value) => SettingsCompanion(appBarColor: Value(value.toARGB32())), Constants.defaultAppBarColor);
    useBottomBar = SettingNotifier(dbSettings.useBottomBar, (value) => SettingsCompanion(useBottomBar: Value(value)), Constants.defaultUseBottomBar);
    showPlatformColorAccents = SettingNotifier(dbSettings.showPlatformColorAccents, (value) => SettingsCompanion(showPlatformColorAccents: Value(value)), Constants.defaultShowPlatformColorAccents);
    showPlatformColorTextAccents = SettingNotifier(dbSettings.showPlatformColorTextAccents, (value) => SettingsCompanion(showPlatformColorTextAccents: Value(value)), Constants.defaultShowPlatformColorTextAccents);
    redditCopyOldRedditLinks = SettingNotifier(dbSettings.redditCopyOldRedditLinks, (value) => SettingsCompanion(redditCopyOldRedditLinks: Value(value)), Constants.defaultRedditCopyOldRedditLinks);
    redditClientId = SettingNotifier(dbSettings.redditClientId, (value) => SettingsCompanion(redditClientId: Value(value)));
    redditRedirectUri = SettingNotifier(dbSettings.redditRedirectUri, (value) => SettingsCompanion(redditRedirectUri: Value(value)));
    diggPostsFetchDepth = SettingNotifier(dbSettings.diggPostsFetchDepth, (value) => SettingsCompanion(diggPostsFetchDepth: Value(value)), Constants.defaultDiggPostsFetchDepth);
    customUserAgent = SettingNotifier(dbSettings.userAgent, (value) => SettingsCompanion(userAgent: Value(value)));
    searchType = Setting(dbSettings.searchType, (value) => SettingsCompanion(searchType: Value(value)));
    searchPlatform = Setting(dbSettings.searchPlatform, (value) => SettingsCompanion(searchPlatform: Value(value)));
    communities = RelationalListSettingNotifier<Community>(
      dbCommunities,
      save: db.saveCommunity,
      delete: db.deleteCommunity,
    );
    isInitialized = true;
  }

}

class Setting<T> {

  final SettingsCompanion Function(T) companionBuilder;
  T _value;
  T? _defaultValue;
  bool hasSavedValue;

  Setting(T? initialValue, this.companionBuilder, [T? defaultValue])
    : _value = initialValue ?? defaultValue as T, _defaultValue = defaultValue, hasSavedValue = initialValue != null;

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

  final SettingsCompanion Function(T) companionBuilder;
  T? _defaultValue;
  bool hasSavedValue;

  SettingNotifier(T? initialValue, this.companionBuilder, [T? defaultValue]) 
    : _defaultValue = defaultValue, hasSavedValue = initialValue != null, super(initialValue ?? defaultValue as T);

  @override
  set value(T newValue) {
    if (super.value == newValue) return;
    super.value = newValue ?? _defaultValue as T;
    Database.instance.updateSettings(companionBuilder(newValue));
    hasSavedValue = true;
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
  final Future<void> Function(T) save;
  final Future<void> Function(T) delete;

  RelationalListSettingNotifier(
    List<T> initialValue, {
    required this.save,
    required this.delete,
  }) : _value = List.unmodifiable(initialValue);

  @override
  List<T> get value => _value;

  Future<void> add(T item) async {
    if (_value.contains(item)) return;
    _value = List.unmodifiable([..._value, item]);
    notifyListeners();
    await save(item);
  }

  Future<void> remove(T item) async {
    if (!_value.contains(item)) return;
    _value = List.unmodifiable(_value.where((x) => x != item));
    notifyListeners();
    await delete(item);
  }

  Future<void> update(T item) async {
    final index = _value.indexOf(item);
    if (index != -1) {
      final newList = List<T>.from(_value);
      newList[index] = item;
      _value = List.unmodifiable(newList);
      notifyListeners();
      await save(item);
    }
  }

  void sort(int Function(T a, T b) compare) {
    final newList = List<T>.from(_value);
    newList.sort(compare);
    _value = List.unmodifiable(newList);
    notifyListeners();
  }

}