import 'package:drift/drift.dart';
import 'package:lurk/core/platforms.dart';

class ActiveUsers extends Table {
  
  TextColumn get platform => text().map(const EnumNameConverter<Platform>(Platform.values))();
  TextColumn get userId => text()();

  @override
  Set<Column> get primaryKey => {platform};
  
}