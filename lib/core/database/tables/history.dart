import 'package:drift/drift.dart';

enum HistoryType { post, comment }

class History extends Table {

  TextColumn get itemId => text()();
  IntColumn get type => intEnum<HistoryType>()();

  @override
  Set<Column> get primaryKey => {itemId, type};
  
}