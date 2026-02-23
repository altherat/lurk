import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/platform_context.dart';

abstract class User {
  
  final String id;
  final String name;
  final String? iconUrl;

  const User({
    required this.id,
    required this.name,
    required this.iconUrl
  });
}

class LookedUpUser extends User {

  final bool isSuspended;
  final List<UserStat>? stats;

  const LookedUpUser({
    required super.id,
    required super.name,
    required super.iconUrl,
    required this.isSuspended,
    required this.stats
  });

}

class LoggedInUser extends User {

  final PlatformContext platformContext;
  final String? hostIconUrl;

  LoggedInUser({
    required Platform platform,
    required String host,
    required super.id,
    required super.name,
    required super.iconUrl,
    this.hostIconUrl,
  }) : platformContext = PlatformContext(platform: platform, host: host);

}

class UserStat {

  final String label;
  final dynamic value;

  UserStat({
    required this.label,
    required this.value
  });

}
