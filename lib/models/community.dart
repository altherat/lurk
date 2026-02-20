import 'package:lurk/core/platforms.dart';

class Community {

  final Platform platform;
  final String host;
  final String? name;
  final String? id;
  final bool isFavorite;

  const Community._({
    required this.platform,
    required this.host,
    this.name,
    this.id,
    this.isFavorite = false,
  });

  factory Community({
    required Platform platform,
    required String host,
    String? name,
    String? id,
    bool isFavorite = false,
  }) {
    return Community._(
      platform: platform,
      host: host,
      name: name?.toLowerCase(),
      id: id,
      isFavorite: isFavorite,
    );
  }

  Community copyWith({
    Platform? platform,
    String? host,
    String? name,
    String? id,
    bool? isFavorite
  }) {
    return Community(
      platform: platform ?? this.platform,
      host: host ?? this.host,
      name: name ?? this.name,
      id: id ?? this.id,
      isFavorite: isFavorite ?? this.isFavorite
    );
  }

  String get fullName => platform.getFullCommunityName(host, name);

  String? get nameAndMaybeHost => name != null ? platform.host != null ? name : '$name@$host' : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Community &&
        other.platform == platform &&
        other.host == host &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(platform, host, name);

}

const Community redditPopular = Community._(
  platform: Platform.reddit,
  host: 'reddit.com',
  name: 'popular',
);

const Community redditAll = Community._(
  platform: Platform.reddit,
  host: 'reddit.com',
  name: 'all',
);

const Community diggFrontPage = Community._(
  platform: Platform.digg,
  host: 'digg.com',
);

const Community lemmyFrontPage = Community._(
  platform: Platform.lemmy,
  host: 'lemmy.world'
);
