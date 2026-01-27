import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/user.dart';

class UserStats extends StatelessWidget {

  final List<UserStat> stats;
  final EdgeInsetsGeometry? padding;
  final Color? valueColor;

  const UserStats({
    super.key,
    required this.stats,
    this.padding,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        spacing: 16,
        children: stats.map((stat) {
          final value = stat.value;
          final String displayValue;
          if (value is DateTime) {
            displayValue = value.timeAgo;
          }
          else if (value is num) {
            displayValue = value.toCommaString();
          }
          else {
            displayValue = value.toString();
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor
                  ),
                ),
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Constants.secondaryTextColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

}