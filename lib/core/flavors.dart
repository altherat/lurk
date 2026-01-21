import 'package:lurk/core/enums.dart';
import 'package:lurk/models/community.dart';

enum Flavor {

  reddit(
    platforms: [Platform.reddit],
    defaultCommunities: [
      Community(platform: Platform.reddit, name: 'popular'),
      Community(platform: Platform.reddit, name: 'all'),
    ]
  ),
  digg(
    platforms: [Platform.digg],
    defaultCommunities: [
      Community(platform: Platform.digg, name: null)
    ]
  ),
  combined(
    platforms: [Platform.reddit, Platform.digg],
    defaultCommunities: [
      Community(platform: Platform.reddit, name: 'popular'),
      Community(platform: Platform.reddit, name: 'all'),
      Community(platform: Platform.digg, name: null)
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
