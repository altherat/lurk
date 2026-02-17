import 'package:flutter/material.dart';
import 'package:lurk/core/collection_listenable/collection_listenable.dart';

class CollectionListenableBuilder<T, R> extends StatefulWidget {

  final T id;
  final CollectionListenable<T, R> collectionListenable;
  final Widget Function(BuildContext context, R value) builder;

  const CollectionListenableBuilder({
    super.key, 
    required this.id, 
    required this.collectionListenable, 
    required this.builder
  });

  @override
  State<CollectionListenableBuilder<T, R>> createState() => _CollectionListenableBuilderState<T, R>();

}

class _CollectionListenableBuilderState<T, R> extends State<CollectionListenableBuilder<T, R>> {

  late R _value;

  @override
  void initState() {
    super.initState();
    _value = widget.collectionListenable.value(widget.id);
    widget.collectionListenable.addListener(widget.id, _onChange);
  }

  @override
  void dispose() {
    widget.collectionListenable.removeListener(widget.id, _onChange);
    super.dispose();
  }

  @override
  void didUpdateWidget(CollectionListenableBuilder<T, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id || widget.collectionListenable != oldWidget.collectionListenable) {
      oldWidget.collectionListenable.removeListener(oldWidget.id, _onChange);
      widget.collectionListenable.addListener(widget.id, _onChange);
      _value = widget.collectionListenable.value(widget.id);
    }
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {
      _value = widget.collectionListenable.value(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
  
}