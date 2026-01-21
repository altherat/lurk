import 'package:lurk/core/enums.dart';

class Community {
  
  final Platform platform;
  final String? name;
  final bool isFavorite;

  const Community({
    required this.platform,
    required this.name,
    this.isFavorite = false
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

  String get displayName => name ?? platform.communityHome ?? '';
  String get fullDisplayName => platform.communityPrefix + displayName;

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