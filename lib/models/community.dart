import 'package:lurk/core/enums.dart';

class Community {
  
  final Platform platform;
  final String? name;
  final bool isFavorite;

  final String? iconUrl;
  final String? description;
  final int? subscriberCount;

  const Community({
    required this.platform,
    this.name,
    this.isFavorite = false,
    this.iconUrl,
    this.description,
    this.subscriberCount,
  });

  Community copyWith({
    Platform? platform,
    String? name,
    bool? isFavorite,
  }) {
    return Community(
      platform: platform ?? this.platform,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get prefixedName => platform.getPrefixedCommunityName(name ?? '');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Community &&
      other.platform == platform &&
      other.name == name;
  }

  @override
  int get hashCode => Object.hash(platform, name);

}