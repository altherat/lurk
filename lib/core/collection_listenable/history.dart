import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database/tables/history.dart';
import 'package:lurk/core/collection_listenable/collection_listenable.dart';

class HistoryCollectionListenable extends CollectionListenable<String, bool> {

  final HistoryType _type;
  late final Database _db;
  late final Set<String> _ids;

  HistoryCollectionListenable(this._type);

  Future<void> init(Database db) async {
    _db = db;
    _ids = (await db.getHistoryIds(_type)).toSet();
  }
  
  void add(String id) {
    if (_ids.contains(id)) return;
    _ids.add(id);
    notifyListeners(id);
    _db.addHistory(id, _type);
  }
  
  @override
  bool value(String id) => _ids.contains(id);

}