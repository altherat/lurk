
import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/tables/active_users.dart';
import 'package:lurk/core/database/tables/communities.dart';
import 'package:lurk/core/database/tables/cookies.dart';
import 'package:lurk/core/database/tables/history.dart';
import 'package:lurk/core/database/tables/settings.dart';
import 'package:lurk/core/database/tables/user_communities.dart';
import 'package:lurk/core/database/tables/users.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/user.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

@DriftDatabase(tables: [ActiveUsers, Communities, Cookies, History, Settings, Users, UserCommunities])
class Database extends _$Database {

  static Database instance = Database._();

  Database._([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await batch((batch) {
          batch.insert(
            settings, 
            SettingsCompanion.insert(),
          );
          batch.insertAll(
            communities,
            F.appFlavor.defaultCommunities.map((community) {
              return CommunitiesCompanion.insert(
                platform: community.platformContext.platform,
                host: community.platformContext.host,
                name: community.name
              );
            })
          );
        });
      },
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationSupportDirectory();
      final file = io.File(p.join(dbFolder.path, 'db.sqlite'));
      if (io.Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }
      final cachebase = (await getTemporaryDirectory()).path;
      sqlite3.tempDirectory = cachebase;
      return NativeDatabase.createInBackground(file);
    });
  }

  Stream<Map<String, dynamic>> watchSettings(Iterable<String> keys) {
    return (select(settings)..limit(1))
      .watchSingle()
      .map((row) {
        final json = row.toJson();
        return {
          for (var key in keys) 
            key: json[key]
      };
    });
  }

  Future<List<Cookie>> getAllValidCookies() {
    final now = DateTime.now();
    return (select(cookies)
      ..where((cookie) => cookie.expirationTime.isNull() | cookie.expirationTime.isBiggerThanValue(now))
    ).get();
  }

  Future<void> saveCookies(Iterable<Cookie> cookieList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        cookies,
        cookieList.map((c) {
          return CookiesCompanion.insert(
            key: c.key,
            value: c.value,
            expirationTime: Value(c.expirationTime),
          );
        })
      );
    });
  }

  Future<void> deleteCookies(Iterable<String> keys) => (delete(cookies)..where((c) => c.key.isIn(keys))).go();

  Future<Setting> getAllSettings() => select(settings).getSingle();

  Future<int> updateSettings(SettingsCompanion companion) => (update(settings)..where((t) => t.id.equals(1))).write(companion);
  
  Future<List<LoggedInUser>> getAllUsers() {
    return (select(users)
      ..orderBy(([
        (u) => OrderingTerm(
          expression: u.platform.caseMatch(
            when: {
              for (var p in Platform.values)
                Constant(p.name): Constant(p.index),
            },
          ),
          mode: OrderingMode.asc,
        ),
      ]))
    ).get();
  }

  Future<void> saveUser(LoggedInUser user) {
    return into(users)
      .insertOnConflictUpdate(
        UsersCompanion.insert(
          platform: user.platformContext.platform,
          host: user.platformContext.host,
          hostIconUrl: Value(user.hostIconUrl),
          id: user.id,
          name: user.name,
          iconUrl: Value(user.iconUrl),
        ),
      );
  }

  Future<void> deleteUser(String id) => (delete(users)..where((u) => u.id.equals(id))).go();

  Future<List<ActiveUser>> getAllActiveUsers() => select(activeUsers).get();

  Future<void> saveActiveUser(Platform platform, String userId) {
    return into(activeUsers)
      .insertOnConflictUpdate(
        ActiveUsersCompanion.insert(
          platform: platform,
          userId: userId,
        ),
      );
  }

  Future<void> deleteActiveUser(Platform platform) {
    return (delete(activeUsers)
      ..where((t) => t.platform.equals(platform.name))
    ).go();
  }

  Future<List<Community>> getAllCommunities() {
    return (select(communities)
      ..orderBy([
        (c) => OrderingTerm(expression: c.isFavorite, mode: OrderingMode.desc),
        (c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc),
      ])
    ).get();
  }

  Future<int> saveCommunity(Community community) {
    return into(communities).insert(
      CommunitiesCompanion.insert(
        platform: community.platformContext.platform,
        host: community.platformContext.host,
        name: community.name,
        isFavorite: Value(community.isFavorite),
        id: Value(community.id),
      ),
      mode: InsertMode.insertOrReplace
    );
  }

  Future<void> saveAllCommunities(Iterable<Community> communities) {
    return batch((batch) {
      batch.insertAll(
        this.communities, 
        communities.map((community) => CommunitiesCompanion.insert(
          platform: community.platformContext.platform,
          host: community.platformContext.host,
          name: community.name,
          isFavorite: Value(community.isFavorite),
          id: Value(community.id),
        )).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> deleteCommunity(Community community) {
    return ( delete(communities)
      ..where((c) => 
        c.platform.equals(community.platformContext.platform.name) & 
        c.name.equals(community.name ?? '')
      )
    ).go();
  }

  Future<List<String>> getHistoryIds(HistoryType type) {
    return (select(history)
      ..where((t) => t.type.equalsValue(type))
    )
    .map((row) => row.itemId)
    .get();
  }
  
  Future<void> addHistory(String id, HistoryType type) {
    return into(history).insert(
      HistoryCompanion.insert(itemId: id, type: type),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> saveCommunitySubscription(Platform platform, String userId, String communityName) {
    return into(userCommunities).insert(
      UserCommunitiesCompanion.insert(
        platform: platform,
        userId: userId,
        communityName: communityName,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> saveAllCommunitySubscriptions(Platform platform, String userId, Iterable<String> communityNames) {
    return batch((batch) {
      batch.insertAll(
        userCommunities,
        communityNames.map((name) => UserCommunitiesCompanion.insert(
          platform: platform,
          userId: userId,
          communityName: name,
        )).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<void> deleteCommunitySubscription(Platform platform, String userId, String communityName) {
    return (
      delete(userCommunities)
        ..where((t) => 
          t.platform.equalsValue(platform) & 
          t.userId.equals(userId) & 
          t.communityName.equals(communityName)
        )
    ).go();
  }

  Future<List<String>> getSubscribedCommunityNames(Platform platform, String userId) {
    return (
      select(userCommunities)
        ..where((t) => t.platform.equalsValue(platform) & t.userId.equals(userId))
    ).map((row) => row.communityName).get();
  }

  Future<List<Community>> getSubscribedCommunities(Platform platform, String userId) {
    return (
      select(userCommunities)
        ..where((t) => t.platform.equalsValue(platform) & t.userId.equals(userId))
    ).join([
      innerJoin(communities, 
        communities.platform.equalsExp(userCommunities.platform) & 
        communities.name.equalsExp(userCommunities.communityName)
      )
    ]).map((row) => row.readTable(communities)).get();
  }

  Future<Map<(Platform, String), Set<String>>> getAllSubscribedCommunities() async {
    final rows = await select(userCommunities).get();
    final Map<(Platform, String), Set<String>> result = {};
    for (final row in rows) {
      result.putIfAbsent((row.platform, row.userId), () => {}).add(row.communityName);
    }
    return result;
  }

}