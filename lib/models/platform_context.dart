import 'package:lurk/core/platforms.dart';

class PlatformContext {

  final Platform platform;
  final String host;

  const PlatformContext({
    required this.platform,
    required this.host
  });

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