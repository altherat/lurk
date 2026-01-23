 //TODO

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class UserDetailsScreen extends StatelessWidget {

  final Platform platform;
  final String username;

  const UserDetailsScreen({
    super.key,
    required this.platform,
    required this.username
  });

  @override
  Widget build(BuildContext context) {
    final parentColor = DefaultTextStyle.of(context).style.color;
    final parentAlpha = (parentColor!.a * 255).toInt();
    return MainScaffold(
      platform: platform,
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: platform.userPrefix,
              style: TextStyle(color: parentColor.withAlpha(min(parentAlpha, Constants.namePrefixAlpha))),
            ),
            TextSpan(text: username),
          ],
        ),
      ),
      feedOptions: platform.userPostsFeedOptions,
      body: CustomRefreshIndicator(
        platform: platform,
        onRefresh: () async {
          
        },
        child: Placeholder()
      )
    );
  }
  
}