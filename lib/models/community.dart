import 'package:lurk/core/platforms.dart';

class Community {

  final Platform platform;
  final String? name;
  final String? id;
  final bool isFavorite;

  const Community({
    required this.platform,
    this.name,
    this.id,
    this.isFavorite = false,
  });

  Community copyWith({
    Platform? platform,
    String? name,
    String? id,
    bool? isFavorite
  }) {
    return Community(
      platform: platform ?? this.platform,
      name: name ?? this.name,
      id: id ?? this.id,
      isFavorite: isFavorite ?? this.isFavorite
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

  bool equalsAll(Object other) {
    if (identical(this, other)) return true;
    return other is Community &&
        other.platform == platform &&
        other.name == name &&
        other.id == id &&
        other.isFavorite == isFavorite;
  }

}
