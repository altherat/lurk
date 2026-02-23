import 'package:drift/drift.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/platforms.dart';

class Settings extends Table {

  IntColumn get id => integer().autoIncrement()();

  TextColumn get homeCommunityPlatform => text().map(const EnumNameConverter<Platform>(Platform.values)).nullable()();
  TextColumn get homeCommunityHost => text().nullable()();
  TextColumn get homeCommunityName => text().nullable()();

  BoolColumn get showCommentImages => boolean().withDefault(const Constant(Constants.defaultShowCommentImages))();
  BoolColumn get autoplayVideos => boolean().withDefault(const Constant(Constants.defaultAutoplayVideos))();
  BoolColumn get swipePostsToVote => boolean().withDefault(const Constant(Constants.defaultSwipePostsToVote))();
  BoolColumn get swipeCommentsToVote => boolean().withDefault(const Constant(Constants.defaultSwipeCommentsToVote))();
  BoolColumn get showCommentVotingEdges => boolean().withDefault(const Constant(Constants.defaultShowCommentVotingEdges))();
  TextColumn get commentTapBehavior => text().map(const EnumNameConverter<CommentBehavior>(CommentBehavior.values)).withDefault(Constant(Constants.defaultCommentTapBehavior.name))();
  TextColumn get commentLongPressBehavior => text().map(const EnumNameConverter<CommentBehavior>(CommentBehavior.values)).withDefault(Constant(Constants.defaultCommentLongPressBehavior.name))();

  IntColumn get appBarColor => integer().nullable()();
  BoolColumn get useBottomBar => boolean().withDefault(const Constant(Constants.defaultUseBottomBar))();
  BoolColumn get reverseCommunityList => boolean().withDefault(const Constant(Constants.defaultReverseCommunityList))();
  BoolColumn get backOnHomeScreenShowCommunityList => boolean().withDefault(const Constant(Constants.defaultBackOnHomeScreenShowCommunityList))();
  BoolColumn get showPlatformColorAccents => boolean().withDefault(const Constant(Constants.defaultShowPlatformColorAccents))();
  BoolColumn get showPlatformColorTextAccents => boolean().withDefault(const Constant(Constants.defaultShowPlatformColorTextAccents))();

  BoolColumn get redditCopyOldRedditLinks => boolean().withDefault(const Constant(Constants.defaultRedditCopyOldRedditLinks))();
  TextColumn get redditClientId => text().nullable()();
  TextColumn get redditRedirectUri => text().nullable()();
  TextColumn get redditDeviceId => text().nullable()();
  TextColumn get redditUserAgent => text().nullable()();
  
  IntColumn get diggPostsFetchDepth => integer().withDefault(const Constant(Constants.diggPostsFetchDepth))();
  TextColumn get diggUserAgent => text().nullable()();

  TextColumn get lemmyUserAgent => text().nullable()();

  TextColumn get searchType => text().map(const EnumNameConverter<SearchType>(SearchType.values)).nullable()();
  
}