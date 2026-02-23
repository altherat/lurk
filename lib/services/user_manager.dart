import 'package:flutter/foundation.dart';
import 'package:lurk/core/database/database.dart' as db;
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/user.dart';

class UserManager {

  static late final db.Database _db;
  static late final ValueNotifier<List<LoggedInUser>> _loggedInUsersNotifier;
  static late final Map<Platform, String> _activeUserIds;
  static final Map<Platform, ValueNotifier<LoggedInUser?>> _activeUserNotifiers = {};
  static final Map<Platform, ValueNotifier<List<LoggedInUser>>> _loggedInUsersNotifiers = {};

  const UserManager();

  static Future<void> init(db.Database db) async {
    _db = db;
    _loggedInUsersNotifier = ValueNotifier(await db.getAllUsers());
    _activeUserIds = {
      for (final activeUser in await db.getAllActiveUsers())
        activeUser.platform: activeUser.userId
    };
  }

  static ValueListenable<List<LoggedInUser>> get loggedInUsers => _loggedInUsersNotifier;

  static ValueListenable<List<LoggedInUser>> getLoggedInUsers(Platform platform) => _loggedInUsersNotifiers[platform] ??= ValueNotifier(_loggedInUsersNotifier.value.where((user) => user.platformContext.platform == platform).toList());

  static ValueListenable<LoggedInUser?> getActiveUser(Platform platform) => _activeUserNotifiers[platform] ??= ValueNotifier(_loggedInUsersNotifier.value.firstWhereOrNull((user) => user.platformContext.platform == platform && user.id == _activeUserIds[platform]));

  static void setActiveUser(Platform platform, LoggedInUser? user) {
    _activeUserNotifiers[platform]?.value = user;
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
    setActiveUser(user.platformContext.platform, user);
    _loggedInUsersNotifier.value = loggedInUsers..add(user);
    _loggedInUsersNotifiers[user.platformContext.platform]?.value = loggedInUsers.where((u) => u.platformContext.platform == user.platformContext.platform).toList();
    _db.saveUser(user);
    Platform.destroySession(user.platformContext, null);
    return true;
  }

  static void removeLoggedInUser(LoggedInUser user) {
    final loggedInUsers = _loggedInUsersNotifier.value;
    _loggedInUsersNotifier.value = loggedInUsers..remove(user);
    final loggedInUsersForPlatform = loggedInUsers.where((u) => u.platformContext.platform == user.platformContext.platform);
    _loggedInUsersNotifiers[user.platformContext.platform]?.value = loggedInUsersForPlatform.toList();
    if (_activeUserIds[user.platformContext.platform] == user.id) {
      setActiveUser(user.platformContext.platform, loggedInUsersForPlatform.firstOrNull);
    }
    _db.deleteUser(user.id);
    Platform.destroySession(user.platformContext, user);
  }

}