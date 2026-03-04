import 'package:lurk/core/collection_listenable/collection_listenable.dart';
import 'package:lurk/models/interaction_state.dart';

class InteractionStateCollectionListenable extends CollectionListenable<(String?, String), InteractionState?> {

  final Map<(String?, String), InteractionState> _states = {};
  
  void update(String? userId, String id, InteractionState state) {
    final key = (userId, id);
    if (state == _states[key]) {
      return;
    }
    _states[key] = state;
    notifyListeners(key);
  }

  void updateVote(String? userId, String id, bool? newVote) {
    final key = (userId, id);
    final currentState = _states[key];
    final bool? oldVote = currentState?.vote;
    _states[key] = InteractionState(
      score: currentState != null && currentState.score != null ? currentState.score! + (newVote == true ? 1 : (newVote == false ? -1 : 0)) - (oldVote == true ? 1 : (oldVote == false ? -1 : 0)) : null,
      vote: newVote
    );
    notifyListeners(key);
  }
  
  @override
  InteractionState? value((String?, String) ids) => _states[ids];

}