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
  BoolColumn get showPlatformColorAccents => boolean().withDefault(const Constant(Constants.defaultShowPlatformColorAccents))();

  TextColumn get clientId => text().nullable()();
  TextColumn get redirectUri => text().nullable()();
  BoolColumn get copyOldRedditLinks => boolean().withDefault(const Constant(Constants.defaultCopyOldRedditLinks))();
  
  TextColumn get userAgent => text().nullable()();
  
}