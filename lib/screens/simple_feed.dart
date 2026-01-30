import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/widgets/centered_full_height_scroll_view.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/icon_message.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class SimpleFeedScreen<T, U> extends StatefulWidget {

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Platform platform;
  final String? activeCommunityName;
  final FeedOptionsGroup? feedOptions;
  final bool showDefaultFeedOptionsInSubtitle;
  final FeedResponse<T, U> Function(Map<FeedOptionType, FeedOption>? feedOptions)? getAll;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final Widget title;
  final Widget? subtitle;
  final List<Widget> Function(BuildContext context, LoadingState loadingState, U? otherData)? headersBuilder;
  final Widget? Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;

  const SimpleFeedScreen({
    super.key,
    this.scaffoldKey,
    required this.platform,
    this.activeCommunityName,
    this.feedOptions,
    this.showDefaultFeedOptionsInSubtitle = false,
    this.getAll,
    required this.getItems,
    required this.title,
    this.subtitle,
    this.headersBuilder,
    required this.itemBuilder,
    required this.noItemsBuilder,
  });

  @override
  State<SimpleFeedScreen<T, U>> createState() => _SimpleFeedScreenState<T, U>();

}

class _SimpleFeedScreenState<T, U> extends State<SimpleFeedScreen<T, U>> {

  final _contentKey = GlobalKey<_ContentState>();
  Map<FeedOptionType, FeedOption>? _feedOptions;

  @override
  Widget build(BuildContext context) {
  final subtitleFeedOptions = _feedOptions ?? (widget.showDefaultFeedOptionsInSubtitle ? widget.feedOptions?.defaults : null);
    return MainScaffold(
      scaffoldKey: widget.scaffoldKey,
      platform: widget.platform,
      activeCommunityName: widget.activeCommunityName,
      feedOptions: widget.feedOptions,
      title: widget.title,
      subtitle: subtitleFeedOptions != null ? Text(subtitleFeedOptions.values.map((o) => o.description.toLowerCase()).join(' / ')) : widget.subtitle,
      selectedFeedOptions: _feedOptions,
      useSlivers: true,
      onFeedOptionsSelected: (options) {
        setState(() {
          _feedOptions = mapEquals(options, widget.feedOptions!.defaults) ? null : options;
        });
      },
      body: _Content<T, U>(
        key: _contentKey,
        platform: widget.platform,
        feedOptions: _feedOptions,
        getAll: widget.getAll,
        getItems: widget.getItems,
        headersBuilder: widget.headersBuilder,
        itemBuilder: widget.itemBuilder,
        noItemsBuilder: widget.noItemsBuilder,
      ),
      onRefresh: () => _contentKey.currentState?._refresh(),
    );
  }

}

class _Content<T, U> extends StatefulWidget {

  final Platform platform;
  final Map<FeedOptionType, FeedOption>? feedOptions;
  final FeedResponse<T, U> Function(Map<FeedOptionType, FeedOption>? feedOptions)? getAll;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final List<Widget> Function(BuildContext context, LoadingState loadingState, U? otherData)? headersBuilder;
  final Widget? Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;

  const _Content({
    super.key,
    required this.platform,
    required this.feedOptions,
    required this.getAll,
    required this.getItems,
    required this.headersBuilder,
    required this.itemBuilder,
    required this.noItemsBuilder,
  });

  @override
  State<_Content<T, U>> createState() => _ContentState<T, U>();

}

class _ContentState<T, U> extends State<_Content<T, U>> {

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  List<T> _items = [];
  U? _otherData;
  String? _pageToken;
  LoadingState _loadingState = LoadingState.loading;
  LoadingState _otherDataLoadingState = LoadingState.loading;

  @override
  void initState() {
    super.initState();
    _get();
  }

  @override
  void didUpdateWidget(covariant _Content<T, U> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(widget.feedOptions, oldWidget.feedOptions)) {
      _items.clear();
      _setLoading();
      _get();
    }
  }

  void _setLoading() {
    setState(() {
      _loadingState = LoadingState.loading;
      _otherDataLoadingState = LoadingState.loading;
    });
  }

  Future<void> _get() {
    final List<Future> futures = [];
    if (widget.getAll != null) {
      final response = widget.getAll!(widget.feedOptions);
      futures.add(
        response.items
          .then((result) {
            if (!mounted) return;
            setState(() {
              _items = result.items;
              _pageToken = result.pageToken;
              _loadingState = LoadingState.success;
            });
          })
          .onError(_onItemsError)
      );
      if (response.other != null) {
        futures.add(
          response.other!
            .then((other) {
              if (!mounted) return;
              setState(() {
                _otherData = other;
                _otherDataLoadingState = LoadingState.success;
              });
            })
            .onError((exception, stackTrace) {
              if (_onError(exception, stackTrace)) {
                setState(() {
                  _otherDataLoadingState = LoadingState.error;
                });
              }
            })
        );
      }
    }
    else {
      futures.add(
        widget.getItems(widget.feedOptions, null)
          .then((result) {
            if (!mounted) return;
            setState(() {
              _items = result.items;
              _pageToken = result.pageToken;
              _loadingState = LoadingState.success;
            });
          })
          .onError(_onItemsError)
      );
    }
    return Future.wait(futures);
  }

  void _getMore() {
    _loadingState = LoadingState.loading;
    widget.getItems(widget.feedOptions, _pageToken)
      .then((response) {
        if (!mounted) return;
        setState(() {
          _items.addAll(response.items);
          _pageToken = response.pageToken;
          _loadingState = LoadingState.success;
        });
      })
      .onError(_onItemsError);
  }

  Future<Null> _onItemsError(dynamic exception, dynamic stackTrace) {
    if (_onError(exception, stackTrace)) {
      setState(() {
        _loadingState = LoadingState.error;
      });
      if (_items.isNotEmpty) {
        context.showSnackBarMessage('Something went wrong');
      }
    }
    throw exception;
  }

  bool _onError(dynamic exception, dynamic stackTrace) {
    dev.log('Error fetching feed: $exception');
    dev.log(stackTrace.toString());
    return mounted;
  }

  Future<void> _refresh() async {
    if (_items.isEmpty) {
      _get();
    }
    else {
      _refreshIndicatorKey.currentState?.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_items.isEmpty) {
      if (_otherData == null) {
        return LargeCenteredCircularProgressIndicator(platform: widget.platform);
      }
      child = CenteredFullHeightScrollView(
        headers: widget.headersBuilder?.call(context, _otherDataLoadingState, _otherData),
        child: _loadingState == LoadingState.error
          ? const LargeVerticalIconMessage(
              icon: Icons.feed_outlined,
              message: 'Something went wrong'
            )
          : _loadingState == LoadingState.loading
            ? LargeCenteredCircularProgressIndicator(platform: widget.platform)
            : widget.noItemsBuilder(context)
      );
    }
    else {
      final headers = widget.headersBuilder?.call(context, _otherDataLoadingState, _otherData) ?? [];
      child = NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (_loadingState != LoadingState.loading && _pageToken != null && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _getMore();
          }
          return false;
        },
        child: Scrollbar(
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            itemCount: headers.length + (_pageToken != null ? _items.length + 1 : _items.length),
            itemBuilder: (context, index) {
              if (index < headers.length) {
                return headers[index];
              }
              final itemIndex = index - headers.length;
              if (_pageToken != null && itemIndex == _items.length) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: PlatformCircularProgressIndicator(
                        platform: widget.platform,
                        strokeWidth: 3
                      )
                    )
                  ),
                );
              }
              return widget.itemBuilder(context, _items[itemIndex]) ?? const SizedBox.shrink();
            }
          )
        ),
      );
    }
    return CustomRefreshIndicator(
      platform: widget.platform,
      flutterRefreshIndicatorKey: _refreshIndicatorKey,
      onRefresh: () {
        _setLoading();
        return _get();
      },
      child: child
    );
  }

}

enum LoadingState {
  loading,
  error,
  success
}