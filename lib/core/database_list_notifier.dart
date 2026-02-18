import 'package:flutter/foundation.dart';

class DatabaseListNotifier<T> extends ChangeNotifier implements ValueListenable<List<T>> {

  List<T> _value;
  final Future<void> Function(T item) _save;
  final Future<void> Function(Iterable<T> items)? _saveAll;
  final Future<void> Function(T item) _delete;
  final Future<void> Function(Iterable<T> items)? _deleteAll;

  DatabaseListNotifier(
    List<T> initialValue, {
    required Future<void> Function(T) save,
    Future<void> Function(Iterable<T> items)? saveAll,
    required Future<void> Function(T) delete,
    Future<void> Function(Iterable<T> items)? deleteAll,
  }) :  _value = List.unmodifiable(initialValue),
        _save = save,
        _saveAll = saveAll,
        _delete = delete,
        _deleteAll = deleteAll;

  @override
  List<T> get value => _value;

  Future<void> add(T item) async {
    if (_value.contains(item)) {
      return;
    }
    _value = List.unmodifiable([..._value, item]);
    notifyListeners();
    await _save(item);
  }

  Future<void> addAll(Iterable<T> items) async {
    final newItems = items.where((item) => !_value.contains(item)).toList();
    if (newItems.isEmpty) {
      return;
    }
    _value = List.unmodifiable([..._value, ...newItems]);
    notifyListeners();
    await _saveAll!.call(newItems);
  }

  Future<void> remove(T item) async {
    if (!_value.contains(item)) {
      return;
    }
    _value = List.unmodifiable(_value.where((x) => x != item));
    notifyListeners();
    await _delete(item);
  }

  Future<void> update(T item) async {
    final index = _value.indexOf(item);
    if (index != -1) {
      final newList = List<T>.from(_value);
      newList[index] = item;
      _value = List.unmodifiable(newList);
      notifyListeners();
      await _save(item);
    }
  }

  Future<void> updateAll(bool Function(List<T> items) fn) async {
    final newList = List<T>.from(_value);
    if (fn(newList)) {
      _value = List.unmodifiable(newList);
      notifyListeners();
      await _saveAll!.call(newList);
    }
  }

  Future<void> clear() async {
    _value = List.unmodifiable([]);
    notifyListeners();
    await _deleteAll?.call(_value);
  }

  void sort(int Function(T a, T b) compare) {
    final newList = List<T>.from(_value);
    newList.sort(compare);
    _value = List.unmodifiable(newList);
    notifyListeners();
  }

}