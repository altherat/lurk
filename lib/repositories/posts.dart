
import 'package:lurk/core/database/tables/history.dart';
import 'package:lurk/core/collection_listenable/history.dart';
import 'package:lurk/core/collection_listenable/interaction_state.dart';

class Posts {

  static final visitedLinks = HistoryCollectionListenable(HistoryType.link);
  static final visitedDetails = HistoryCollectionListenable(HistoryType.details);
  static final interactionStates = InteractionStateCollectionListenable();

  static Future<void> init() async {
    await visitedLinks.init();
    await visitedDetails.init();
  }

}