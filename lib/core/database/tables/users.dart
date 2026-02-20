import 'package:drift/drift.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/user.dart';

@UseRowClass(LoggedInUser)
class Users extends Table {

  TextColumn get platform => text().map(const EnumNameConverter<Platform>(Platform.values))();
  TextColumn get host => text()();
  TextColumn get hostIconUrl => text().nullable()();
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get iconUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {platform, host, id};

}
