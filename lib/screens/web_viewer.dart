import 'package:flutter/material.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebViewerScreen extends StatefulWidget {

  final Platform platform;
  final String url;
  final Post? post;

  const WebViewerScreen({
    super.key,
    required this.platform,
    required this.url,
    this.post,
  });

  @override
  State<WebViewerScreen> createState() => _WebViewerScreenState();

}

class _WebViewerScreenState extends State<WebViewerScreen> {

  late final WebViewController _controller;
  final _progressNotifier = ValueNotifier(0.0);
  late String? _title;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _title = widget.post?.title;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) async {
            _progressNotifier.value = progress / 100;
            if (progress == 100) {
                final String? title = await _controller.getTitle();
                if (mounted && title != null && title.isNotEmpty) {
                  setState(() {
                    _title = title;
                  });
                }
              }
          }
        ),
      );
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _progressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          setState(() => _isExiting = true);
        }
      },
      child: MainScaffold(
        platform: widget.platform,
        title: _title != null ? Text(_title!) : null,
        subtitle: Text(widget.url),
        iconActions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.reload,
          )
        ],
        popupMenuActions: {
          if (widget.post != null)
            Text('View comments'): (context) => context.push(() => PostDetailsScreen.fromPost(post: widget.post!)),
          Text('View in browser'): (context) => openInBrowser(widget.url),
          Text('Copy link'): (context) => copyToClipboard(widget.url)
        },
        body: _isExiting
          ? const SizedBox.shrink()
          : Stack(
              children: [
                _WebView(controller: _controller),
                ValueListenableBuilder(
                  valueListenable: _progressNotifier,
                  builder: (context, progress, child) {
                    if (progress == 1) {
                      return SizedBox.shrink();
                    }
                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(10),
                    );
                  }
                )
              ],
          )
      )
    );
  }

}

class _WebView extends StatefulWidget {

  final WebViewController controller;

  const _WebView({
    required this.controller,
  });

  @override
  State<_WebView> createState() => _WebViewState();

}

class _WebViewState extends State<_WebView> {

  @override
  Widget build(BuildContext context) {
    final PlatformWebViewWidgetCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewWidgetCreationParams(
        controller: widget.controller.platform,
        displayWithHybridComposition: true,
      );
    }
    else {
      params = PlatformWebViewWidgetCreationParams(
        controller: widget.controller.platform,
      );
    }
    return WebViewWidget.fromPlatformCreationParams(params: params);
  }

}