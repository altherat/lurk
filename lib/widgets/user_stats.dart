import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/models/user.dart';
import 'package:lurk/widgets/stat.dart';

class UserStats extends StatelessWidget {

  final List<UserStat> stats;
  final EdgeInsetsGeometry? padding;
  final double valueFontSize;
  final double labelFontSize;
  final Color? valueColor;
  final Color? labelColor;

  const UserStats({
    super.key,
    required this.stats,
    this.padding,
    this.valueFontSize = 18,
    this.labelFontSize = 11,
    this.valueColor,
    this.labelColor,
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
          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Stat(
              value: value is DateTime ? value.timeAgo : value is num ? value.toCommaString() : value.toString(),
              label: stat.label,
              valueFontSize: valueFontSize,
              labelFontSize: labelFontSize,
              valueColor: valueColor,
              labelColor: labelColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}
