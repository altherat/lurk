import 'package:drift/drift.dart';

@DataClassName('Cookie')
class Cookies extends Table {

  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get expirationTime => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};
  
}