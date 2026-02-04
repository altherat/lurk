import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
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
          valueListenable: Settings.showPlatformColorAccents,
          builder: (context, showPlatformColorAccents, child) {
            return Wrap(
              spacing: Constants.choiceChipGapSize,
              runSpacing: Constants.choiceChipGapSize / 2,
              children: options.map((filter) {
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
      ],
    );
  }

}

class FeedFilterIconButton extends StatelessWidget {

  final Platform platform;
  final FeedOptionsGroup? feedOptions;
  final Map<FeedOptionType, FeedOption>? selectedFeedOptions;
  final Function(Map<FeedOptionType, FeedOption>) onFeedOptionsSelected;

  const FeedFilterIconButton({
    super.key,
    required this.platform,
    required this.feedOptions,
    required this.selectedFeedOptions,
    required this.onFeedOptionsSelected
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Filter',
      iconSize: 26,
      onPressed: feedOptions != null
        ? () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FeedOptionsSelector(
                      platform: platform,
                      optionsGroup: feedOptions!,
                      selected: selectedFeedOptions,
                      onSelected: (options) {
                        onFeedOptionsSelected(options);
                        context.pop();
                      }
                    ),
                  ),
                );
              }
            );
          }
        : null,
    );
  }

}

class _FeedOptionsSelector extends StatefulWidget {

  final Platform platform;
  final FeedOptionsGroup optionsGroup;
  final Map<FeedOptionType, FeedOption>? selected;
  final Function(Map<FeedOptionType, FeedOption>) onSelected;

  const _FeedOptionsSelector({
    super.key,
    required this.platform,
    required this.optionsGroup,
    required this.selected,
    required this.onSelected
  });

  @override
  State<_FeedOptionsSelector> createState() => _FeedOptionsSelectorState();
  
}

class _FeedOptionsSelectorState extends State<_FeedOptionsSelector> {

  late final List<(FeedOptionType, FeedOption)> _selected;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _selected = widget.selected!.entries.map((entry) => (entry.key, entry.value)).toList();
    }
    else {
      // _selected = [(widget.optionsGroup.type, widget.optionsGroup.options.first)];
      _selected = [];
      void addDefaultSelection(FeedOptionsGroup group) {
        final firstOption = group.options.first;
        _selected.add((group.type, firstOption));
        if (firstOption.subGroup != null) {
          addDefaultSelection(firstOption.subGroup!);
        }
      }
      addDefaultSelection(widget.optionsGroup);
    }
  }

  void _onOptionSelected(int index, FeedOptionType feedOptionType, FeedOption option) {
    if (_selected.length > index) {
      _selected.removeRange(index, _selected.length);
    }
    _selected.add((feedOptionType, option));
    if (option.subGroup != null) {
      setState(() {});
    }
    else {
      widget.onSelected({for (var item in _selected) item.$1: item.$2});
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FeedOptionsGroup> toShow = [widget.optionsGroup];
    for (var selection in _selected) {
      final option = selection.$2;
      if (option.subGroup != null) {
        toShow.add(option.subGroup!);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(toShow.length, (index) {
          final group = toShow[index];
          return _AnimatedRow(
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, index == 0 ? 0 : 16, 32, 0),
              child: FeedOptionSelector(
                platform: widget.platform,
                header: group.type.label,
                options: group.options,
                selected: _selected.length > index ? _selected[index].$2 : null,
                onSelected: (option) => _onOptionSelected(index, group.type, option),
              ),
            ),
          );
        }),
      ]
    );
  }

}

class _AnimatedRow extends StatefulWidget {

  final Widget child;
  const _AnimatedRow({
    super.key, 
    required this.child
  });

  @override
  State<_AnimatedRow> createState() => _AnimatedRowState();

}

class _AnimatedRowState extends State<_AnimatedRow> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _animation,
        child: widget.child
      ),
    );
  }

}