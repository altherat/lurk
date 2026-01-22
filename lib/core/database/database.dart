import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/database/tables/communities.dart';
import 'package:lurk/core/database/tables/history.dart';
import 'package:lurk/core/database/tables/settings.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/core/enums.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Settings, Communities, History])
class Database extends _$Database {

  static Database instance = Database._();

  Database._([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    final homeCommunity = F.appFlavor.defaultCommunities.first;
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await into(settings).insert(
          SettingsCompanion.insert(
            homeCommunityPlatform: homeCommunity.platform,
            homeCommunityName: Value(homeCommunity.name),
          ),
        );
        await batch((batch) {
          batch.insertAll(
            communities,
            F.appFlavor.defaultCommunities.map((community) => CommunitiesCompanion.insert(platform: community.platform, name: community.name))
          );
        });
      },
    );
  }

  static QueryExecutor _openConnection() {
    if (kDebugMode) {
      return LazyDatabase(() async {
        final dbFolder = await getApplicationSupportDirectory();
        final file = File(p.join(dbFolder.path, '${Constants.databaseName}.sqlite'));
        return NativeDatabase(file);
      });
    }
    return driftDatabase(
      name: Constants.databaseName,
      native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
    );
  }

  Future<Setting> getAllSettings() => select(settings).getSingle();

  Future<int> updateSettings(SettingsCompanion companion) => (update(settings)..where((t) => t.id.equals(1))).write(companion);
  
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
        platform: community.platform,
        name: community.name,
        isFavorite: Value(community.isFavorite),
      ),
      mode: InsertMode.insertOrReplace
    );
  }

  Future<void> deleteCommunity(Community community) {
    return (delete(communities)
      ..where((c) => 
        c.platform.equals(community.platform.name) & 
        c.name.equals(community.name ?? '')
      )
    )
    .go();
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

}