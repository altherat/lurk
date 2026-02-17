import 'package:flutter/material.dart';
import 'package:lurk/core/platforms.dart';

class Constants {

  static const version = '1.0.0';

  static const separator = ' • ';

  static const screenTransitionDuration = Duration(milliseconds: 250);
  static const reverseScreenTransitionDuration = Duration(milliseconds: 100);
  static const feedLoadAnimationDuration = Duration(milliseconds: 500);

  static const thumbnailSize = 70.0;
  static const scrimAlpha = 125;
  static const onSurfaceVariantAlpha = 179;
  static const choiceChipGapSize = 14.0;
  
  static const primaryColor = Color(0xFFAADFF1);
  static const lighterBackgroundColor = Color(0xFF1F1F1F);
  static const secondaryTextColor = Color(0xFFB3B3B3);
  static const refreshIndicatorBackgroundColor = Color(0xFF000000);
  static const textFieldHintColor = Color(0xAAFFFFFF);
  static const scrollbarColor = Color(0x60FFFFFF);
  static const visitedTextColor = Color(0xFFAAAAFF);
  static const loadMoreCommentsTextColor = Color(0xFF2676AF);
  static const contextCommentBackgroundColor = Color(0xFF1F1F1F); //Color(0xFF0C1A2B);
  static const postStickiedTitleColor = Color(0xFF99CC00);
  static const postVisitedTitleColor = Color(0xFFAAAAFF);
  static const postBodyBorderColor = Color(0xFFCCCCCC);
  static const upvoteColor = Color(0xFFFF8A63);
  static const downvoteColor = Color(0xFF9494FF);
  static const commentIndentColor = Color(0xFF3F3F3F);
  static const commentAuthorColor = Color(0xFF888888);
  static const commentModeratorColor = Color(0xFF228822);
  static const commentSubmitterColor = Color(0xFFAACCFF);
  static const htmlLinkColor = Color(0xFF66CCDD);
  static const htmlQuoteLineColor = Color(0xFF3388CC);

  static const defaultShowCommentImages = true;
  static const defaultAutoplayVideos = true;
  static const defaultCommentTapBehavior = CommentBehavior.expandOrCollapse;
  static const defaultCommentLongPressBehavior = CommentBehavior.showOptions;
  static const defaultSwipePostsToVote = false;
  static const defaultSwipeCommentsToVote = false;
  static const defaultShowCommentVotingEdges = false;
  static const defaultAppBarColor = Color(0xFF000000);
  static const defaultUseBottomBar = false;
  static const defaultReverseCommunityList = false;
  static const defaultBackOnHomeScreenShowCommunityList = true;
  static const diggPostsFetchDepth = 3;
  static const defaultShowPlatformColorAccents = true;
  static const defaultShowPlatformColorTextAccents = false;
  static const defaultRedditCopyOldRedditLinks = false;
  static const defaultDiggPostsFetchDepth = 3;
    
}