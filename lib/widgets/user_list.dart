import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/list_tile_icon.dart';

class UserList extends StatefulWidget {

  final List<LoggedInUser> loggedInUsers;
  final LoggedInUser activeUser;
  final Widget? addUserTileTrailing;
  final VoidCallback onLoginPressed;

  const UserList({
    super.key,
    required this.loggedInUsers,
    required this.activeUser,
    this.addUserTileTrailing,
    required this.onLoginPressed,
  });

  @override
  State<UserList> createState() => _UserListState();

}

class _UserListState extends State<UserList> {

  bool _isExpanded = false;

  void _onTileLongPress(LoggedInUser user, bool isActiveUser) {
    showSimpleOptionsDialog(
      context: context,
      title: user.platform.getPrefixedUsername(user.name),
      options: {
        'View profile': (){
          context.pop();
          context.push(() {
            return UserDetailsScreen(
              platform: user.platform,
              username: user.name
            );
          });
        },
        'Logout': () {
          Settings.loggedInUsers.remove(user);
          if (isActiveUser) {
            Settings.activeUser.value = Settings.loggedInUsers.value.firstOrNull;
          }
         user.platform.api.logout(user.id);
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final inactiveUsers = widget.loggedInUsers.where((user) => user != widget.activeUser);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                horizontalTitleGap: 8,
                leading: IconButton(
                  icon: Icon(Icons.add_rounded),
                  onPressed: widget.onLoginPressed
                ),
                title: Text('Add user'),
                trailing: widget.addUserTileTrailing,
                onTap: widget.onLoginPressed,
              ),
              ...inactiveUsers.map((user) => UserListTile(
                platform: user.platform,
                user: user,
                onTap: () async {
                  Settings.activeUser.value = user;
                  await Future.delayed(const Duration(milliseconds: 300));
                  setState(() => _isExpanded = false);
                },
                onLongPress: () => _onTileLongPress(user, false)
              ))
            ],
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 500),
          sizeCurve: Curves.easeInOutCubicEmphasized, 
        ),
        UserListTile(
          platform: widget.activeUser.platform,
          user: widget.activeUser,
          trailing: IconButton(
            icon: Icon(_isExpanded ? Icons.expand_more_rounded : Icons.expand_less_rounded),
            onPressed: () => setState(() => _isExpanded = !_isExpanded)
          ),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          onLongPress: () => _onTileLongPress(widget.activeUser, true)
        )
      ],
    );
  }

}

class UserListTile extends StatelessWidget {

  final Platform platform;
  final LoggedInUser user;
  final Widget? trailing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const UserListTile({
    super.key,
    required this.platform,
    required this.user,
    this.trailing,
    required this.onTap,
    this.onLongPress
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 8,
      leading: UserIcon(user: user),
      title: Text(user.name),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

}

class UserIcon extends StatelessWidget {

  final LoggedInUser user;

  const UserIcon({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6), 
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: user.platform.color, width: 1), 
      ),
      child: ListTileIcon(
        platform: user.platform,
        url: user.iconUrl,
        size: 34,
        placeholderIcon: Icons.no_accounts_rounded,
      ),
    );
  }

}