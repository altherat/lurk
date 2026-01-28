import 'package:lurk/core/collection_listenable.dart';

class Votes extends CollectionListenable<String, bool?> {

  static final Votes posts = Votes._();
  static final Votes comments = Votes._();

  final Map<String, bool?> _votes = {};

  Votes._();
  
  void setVote(String id, bool? vote) {
    _votes[id] = vote;
    notifyListeners(id);
  }
  
  @override
  bool? value(String id) => _votes[id];

}