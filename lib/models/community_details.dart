import 'package:lurk/models/community.dart';

class CommunityDetails {

  final Community community;
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

  const CommunityDetails({
    required this.community,
    this.id,
    this.createdDate,
    this.title,
    this.description,
    this.descriptionHtml,
    this.iconUrl,
    this.bannerUrl,
    this.subscriberCount,
    this.postCount,
    this.isSubscribed,
  });

}