
import 'package:drift/drift.dart';
import 'package:lurk/core/platforms.dart';

class UserCommunities extends Table {

  TextColumn get platform => text().map(const EnumNameConverter<Platform>(Platform.values))();
  TextColumn get userId => text()();
  TextColumn get communityName => text()();

  @override
  Set<Column> get primaryKey => {platform, userId, communityName};

}
