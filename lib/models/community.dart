import 'package:lurk/core/enums.dart';

class Community {

  final Platform platform;
  final String? name;
  final bool isFavorite;

  final String? id;
  final DateTime? createdDate;
  final String? title;
  final String? description;
  final String? descriptionHtml;
  final String? iconUrl;
  final String? bannerUrl;
  final int? subscriberCount;
  final int? postCount;
  final bool? isSubscribed;

  const Community({
    required this.platform,
    this.name,
    this.isFavorite = false,
    this.id,
    this.createdDate,
    this.title,
    this.description,
    this.descriptionHtml,
    this.iconUrl,
    this.bannerUrl,
    this.subscriberCount,
    this.postCount,
    this.isSubscribed
  });

  Community copyWith({
    Platform? platform,
    String? name,
    bool? isFavorite,
    bool? isSubscribed
  }) {
    return Community(
      platform: platform ?? this.platform,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      isSubscribed: isSubscribed ?? this.isSubscribed,
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
