import 'package:drift/drift.dart';
import 'package:lurk/models/user.dart';

@UseRowClass(LoggedInUser)
class Users extends Table {

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get iconUrl => text()();
  IntColumn get inboxCount => integer()();
  IntColumn get score => integer()();

  @override
  Set<Column> get primaryKey => {id};

}
