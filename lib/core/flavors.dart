import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';

enum Flavor {
  
  combined(
    platforms: [Platform.reddit, Platform.digg, Platform.lemmy],
    defaultCommunities: [
      redditPopular,
      redditAll,
      diggFrontPage,
      lemmyFrontPage
    ]
  ),

  reddit(
    platforms: [Platform.reddit],
    defaultCommunities: [
      redditPopular,
      redditAll,
    ]
  ),

  digg(
    platforms: [Platform.digg],
    defaultCommunities: [
      diggFrontPage
    ]
  ),

  lemmy(
    platforms: [Platform.lemmy],
    defaultCommunities: [
      lemmyFrontPage
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

const Community redditPopular = Community(
  platform: Platform.reddit,
  name: 'popular',
  host: 'www.reddit.com',
);

const Community redditAll = Community(
  platform: Platform.reddit,
  name: 'all',
  host: 'www.reddit.com',
);

const Community diggFrontPage = Community(
  platform: Platform.digg,
  name: null,
  host: 'digg.com',
);

const Community lemmyFrontPage = Community(
  platform: Platform.lemmy,
  name: null,
  host: 'lemmy.world',
);
