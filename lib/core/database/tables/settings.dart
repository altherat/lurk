import 'package:drift/drift.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';

class Settings extends Table {

  IntColumn get id => integer().autoIncrement()();

  TextColumn get homeCommunityPlatform => text().map(const EnumNameConverter<Platform>(Platform.values)).nullable()();
  TextColumn get homeCommunityName => text().nullable()();

  BoolColumn get showCommentImages => boolean().withDefault(const Constant(Constants.defaultShowCommentImages))();
  BoolColumn get autoplayVideos => boolean().withDefault(const Constant(Constants.defaultAutoplayVideos))();

  IntColumn get appBarColor => integer().nullable()();
  BoolColumn get useBottomBar => boolean().withDefault(const Constant(Constants.defaultUseBottomBar))();
  BoolColumn get reverseCommunityList => boolean().withDefault(const Constant(Constants.defaultReverseCommunityList))();
  BoolColumn get showPlatformColorAccents => boolean().withDefault(const Constant(Constants.defaultShowPlatformColorAccents))();
  BoolColumn get showPlatformColorTextAccents => boolean().withDefault(const Constant(Constants.defaultShowPlatformColorTextAccents))();

  BoolColumn get redditCopyOldRedditLinks => boolean().withDefault(const Constant(Constants.defaultRedditCopyOldRedditLinks))();
  TextColumn get redditClientId => text().nullable()();
  TextColumn get redditRedirectUri => text().nullable()();
  TextColumn get redditDeviceId => text().nullable()();
  
  IntColumn get diggPostsFetchDepth => integer().withDefault(const Constant(Constants.diggPostsFetchDepth))();
  
  TextColumn get userAgent => text().nullable()();

  TextColumn get searchType => text().map(const EnumNameConverter<SearchType>(SearchType.values)).nullable()();
  
  TextColumn get activeUserId => text().nullable()();
  
}