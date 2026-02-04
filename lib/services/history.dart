import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database/tables/history.dart';
import 'package:lurk/core/collection_listenable.dart';

class History extends CollectionListenable<String, bool> {

  static final History posts = History._(HistoryType.post);
  static final History postDetails = History._(HistoryType.comment);

  final Database _db;
  final HistoryType _type;
  late final Set<String> _ids;

  History._(this._type) : _db = Database.instance;

  static Future<void> init() async {
    await posts._init();
    await postDetails._init();
  }

  Future<void> _init() async {
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