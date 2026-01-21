import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';

class Constants {

  const Constants._();

  static const scrimAlpha = 125;
  static const communityPrefixAlpha = 125;
  static const appBarSubtitleAlpha = 175;
  static const platformColorBackgroundAlpha = 100;
  static const primaryColor = Color(0xFFAADFF1);
  static const splashColor = Color(0x30AADFF1);
  static const highlightColor = Color(0x30AADFF1);
  static const lighterBackgroundColor = Color(0xFF1F1F1F);
  static const refreshIndicatorBackgroundColor = Color(0xFF000000);
  static const popupMenuColor = Color(0xFF212121);
  static const dialogBackgroundColor = Color(0xFF212121);
  static const textFieldHintColor = Color(0xAAFFFFFF);
  static const scrollbarColor = Color(0x60FFFFFF);
  static const secondaryTextColor = Color(0xFFB3B3B3);
  static const visitedTextColor = Color(0xFFAAAAFF);
  static const linkTextColor = Color(0xFF2676AF);
  static const postSelectedBackgroundColor = Color(0xFF0C1A2B);
  static const postStickiedTitleColor = Color(0xFF99CC00);
  static const postVisitedTitleColor = Color(0xFFAAAAFF);
  static const postTextHtmlBorderColor = Color(0xFFCCCCCC);
  static const upvoteColor = Color(0xFFFF8A63);
  static const downvoteColor = Color(0xFF9494FF);
  static const commentIndentColor = Color(0xFF3F3F3F);
  static const commentAuthorColor = Color(0xFF888888);
  static const commentModeratorColor = Color(0xFF228822);
  static const commentSubmitterColor = Color(0xFFAACCFF);
  static const htmlLinkColor = Color(0xFF66CCDD);
  static const htmlQuoteLineColor = Color(0xFF3388CC);
  // static const htmlQuoteTextColor = Colors.white;

  static const databaseName = 'lurk';
  static final diggApiBaseUrl = 'https://apineapple-prod.digg.com/graphql';
  static const defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36';
  static const defaultPlatform = Platform.reddit;
  static const defaultShowCommentImages = true;
  static const defaultAutoplayVideos = true;
  static const defaultAppBarColor = Color(0xFF000000);
  static const defaultUseBottomBar = false;
  static const defaultShowPlatformColorAccents = false;
  static const defaultCopyOldRedditLinks = false;

  static const userAgentHeader = {
    'User-Agent': defaultUserAgent
  };

  static const httpHeaders = {
    ...userAgentHeader,
    // 'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    // 'Accept-Language': 'en-CA,en-US;q=0.9,en-GB;q=0.8,en;q=0.7',
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
  };
    
}