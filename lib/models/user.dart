class LookedUpUser {

  final String? id;
  final String name;
  final String? iconUrl;
  final bool isSuspended;
  final List<UserStat>? stats;

  LookedUpUser({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.isSuspended,
    required this.stats
  });

}

class LoggedInUser {

  final String id;
  final String name;
  final String iconUrl;
  final int inboxCount;
  final int score;

  LoggedInUser({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.inboxCount,
    required this.score,
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
