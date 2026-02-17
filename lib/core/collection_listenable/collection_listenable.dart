import 'package:flutter/foundation.dart';

abstract class CollectionListenable<T, R> {

  final Map<T, Set<VoidCallback>> _listeners = {};

  R value(T id);

  void notifyListeners(T id) {
    _listeners[id]?.forEach((callback) => callback());
  }

  void addListener(T id, VoidCallback callback) {
    (_listeners[id] ??= {}).add(callback);
  }

  void removeListener(T id, VoidCallback callback) {
    if (_listeners.containsKey(id)) {
      final listeners = _listeners[id]!;
      listeners.remove(callback);
      if (listeners.isEmpty) {
        _listeners.remove(id);
      }
    }
  }

}