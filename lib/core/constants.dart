import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';

class Constants {

  static const screenTransitionDuration = Duration(milliseconds: 250);
  static const reverseScreenTransitionDuration = Duration(milliseconds: 100);
  static const feedLoadAnimationDuration = Duration(milliseconds: 400);
  static const thumbnailSize = 70;
  static const scrimAlpha = 125;
  static const appBarSubtitleAlpha = 175;
  static const namePrefixAlpha = 125;
  static const refreshIndicatorDisplacement = 15.0;
  static const choiceChipGapSize = 12.0;
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
  static const contextCommentBackgroundColor = Color(0xFF1F1F1F); //Color(0xFF0C1A2B);
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

  static const databaseName = 'lurk';
  static const defaultPlatform = Platform.reddit;
  static const defaultShowCommentImages = true;
  static const defaultAutoplayVideos = true;
  static const defaultAppBarColor = Color(0xFF000000);
  static const defaultUseBottomBar = false;
  static const diggPostsFetchDepth = 3;
  static const defaultShowPlatformColorAccents = true;
  static const defaultShowPlatformColorTextAccents = false;
  static const defaultRedditCopyOldRedditLinks = false;
  static const defaultDiggPostsFetchDepth = 3;
    
}