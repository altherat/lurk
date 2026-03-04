import 'package:lurk/core/platforms.dart';

class User {
  
  final Platform platform;
  final String host;
  final String name;
  final String? iconUrl;

  const User({
    required this.platform,
    required this.host,
    required this.name,
    this.iconUrl
  });
  
  String get nameAndMaybeHost => platform.getUserNameAndMaybeHost(host, name);

  String get prefixedNameAndMaybeHost => platform.getPrefixedUserNameAndMaybeHost(host, name);

}

class LookedUpUser extends User {

  final String? id;
  final bool isSuspended;
  final List<UserStat>? stats;

  const LookedUpUser({
    required super.platform,
    required super.host,
    required this.id,
    required super.name,
    required super.iconUrl,
    required this.isSuspended,
    required this.stats
  });

}

class LoggedInUser extends User {

  final String id;
  final String? hostIconUrl;

  const LoggedInUser({
    required this.id,
    required super.platform,
    required super.host,
    required super.name,
    required super.iconUrl,
    this.hostIconUrl,
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