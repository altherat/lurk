import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';

enum Flavor {
  
  combined(
    platforms: [Platform.reddit, Platform.digg, Platform.lemmy],
    defaultCommunities: [
      Community(platform: Platform.reddit, host: 'reddit.com', name: 'popular'),
      Community(platform: Platform.reddit, host: 'reddit.com', name: 'all'),
      Community(platform: Platform.digg, host: 'digg.com', name: null),
      Community(platform: Platform.lemmy, host: 'lemmy.world', name: null)
    ]
  ),

  reddit(
    platforms: [Platform.reddit],
    defaultCommunities: [
      Community(platform: Platform.reddit, host: 'reddit.com', name: 'popular'),
      Community(platform: Platform.reddit, host: 'reddit.com', name: 'all'),
    ]
  ),

  digg(
    platforms: [Platform.digg],
    defaultCommunities: [
      Community(platform: Platform.digg, host: 'digg.com', name: null)
    ]
  ),

  lemmy(
    platforms: [Platform.lemmy],
    defaultCommunities: [
      Community(platform: Platform.lemmy, host: 'lemmy.world', name: null)
    ]
  );

  final List<Platform> platforms;
  final List<Community> defaultCommunities;

  const Flavor({
    required this.platforms,
    required this.defaultCommunities
  });

}

class F {
  
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

}
