// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lurk/core/constants.dart';
// import 'package:lurk/core/enums.dart';
// import 'package:lurk/core/utils.dart';
// import 'package:lurk/screens/settings.dart';
// import 'package:lurk/services/settings.dart';
// import 'package:lurk/widgets/community_list.dart';
// import 'package:lurk/widgets/scrim.dart';
// import 'package:lurk/widgets/user_list.dart';

// class AppDrawer extends StatelessWidget {

//   final Platform platform;
//   final String? activeCommunityName;
//   const AppDrawer({
//     super.key,
//     required this.platform,
//     this.activeCommunityName
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Drawer(
//       child: AnnotatedRegion<SystemUiOverlayStyle>(
//         value: const SystemUiOverlayStyle(
//           statusBarColor: Colors.transparent,
//           statusBarIconBrightness: Brightness.light, 
//           statusBarBrightness: Brightness.dark,      
//         ),
//         child: SafeArea(
//           top: false,
//           child: Stack(
//             children: [
//               Column(children: [
//                 Expanded(
//                   child: CommunityList(
//                     platform: platform,
//                     activeCommunityName: activeCommunityName,
//                     onCommunitySelected: (isActive) {
//                       if (isActive) {
//                         _scrollToTopAndRefresh();
//                       }
//                     }
//                   )
//                 ),
//                 DecoratedBox(
//                   decoration: const BoxDecoration(
//                     border: Border(
//                       top: BorderSide(
//                         color: Constants.lighterBackgroundColor,
//                         width: 1,
//                       ),
//                     ),
//                   ),
//                   child: SafeArea(
//                     top: false,
//                     child: ValueListenableBuilder(
//                       valueListenable: Settings.loggedInUsers,
//                       builder: (context, loggedInUsers, child) {
//                         if (loggedInUsers.isEmpty) {
//                           if (platform.api.hasLogin) {
//                             return ValueListenableBuilder(
//                               valueListenable: Settings.redditClientId,
//                               builder: (context, redditClientId, child) {
//                                 return ValueListenableBuilder(
//                                   valueListenable: Settings.redditRedirectUri,
//                                   builder: (context, redditRedirectUri, child) {
//                                     if (redditClientId == null || redditRedirectUri == null) {
//                                       return const ListTile(leading: _SettingsIconButton());
//                                     }
//                                     return ListTile(
//                                       title: Text('Login to Reddit'),
//                                       onTap: _onLoginPressed,
//                                       trailing: const _SettingsIconButton(),
//                                     );
//                                   }
//                                 );
//                               }
//                             );
//                           }
//                           return const ListTile(leading: _SettingsIconButton());
//                         }
//                         return ValueListenableBuilder(
//                           valueListenable: Settings.activeUser,
//                           builder: (context, activeUser, child) {
//                             return UserList(
//                               loggedInUsers: loggedInUsers,
//                               activeUser: activeUser!,
//                               addUserTileTrailing: const _SettingsIconButton(),
//                               onLoginPressed: _onLoginPressed,
//                             );
//                           }
//                         );
//                       }
//                     ),
//                   ),
//                 )
//               ]),
//               Scrim(color: (theme.drawerTheme.backgroundColor ?? theme.canvasColor).withAlpha(Constants.scrimAlpha)),
//             ],
//           ),
//         ),
//       )
//     );
//   }
  
// }

// class _SettingsIconButton extends StatelessWidget {

//   const _SettingsIconButton({
//     super.key
//   });

//   @override
//   Widget build(BuildContext context) {
//     return IconButton(
//       icon: Icon(Icons.settings_rounded),
//       onPressed: () {
//         context.pop();
//         context.push(() => const SettingsScreen());
//       }
//     );
//   }
// }