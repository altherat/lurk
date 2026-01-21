import 'package:flutter/material.dart';
import 'package:lurk/services/history.dart';

class HistoryBuilder extends StatefulWidget {

  final String id;
  final History history;
  final Widget Function(BuildContext context, bool isVisited) builder;

  const HistoryBuilder({
    super.key, 
    required this.id, 
    required this.history, 
    required this.builder
  });

  @override
  State<HistoryBuilder> createState() => _HistoryBuilderState();

}

class _HistoryBuilderState extends State<HistoryBuilder> {

  late final HistoryNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = widget.history.getNotifier(widget.id);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _notifier,
      builder: (context, value, _) => widget.builder(context, value),
    );
  }
  
}