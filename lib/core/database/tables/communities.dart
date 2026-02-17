import 'package:drift/drift.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';

@UseRowClass(Community)
class Communities extends Table {

  TextColumn get platform => text().map(const EnumNameConverter<Platform>(Platform.values))();
  TextColumn get name => text().map(const EmptyStringConverter())();
  TextColumn get id => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {platform, name};

}

class EmptyStringConverter extends TypeConverter<String?, String> {

  const EmptyStringConverter();

  @override
  String? fromSql(String from) => from.isEmpty ? null : from;

  @override
  String toSql(String? to)=> to ?? '';
  
}