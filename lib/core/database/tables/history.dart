import 'package:drift/drift.dart';

enum HistoryType { link, details }

class History extends Table {

  TextColumn get itemId => text()();
  IntColumn get type => intEnum<HistoryType>()();

  @override
  Set<Column> get primaryKey => {itemId, type};
  
}