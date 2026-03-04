import 'package:lurk/core/platforms.dart';

class Community {

  final Platform platform;
  final String host;
  final String? name;
  final String? id;
  final bool isFavorite;

  const Community({
    required this.platform,
    required this.host,
    required this.name,
    this.id,
    this.isFavorite = false,
  });
  
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

  String get prefixedNameAndMaybeHost => platform.getPrefixedCommunityNameAndMaybeHost(host, name);

  String? get nameAndMaybeHost => platform.getCommunityNameAndMaybeHost(host, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Community
      && other.platform == platform
      && other.host == host
      && other.name == name;
  }

  @override
  int get hashCode => Object.hash(platform, host, name);

}
