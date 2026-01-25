import 'package:flutter/foundation.dart';
import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database/tables/history.dart';

class History {

  static final History posts = History._(HistoryType.post);
  static final History postDetails = History._(HistoryType.comment);

  final Database _db;
  final HistoryType _type;
  late final Set<String> _ids;
  final Map<String, HistoryNotifier> _notifiers = {};

  History._(this._type) : _db = Database.instance;

  static Future<void> init() async {
    await posts._init();
    await postDetails._init();
  }

  Future<void> _init() async {
    _ids = (await _db.getHistoryIds(_type)).toSet();
  }

  HistoryNotifier getNotifier(String id) {
    final notifier = _notifiers.putIfAbsent(
      id,
      () => HistoryNotifier(
        _ids.contains(id), 
        onDispose: () => _notifiers.remove(id),
      )
    );
    notifier._addRef();
    return notifier;
  }

  void setVisited(String id) {
    if (_ids.contains(id)) return;
    _ids.add(id);
    _notifiers[id]?.value = true;
    _db.addHistory(id, _type);
  }

}

class HistoryNotifier extends ValueNotifier<bool> {

  final VoidCallback onDispose;
  int _refCount = 0;
  
  HistoryNotifier(super.value, {required this.onDispose});

  void _addRef() => _refCount++;

  @override
  void dispose() {
    _refCount--;
    if (_refCount == 0) {
      onDispose();
      super.dispose();
    }
  }

}