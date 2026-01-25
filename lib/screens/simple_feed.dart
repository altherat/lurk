import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/services/api/api.dart';
import 'package:lurk/widgets/centered_large_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/main_scaffold.dart';

class SimpleFeedScreen<R extends FeedResponse<T>, T> extends StatefulWidget {

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Platform platform;
  final String? activeCommunityName;
  final FeedOptionsGroup? feedOptions;
  final bool showDefaultFeedOptionsInSubtitle;
  final R Function(Map<FeedOptionType, FeedOption>? feedOptions)? getAll;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final Widget title;
  final List<Widget> Function(BuildContext context, R? response)? headersBuilder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? Function(BuildContext context) noItemsBuilder;

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
    this.headersBuilder,
    required this.itemBuilder,
    required this.noItemsBuilder,
  });

  @override
  State<SimpleFeedScreen<R, T>> createState() => _SimpleFeedScreenState<R, T>();

}

class _SimpleFeedScreenState<R extends FeedResponse<T>, T> extends State<SimpleFeedScreen<R, T>> {

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
      subtitle: subtitleFeedOptions != null ? Text(subtitleFeedOptions.values.map((o) => o.description.toLowerCase()).join(' / ')) : null,
      selectedFeedOptions: _feedOptions,
      useSlivers: true,
      onFeedOptionsSelected: (options) {
        setState(() {
          _feedOptions = mapEquals(options, widget.feedOptions!.defaults) ? null : options;
        });
      },
      body: _Content<R, T>(
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

class _Content<R extends FeedResponse<T>, T> extends StatefulWidget {

  final Platform platform;
  final Map<FeedOptionType, FeedOption>? feedOptions;
  final R Function(Map<FeedOptionType, FeedOption>? feedOptions)? getAll;
  final Future<PagedResult<T>> Function(Map<FeedOptionType, FeedOption>? feedOptions, String? pageToken) getItems;
  final List<Widget> Function(BuildContext context, R? response)? headersBuilder;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? Function(BuildContext context) noItemsBuilder;

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
  State<_Content<R, T>> createState() => _ContentState<R, T>();

}

class _ContentState<R extends FeedResponse<T>, T> extends State<_Content<R, T>> {

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  R? _response;

  List<T> _items = [];
  String? _pageToken;
  bool _isLoadingItems = true;
  bool _isLoadingMoreItems = false;

  @override
  void initState() {
    super.initState();
    _get();
  }

  @override
  void didUpdateWidget(covariant _Content<R, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(widget.feedOptions, oldWidget.feedOptions)) {
      setState(() {
        _items.clear();
        _isLoadingItems = true;
      });
      _get();
    }
  }

  Future<void> _get() async {
    if (_items.isEmpty) {
      setState(() {
        _isLoadingItems = true;
      });
    }
    try {
      final PagedResult<T> itemsResult;
      if (widget.getAll != null) {
        _response = widget.getAll!(widget.feedOptions);
        itemsResult = await _response!.items;
      }
      else {
        itemsResult = await widget.getItems(widget.feedOptions, null);
      }
      if (mounted) {
        setState(() {
          _items = itemsResult.items;
          _pageToken = itemsResult.pageToken;
          _isLoadingItems = false;
        });
      }
    }
    catch (e, stackTrace) {
      debugPrint('Error loading feed: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        setState(() => _isLoadingItems = false);
      }
    }
  }

  Future<void> _getMore() async {
    _isLoadingMoreItems = true;
    try {
      final response = await widget.getItems(widget.feedOptions, _pageToken);
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
    _isLoadingMoreItems = false;
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
    if (_isLoadingItems) {
      return CenteredLargeCircularProgressIndicator(platform: widget.platform);
    }
    final headers = widget.headersBuilder?.call(context, _response) ?? [];
    return CustomRefreshIndicator(
      platform: widget.platform,
      flutterRefreshIndicatorKey: _refreshIndicatorKey,
      onRefresh: _get,
      child: _items.isEmpty
        ? Column(
            children: [
              ...headers,
              Expanded(child: Center(child: widget.noItemsBuilder(context)))
            ],
        )
        : NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (!_isLoadingMoreItems && _pageToken != null && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
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
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CustomCircularProgressIndicator(strokeWidth: 3)
                        )
                      ),
                    );
                  }
                  return widget.itemBuilder(context, _items[itemIndex]);
                }
              )
            ),
        )
    );
  }

}