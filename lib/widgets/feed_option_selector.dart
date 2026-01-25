import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class FeedOptionSelector extends StatelessWidget {

  final Platform platform;
  final String? header;
  final List<FeedOption> options;
  final FeedOption? selected;
  final Function(FeedOption) onSelected;

  const FeedOptionSelector({
    super.key,
    required this.platform,
    this.header,
    required this.options,
    this.selected,
    required this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: EdgeInsetsGeometry.only(bottom: 4),
            child: Text(
              header!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              )
            )
          ),
        ValueListenableBuilder(
          valueListenable: Settings.showMorePlatformColorAccents,
          builder: (context, showMorePlatformColorAccents, child) {
            return Wrap(
              spacing: Constants.choiceChipGapSize,
              runSpacing: Constants.choiceChipGapSize / 2,
              children: options.map((filter) {
                final Color? backgroundColor;
                final Color? foregroundColor;
                if (showMorePlatformColorAccents) {
                  backgroundColor = platform.color;
                  foregroundColor = Colors.white;
                }
                else {
                  backgroundColor = null;
                  foregroundColor = null;
                }
                return ChoiceChip(
                  label: Text(filter.label),
                  selected: selected == filter,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: foregroundColor),
                  color: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.selected) || states.contains(WidgetState.pressed) ? backgroundColor : null),
                  onSelected: (selected) {
                    if (selected) {
                      onSelected(filter);
                    }
                  },
                );
              }).toList(),
            );
          }
        )
      ],
    );
  }

}