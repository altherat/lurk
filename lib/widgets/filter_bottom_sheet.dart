import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/settings.dart';

class FilterBottomSheet<T extends FeedOption> extends StatefulWidget {

  final Platform platform;
  final List<T> filters;
  final T? initialFilter;
  final Widget? Function(BuildContext context, T? selectedFilter)? additionalFilterBuilder;
  final Function(T filter) onFilterSelected;

  const FilterBottomSheet({
    super.key,
    required this.platform,
    required this.filters,
    required this.initialFilter,
    this.additionalFilterBuilder,
    required this.onFilterSelected
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState<T>();
  
}

class _FilterBottomSheetState<T extends FeedOption> extends State<FilterBottomSheet<T>> {

  late T? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      FilterSection(
        platform: widget.platform,
        header: 'Sort by',
        selected: _selectedFilter,
        filters: widget.filters,
        onSelected: (filter) {
          setState(() {
            _selectedFilter = filter;
          });
          widget.onFilterSelected(filter);
        }
      )
    ];
    if (widget.additionalFilterBuilder != null) {
      final Widget? child = widget.additionalFilterBuilder!(context, _selectedFilter);
      children.add(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: child != null
            ? Padding(
                padding: const EdgeInsets.only(top: 16),
                child: child
            )
            : const SizedBox(
                width: double.infinity,
                height: 0
              )
        )
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children
      ),
    );
  }

}

class FilterSection<T extends FeedOption> extends StatelessWidget {

  final Platform platform;
  final String header;
  final T? selected;
  final List<T> filters;
  final Function(T filter) onSelected;

  const FilterSection({
    super.key,
    this.selected,
    required this.platform,
    required this.header,
    required this.filters,
    required this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.only(bottom: 8),
          child: Text(
            header,
            style: TextStyle(
              fontSize: 16
            )
          )
        ),
        ValueListenableBuilder(
          valueListenable: Settings.showPlatformColorAccents,
          builder: (context, showPlatformColorAccents, child) {
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: filters.map((filter) {
                final Color? backgroundColor;
                final Color? foregroundColor;
                if (showPlatformColorAccents) {
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
        // SingleChildScrollView(
        //   scrollDirection: Axis.horizontal,
        //   child: Wrap(
        //     spacing: 8,
        //     children: filters.map((filter) {
        //       return ChoiceChip(
        //         label: Text(filter.label),
        //         selected: selected == filter,
        //         showCheckmark: false,
        //         onSelected: (selected) {
        //           if (selected) {
        //             onSelected(filter);
        //           }
        //         },
        //       );
        //     }).toList(),
        //   )
        // )
      ],
    );
  }

}