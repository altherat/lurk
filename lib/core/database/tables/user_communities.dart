
import 'package:drift/drift.dart';
import 'package:lurk/core/platforms.dart';

class UserCommunities extends Table {

  TextColumn get platform => text().map(const EnumNameConverter<Platform>(Platform.values))();
  TextColumn get host => text()();
  TextColumn get userId => text()();
  TextColumn get communityId => text()();

  @override
  Set<Column> get primaryKey => {platform, host, userId, communityId};

}
