import 'package:drift/drift.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';

@UseRowClass(Community)
class Communities extends Table {

  TextColumn get platform => text().map(const EnumNameConverter<Platform>(Platform.values))();
  TextColumn get host => text()();
  TextColumn get name => text().map(const EmptyStringConverter())();
  TextColumn get id => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {platform, host, name};

}