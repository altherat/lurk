import 'package:lurk/models/community.dart';

class CommunityDetails {

  final Community community;
  final String? id;
  final DateTime? createdDate;
  final String? title;
  final String? shortDescription;
  final String? longDescriptionHtml;
  final String? iconUrl;
  final String? bannerUrl;
  final int? subscriberCount;
  final int? postCount;
  final String? primaryColorHexCode;
  final String? bannerBackgroundColorHexCode;
  final bool? isSubscribed;

  const CommunityDetails({
    required this.community,
    this.id,
    this.createdDate,
    this.title,
    this.shortDescription,
    this.longDescriptionHtml,
    this.iconUrl,
    this.bannerUrl,
    this.subscriberCount,
    this.postCount,
    this.primaryColorHexCode,
    this.bannerBackgroundColorHexCode,
    this.isSubscribed,
  });

}