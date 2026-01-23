import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/models/paged_result.dart';
import 'package:lurk/widgets/centered_large_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class FeedScreen<T> extends StatefulWidget {

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Platform platform;
  final String? activeCommunityName;
  final FeedOptionsGroup? feedOptions;
  final Widget title;
  final Widget? subtitle;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) get;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;

  const FeedScreen({
    super.key,
    this.scaffoldKey,
    required this.platform,
    this.activeCommunityName,
    this.feedOptions,
    required this.title,
    this.subtitle,
    required this.get,
    required this.itemBuilder,
    required this.noItemsBuilder,
  });

  @override
  State<FeedScreen<T>> createState() => _FeedScreenState<T>();

}

class _FeedScreenState<T> extends State<FeedScreen<T>> {

  final _contentKey = GlobalKey<_ContentState>();
  Map<FeedOptionType, FeedOption>? _feedOptions;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      scaffoldKey: widget.scaffoldKey,
      platform: widget.platform,
      activeCommunityName: widget.activeCommunityName,
      feedOptions: widget.feedOptions,
      title: widget.title,
      subtitle: widget.subtitle ?? (_feedOptions != null ? Text(_feedOptions!.values.map((option) => option.description.toLowerCase()).join(' / ')) : null),
      selectedFeedOptions: _feedOptions,
      useSlivers: true,
      onFeedOptionsSelected: (options) {
        setState(() {
          _feedOptions = mapEquals(options, widget.platform.postsFeedOptions.defaults) ? null : options;
        });
      },
      body: _Content<T>(
        key: _contentKey,
        platform: widget.platform,
        feedOptions: _feedOptions,
        get: widget.get,
        itemBuilder: widget.itemBuilder,
        noItemsBuilder: widget.noItemsBuilder,
      ),
      onRefresh: () => _contentKey.currentState?._refresh(),
    );
  }

}

class _Content<T> extends StatefulWidget {

  final Platform platform;
  final Map<FeedOptionType, FeedOption>? feedOptions;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) get;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget Function(BuildContext context) noItemsBuilder;

  const _Content({
    super.key,
    required this.platform,
    required this.feedOptions,
    required this.get,
    required this.itemBuilder,
    required this.noItemsBuilder,
  });

  @override
  State<_Content<T>> createState() => _ContentState<T>();

}

class _ContentState<T> extends State<_Content<T>> {

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  List<T> _items = [];
  String? _pageToken;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _get();
  }

  @override
  void didUpdateWidget(covariant _Content<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(widget.feedOptions, oldWidget.feedOptions)) {
      setState(() {
        _items.clear();
        _isLoading = true;
      });
      _get();
    }
  }

  Future<void> _get() async {
    if (_items.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final response = await widget.get(widget.feedOptions, null);
      if (mounted) {
        setState(() {
          _items = response.items;
          _pageToken = response.pageToken;
          _isLoading = false;
        });
      }
    }
    catch (e, stackTrace) {
      debugPrint('Error loading feed: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getMore() async {
    _isLoadingMore = true;
    try {
      final response = await widget.get(widget.feedOptions, _pageToken);
      if (mounted) {
        setState(() {
          _items.addAll(response.items);
          _pageToken = response.pageToken;
        });
      }
    }
    catch (e) {
      debugPrint('Error loading more feed: $e');
    }
    _isLoadingMore = false;
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
    if (_isLoading) return CenteredLargeCircularProgressIndicator(platform: widget.platform);
    return CustomRefreshIndicator(
      flutterRefreshIndicatorKey: _refreshIndicatorKey,
      platform: widget.platform,
      onRefresh: _get,
      child: _items.isEmpty
        ? widget.noItemsBuilder(context)
        : NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (!_isLoadingMore && _pageToken != null && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                _getMore();
              }
              return false;
            },
            child: Scrollbar(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                itemCount: _pageToken != null ? _items.length + 1 : _items.length,
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CustomCircularProgressIndicator(
                            platform: widget.platform,
                            strokeWidth: 3
                          )
                        )
                      ),
                    );
                  }
                  return widget.itemBuilder(context, _items[index]);
                }
              )
            ),
        )
    );
  }

}