import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/user.dart';

class UserStats extends StatelessWidget {

  final List<UserStat> stats;
  final EdgeInsetsGeometry? padding;
  final double valueFontSize;
  final Color? color;
  final double labelFontSize;

  const UserStats({
    super.key,
    required this.stats,
    this.padding,
    this.valueFontSize = 18,
    this.color,
    this.labelFontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        spacing: 24,
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
                    fontSize: valueFontSize,
                    color: color,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: color?.withAlpha(Constants.secondaryTextColorAlpha)
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