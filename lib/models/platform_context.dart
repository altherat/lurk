import 'package:lurk/core/platforms.dart';
import 'package:lurk/models/community.dart';

class PlatformContext {

  final Platform platform;
  final String host;
  final String? iconUrl;

  const PlatformContext({
    required this.platform,
    required this.host,
    this.iconUrl,
  });

  factory PlatformContext.fromCommunity(Community community) {
    return PlatformContext(
      platform: community.platform,
      host: community.host
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PlatformContext
      && other.platform == platform
      && other.host == host;
  }

  @override
  int get hashCode => Object.hash(platform, host);

}