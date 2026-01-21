import 'dart:ui';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/models/community.dart';

class Settings {

  static late final SettingNotifier<Community> homeCommunity;
  static late final SettingNotifier<bool> showCommentImages;
  static late final SettingNotifier<bool> autoplayVideos;
  static late final SettingNotifier<Color?> appBarColor;
  static late final SettingNotifier<bool> useBottomBar;
  static late final SettingNotifier<bool> showPlatformColorAccents;
  static late final SettingNotifier<String?> clientId;
  static late final SettingNotifier<String?> redirectUri;
  static late final SettingNotifier<bool> copyOldRedditLinks;
  static late final SettingNotifier<String?> userAgent;
  static late final RelationalListSettingNotifier<Community> communities;

  static Future<void> init() async {
    
    final db = Database.instance;
    final [dbSettings as Setting, dbCommunities as List<Community>] = await Future.wait([db.getAllSettings(), db.getAllCommunities()]);

    homeCommunity = SettingNotifier(
      Community(
        platform: dbSettings.homeCommunityPlatform,
        name: dbSettings.homeCommunityName
      ),
      (value) {
        return SettingsCompanion(
          homeCommunityPlatform: Value(value.platform),
          homeCommunityName: Value(value.name),
        );
      },
    );
    showCommentImages = SettingNotifier(dbSettings.showCommentImages, (value) => SettingsCompanion(showCommentImages: Value(value)), Constants.defaultShowCommentImages);
    autoplayVideos = SettingNotifier(dbSettings.autoplayVideos, (value) => SettingsCompanion(autoplayVideos: Value(value)), Constants.defaultAutoplayVideos);
    appBarColor = SettingNotifier(dbSettings.appBarColor != null ? Color(dbSettings.appBarColor!) : null, (value) => SettingsCompanion(appBarColor: Value(value?.toARGB32())), Constants.defaultAppBarColor);
    useBottomBar = SettingNotifier(dbSettings.useBottomBar, (value) => SettingsCompanion(useBottomBar: Value(value)), Constants.defaultUseBottomBar);
    showPlatformColorAccents = SettingNotifier(dbSettings.showPlatformColorAccents, (value) => SettingsCompanion(showPlatformColorAccents: Value(value)), Constants.defaultShowPlatformColorAccents);
    clientId = SettingNotifier(dbSettings.clientId, (value) => SettingsCompanion(clientId: Value(value)));
    redirectUri = SettingNotifier(dbSettings.redirectUri, (value) => SettingsCompanion(redirectUri: Value(value)));
    copyOldRedditLinks = SettingNotifier(dbSettings.copyOldRedditLinks, (value) => SettingsCompanion(copyOldRedditLinks: Value(value)), Constants.defaultCopyOldRedditLinks);
    userAgent = SettingNotifier(dbSettings.userAgent, (value) => SettingsCompanion(userAgent: Value(value)), Constants.defaultUserAgent);
    communities = RelationalListSettingNotifier<Community>(
      dbCommunities,
      save: db.saveCommunity,
      delete: db.deleteCommunity,
    );
  }

}

class SettingNotifier<T> extends ValueNotifier<T> {

  final SettingsCompanion Function(T) companionBuilder;
  final T? defaultValue;
  final bool hasSavedValue;

  SettingNotifier(T initialValue, this.companionBuilder, [this.defaultValue]) : hasSavedValue = initialValue != null, super(initialValue ?? defaultValue as T);

  @override
  set value(T newValue) {
    if (super.value == newValue) return;
    super.value = newValue ?? defaultValue as T;
    Database.instance.updateSettings(companionBuilder(newValue));
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