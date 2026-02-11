
import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/tables/communities.dart';
import 'package:lurk/core/database/tables/cookies.dart';
import 'package:lurk/core/database/tables/history.dart';
import 'package:lurk/core/database/tables/settings.dart';
import 'package:lurk/core/database/tables/users.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/user.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Cookies, Settings, Users, Communities, History])
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
            F.appFlavor.defaultCommunities.map((community) => CommunitiesCompanion.insert(platform: community.platform, name: community.name))
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

  Future<List<Cookie>> getAllValidCookies() {
    final now = DateTime.now();
    return (
      select(cookies)
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

  Future<Setting?> getAllSettings() => select(settings).getSingleOrNull();

  Future<int> updateSettings(SettingsCompanion companion) => (update(settings)..where((t) => t.id.equals(1))).write(companion);
  
  Future<List<LoggedInUser>> getAllLoggedInUsers() {
    return (
      select(users)
        ..orderBy([
          (u) => OrderingTerm(expression: u.name, mode: OrderingMode.asc),
        ])
    ).get();
  }

  Future<void> saveLoggedInUser(LoggedInUser user) {
    return into(users).insertOnConflictUpdate(
      UsersCompanion.insert(
        platform: user.platform,
        id: user.id,
        name: user.name,
        iconUrl: user.iconUrl,
        score: user.score,
        inboxCount: user.inboxCount,
      ),
    );
  }

  Future<void> deleteLoggedInUser(LoggedInUser user) {
    return (
      delete(users)
        ..where((u) => u.id.equals(user.id))
    )
    .go();
  }

  Future<List<Community>> getAllCommunities() {
    return (
      select(communities)
        ..orderBy([
          (c) => OrderingTerm(expression: c.isFavorite, mode: OrderingMode.desc),
          (c) => OrderingTerm(expression: c.name, mode: OrderingMode.asc),
        ])
    ).get();
  }

  Future<int> saveCommunity(Community community) {
    return into(communities).insert(
      CommunitiesCompanion.insert(
        platform: community.platform,
        name: community.name,
        isFavorite: Value(community.isFavorite),
      ),
      mode: InsertMode.insertOrReplace
    );
  }

  Future<void> saveAllCommunities(Iterable<Community> communities) {
    return batch((batch) {
      batch.insertAll(
        this.communities, 
        communities.map((community) => CommunitiesCompanion.insert(
          platform: community.platform,
          name: community.name,
          isFavorite: Value(community.isFavorite),
        )).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> deleteCommunity(Community community) {
    return (
      delete(communities)
        ..where((c) => 
          c.platform.equals(community.platform.name) & 
          c.name.equals(community.name ?? '')
        )
    )
    .go();
  }

  Future<List<String>> getHistoryIds(HistoryType type) {
    return (
      select(history)
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

}