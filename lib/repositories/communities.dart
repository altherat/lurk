import 'package:lurk/core/database/database.dart';
import 'package:lurk/core/database_list_notifier.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';

class Communities {

  static late final DatabaseListNotifier<Community> saved;
  static late final Map<(Platform, String), Set<String>> _subscribedCommunityNames;

  static Future<void> init() async {
    final [savedCommunities as List<Community>, getSubscribedCommunityNames as Map<(Platform, String), Set<String>>] = await Future.wait([Database.instance.getAllCommunities(), Database.instance.getAllSubscribedCommunities()]);
    saved = DatabaseListNotifier<Community>(
      savedCommunities,
      save: Database.instance.saveCommunity,
      saveAll: Database.instance.saveAllCommunities,
      delete: Database.instance.deleteCommunity,
    );
    _subscribedCommunityNames = getSubscribedCommunityNames;
  }

  static void addSubscribedCommunity(Platform platform, String userId, String communityName) {
    if (_subscribedCommunityNames.putIfAbsent((platform, userId), () => {}).add(communityName)) {
      Database.instance.saveCommunitySubscription(platform, userId, communityName);
    }
  }

  static void removeSubscribedCommunity(Platform platform, String userId, String communityName) {
    if (_subscribedCommunityNames[(platform, userId)]?.remove(communityName) ?? false) {
      Database.instance.deleteCommunitySubscription(platform, userId, communityName);
    }
  }

  static void updateSubscribedCommunity(Platform platform, String userId, String communityname, bool isSubscribed) {
    if (isSubscribed) {
      addSubscribedCommunity(platform, userId, communityname);
    }
    else {
      removeSubscribedCommunity(platform, userId, communityname);
    }
  }

  static void addAllSubscribedCommunities(Platform platform, String userId, Iterable<Community> communities) {
    final Set<String> communityNames = {};
    for (final community in communities) {
      communityNames.add(community.name!);
    }
    _subscribedCommunityNames[(platform, userId)] = communityNames;
    Database.instance.saveAllCommunitySubscriptions(platform, userId, communityNames);
  }

  static bool isSubscribed(Platform platform, String userId, String communityName) => _subscribedCommunityNames[(platform, userId)]?.contains(communityName) ?? false;

}