import 'package:flutter/foundation.dart';
import 'package:lurk/core/database/database.dart' as db;
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/user.dart';

class UserManager {

  static late final db.Database _db;
  static late final ValueNotifier<List<LoggedInUser>> _loggedInUsersNotifier;
  static late final Map<Platform, String> _activeUserIds;
  static final Map<(Platform, String?), ValueNotifier<LoggedInUser?>> _activeUserNotifiers = {};
  static final Map<Platform, ValueNotifier<List<LoggedInUser>>> _loggedInUsersNotifiers = {};

  const UserManager();

  static void init(db.Database db, List<LoggedInUser> users, List<ActiveUser> activeUsers) {
    _db = db;
    _loggedInUsersNotifier = ValueNotifier(users);
    _activeUserIds = {
      for (final activeUser in activeUsers)
        activeUser.platform: activeUser.userId
    };
  }

  static LoggedInUser? getActiveUser(Platform platform, [String? host]) {
    final activeUserId = _activeUserIds[platform];
    if (activeUserId != null) {
      final platformUsers = _loggedInUsersNotifier.value.where((user) => user.platform == platform);
      final activeUser = platformUsers.firstWhere((user) => user.id == activeUserId);
      if (host != null && activeUser.host != host) {
        return platformUsers.firstWhereOrNull((user) => user.host == host);
      }
      return activeUser;
    }
    return null;
  }

  static bool hasActiveUser(Platform platform) => _activeUserIds.containsKey(platform);

  static ValueListenable<List<LoggedInUser>> get loggedInUsersListenable => _loggedInUsersNotifier;

  static ValueListenable<List<LoggedInUser>> getLoggedInUsersListenable(Platform platform) => _loggedInUsersNotifiers[platform] ??= ValueNotifier(_loggedInUsersNotifier.value.where((user) => user.platform == platform).toList());

  static ValueListenable<LoggedInUser?> getActiveUserListenable(Platform platform, [String? host]) => _activeUserNotifiers[(platform, host)] ??= ValueNotifier(getActiveUser(platform, host));

  static void setActiveUser(Platform platform, LoggedInUser? user) {
    for (final entry in _activeUserNotifiers.entries) {
      if (entry.key.$1 == platform) {
        entry.value.value = entry.key.$2 == null || user?.host == entry.key.$2 ? user : _loggedInUsersNotifier.value.firstWhereOrNull((user) => user.platform == platform && user.host == entry.key.$2);
      }
    }
    if (user == null) {
      _activeUserIds.remove(platform);
      _db.deleteActiveUser(platform);
    }
    else {
      _activeUserIds[platform] = user.id;
      _db.saveActiveUser(platform, user.id);
    }
  }

  static bool addLoggedInUser(LoggedInUser user) {
    final loggedInUsers = _loggedInUsersNotifier.value;
    if (loggedInUsers.any((u) => u.id == user.id)) {
      return false;
    }
    setActiveUser(user.platform, user);
    _loggedInUsersNotifier.value = loggedInUsers..add(user);
    _loggedInUsersNotifiers[user.platform]?.value = loggedInUsers.where((u) => u.platform == user.platform).toList();
    _db.saveUser(user);
    Platform.destroySession(user.platform, user.host, null);
    return true;
  }

  static void removeLoggedInUser(LoggedInUser user) {
    final loggedInUsers = _loggedInUsersNotifier.value;
    _loggedInUsersNotifier.value = loggedInUsers..remove(user);
    final loggedInUsersForPlatform = loggedInUsers.where((u) => u.platform == user.platform);
    _loggedInUsersNotifiers[user.platform]?.value = loggedInUsersForPlatform.toList();
    if (_activeUserIds[user.platform] == user.id) {
      setActiveUser(user.platform, loggedInUsersForPlatform.firstOrNull);
    }
    _db.deleteUser(user.id);
    Platform.destroySession(user.platform, user.host, user);
  }

}