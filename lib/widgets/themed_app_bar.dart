import 'package:flutter/material.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/settings.dart';

class ThemedAppBar extends StatelessWidget implements PreferredSizeWidget {

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;

  const ThemedAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ValueListenableBuilder(
        valueListenable: Settings.appBarColor,
        builder: (context, appBarColor, child) {
          return AppBar(
            title: title,
            leading: leading,
            actions: actions,
            backgroundColor: appBarColor,
            surfaceTintColor: appBarColor,
            foregroundColor: appBarColor?.contrast,
          );
        }
      ),
    );
  }
  
}