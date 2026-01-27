class User {

  final String? id;
  final String name;
  final String? iconUrl;
  final bool isSuspended;
  final List<UserStat>? stats;

  User({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.isSuspended,
    required this.stats
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
