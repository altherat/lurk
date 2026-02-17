import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database/tables/history.dart';
import 'package:lurk/core/collection_listenable/collection_listenable.dart';

class HistoryCollectionListenable extends CollectionListenable<String, bool> {

  final Database _db;
  final HistoryType _type;
  late final Set<String> _ids;

  HistoryCollectionListenable(this._type) : _db = Database.instance;

  Future<void> init() async {
    _ids = (await _db.getHistoryIds(_type)).toSet();
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