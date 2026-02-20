import 'package:lurk/core/platforms.dart';

class LookedUpUser {

  final String host;
  final String? id;
  final String name;
  final String? iconUrl;
  final bool isSuspended;
  final List<UserStat>? stats;

  LookedUpUser({
    required this.host,
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.isSuspended,
    required this.stats
  });

}

class LoggedInUser {

  final Platform platform;
  final String host;
  final String? hostIconUrl;
  final String id;
  final String name;
  final String? iconUrl;

  LoggedInUser({
    required this.platform,
    required this.host,
    this.hostIconUrl,
    required this.id,
    required this.name,
    required this.iconUrl,
  });

}

class UserStat {

  final String label;
  final dynamic value;

  UserStat({
    required this.label,
    required this.value
  });

}
