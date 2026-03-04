import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database_list_notifier.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/user.dart';

class Communities {

  static late final DatabaseListNotifier<Community> saved;
  static late final Map<(Platform, String, String), Set<String>> _subscribedCommunityIds;

  static void init(Database db, List<Community> savedCommunities, Map<(Platform, String, String), Set<String>> subscribedCommunityIds) {
    saved = DatabaseListNotifier<Community>(
      savedCommunities,
      save: db.saveCommunity,
      saveAll: db.saveAllCommunities,
      delete: db.deleteCommunity,
    );
    _subscribedCommunityIds = subscribedCommunityIds;
  }

  static void addSubscribedCommunity(Platform platform, String host, String userId, String communityId) {
    if (_subscribedCommunityIds.putIfAbsent((platform, host, userId), () => {}).add(communityId)) {
      Database.instance.saveCommunitySubscription(platform, host, userId, communityId);
    }
  }

  static void removeSubscribedCommunity(Platform platform, String host, String userId, String communityId) {
    if (_subscribedCommunityIds[(platform, host, userId)]?.remove(communityId) ?? false) {
      Database.instance.deleteCommunitySubscription(platform, host, userId, communityId);
    }
  }

  static void addAllSubscribedCommunities(Platform platform, String host, String userId, Iterable<Community> communities) {
    final Set<String> communityIds = {};
    for (final community in communities) {
      communityIds.add(community.id!);
    }
    _subscribedCommunityIds[(platform, host, userId)] = communityIds;
    Database.instance.saveAllCommunitySubscriptions(platform, host, userId, communityIds);
  }

  static bool isSubscribed(LoggedInUser user, String communityId) => _subscribedCommunityIds[(user.platform, user.host, user.id)]?.contains(communityId) ?? false;

}