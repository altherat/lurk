import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/models/paged_items.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';
import 'package:lurk/widgets/icon_message.dart';

class FeedList<T> extends StatefulWidget {

  final Future<PagedItems<T>>? initialItems;
  final Future<PagedItems<T>> Function(String? pageToken) getItems;
  final Widget Function(BuildContext context) noItemsBuilder;
  final Widget? Function(BuildContext context, int index, T item) itemBuilder;

  const FeedList({
    super.key,
    this.initialItems,
    required this.getItems,
    required this.noItemsBuilder,
    required this.itemBuilder,
  });

  @override
  State<FeedList<T>> createState() => FeedListState<T>();

}

class FeedListState<T> extends State<FeedList<T>> with SingleTickerProviderStateMixin {

  late final AnimationController _animationController;
  LoadingState _loadingState = LoadingState.loading;
  List<T> items = [];
  String? _pageToken;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: Constants.feedLoadAnimationDuration
    );
    if (widget.initialItems != null) {
      _processItems(widget.initialItems!, (items) => this.items = items);
    }
    else {
      _getItems();
    }
  }

  Future<void> _getItems() => _processItems(widget.getItems(null), (items) => this.items = items);

  Future<void> _processItems(Future<PagedItems<T>> future, void Function(List<T> items) fn) async {
    try {
      final pagedItems = await future;
      if (!mounted) return;
      setState(() {
        fn(pagedItems.items);
        _pageToken = pagedItems.pageToken;
        _loadingState = LoadingState.success;
      });
      _animationController.forward();
    }
    catch (error, stackTrace) {
      dev.log('Failed to get items', error: error, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _loadingState = LoadingState.error);
      context.showSnackBarMessage('Something went wrong');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    _animationController.reset();
    setState(() {
      _loadingState = LoadingState.loading;
      items.clear();
      _pageToken = null;
    });
    return _getItems();
  }

  Future<void> refresh() => _getItems();

  void updateItems(Function(List<T> items) update) {
    setState(() => update(items));
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      if (_loadingState == LoadingState.loading) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: LargeCenteredCircularProgressIndicator()
        );
      }
      final Widget child;
      if (_loadingState == LoadingState.error) {
        child = const LargeVerticalIconMessage(
          icon: Icons.feed_outlined,
          message: 'Something went wrong'
        );
      }
      else {
        child = widget.noItemsBuilder(context);
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: child)
      );
    }
    return SliverPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      sliver: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: (_pageToken != null ? items.length + 1 : items.length),
              (context, index) {
                if (index == items.length) {
                  if (_loadingState != LoadingState.loading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _loadingState = LoadingState.loading;
                      });
                      _processItems(widget.getItems(_pageToken), (items) => this.items.addAll(items));
                    });
                  }
                  return CustomCircularProgressIndicator(
                    padding: EdgeInsets.all(16),
                    alignment: Alignment.center,
                    size: 24,
                  );
                }
                return _FeedItemTransition(
                  progress: _animationController.value,
                  child: widget.itemBuilder(context, index, items[index])!
                );
              }
            )
          );
        }
      ),
    );
  }

}

enum LoadingState {
  loading,
  error,
  success
}

class _FeedItemTransition extends StatelessWidget {

  final double progress;
  final Widget child;

  const _FeedItemTransition({
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = Curves.easeOut.transform(progress);
    final double slideProgress = const Cubic(0.05, 0.7, 0.1, 1.0).transform(progress);
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 50 * (1 - slideProgress)),
        child: child,
      )
    );
    // final double curveValue = Curves.easeInOutCubicEmphasized.transform(progress);
    // return Opacity(
    //   opacity: curveValue,
    //   child: Transform.translate(
    //     offset: Offset(0, 20 * (1 - curveValue)),
    //     child: child,
    //   ),
    // );
  }

}