import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/platform_context.dart';

class Community {

  final PlatformContext platformContext;
  final String? name;
  final String? id;
  final bool isFavorite;
  final String? originHost;

  const Community.fromPlatformContext(
    this.platformContext, {
    required this.name,
    this.id,
    this.isFavorite = false,
    this.originHost
  });

  factory Community({
    required Platform platform,
    required String host,
    String? name,
    String? id,
    bool isFavorite = false,
    String? originHost
  }) => Community.fromPlatformContext(
    PlatformContext(platform: platform, host: host),
    name: name?.toLowerCase(),
    id: id,
    isFavorite: isFavorite,
    originHost: originHost
  );
  
  Community copyWith({
    PlatformContext? platformContext,
    String? name,
    String? id,
    bool? isFavorite
  }) {
    return Community.fromPlatformContext(
      platformContext ?? this.platformContext,
      name: name ?? this.name,
      id: id ?? this.id,
      isFavorite: isFavorite ?? this.isFavorite
    );
  }

  String get fullName => platformContext.platform.getFullCommunityName(originHost ?? platformContext.host, name);

  String? get nameAndMaybeHost => name != null ? platformContext.platform.supportsMultipleHosts ? '$name@${originHost ?? platformContext.host}' : name : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Community
      && other.platformContext == platformContext
      && other.name == name;
  }

  @override
  int get hashCode => Object.hash(platformContext, name);

}

const Community redditPopular = Community.fromPlatformContext(
  PlatformContext(platform: Platform.reddit, host: 'www.reddit.com'),
  name: 'popular',
);

const Community redditAll = Community.fromPlatformContext(
  PlatformContext(platform: Platform.reddit, host: 'www.reddit.com'),
  name: 'all',
);

const Community diggFrontPage = Community.fromPlatformContext(
  PlatformContext(platform: Platform.digg, host: 'digg.com'),
  name: null
);

const Community lemmyFrontPage = Community.fromPlatformContext(
  PlatformContext(platform: Platform.lemmy, host: 'lemmy.world'),
  name: null
);
