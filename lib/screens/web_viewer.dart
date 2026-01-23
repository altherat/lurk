import 'package:flutter/material.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebViewerScreen extends StatefulWidget {

  final String url;
  final Community? community;
  final Post? post;

  const WebViewerScreen({
    super.key,
    required this.url,
    this.community,
    this.post
  });

  @override
  State<WebViewerScreen> createState() => _WebViewerScreenState();

}

class _WebViewerScreenState extends State<WebViewerScreen> {

  late final WebViewController _controller;
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
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          setState(() => _isExiting = true);
        }
      },
      child: MainScaffold(
        title: _title != null ? Text(_title!) : null,
        subtitle: Text(widget.url),
        popupMenuActions: {
          if (widget.post != null)
            'View comments': () {
              context.push(
                () => PostDetailsScreen(
                  community: widget.community!,
                  post: widget.post,
                  url: widget.url
                )
              );
            },
        'View in browser': () => openInBrowser(widget.url),
        'Copy link': () => copyToClipboard(widget.url)
        },
        body: _isExiting
          ? const SizedBox.shrink()
          : _WebView(
              controller: _controller,
              url: widget.url,
              community: widget.community,
              post: widget.post,
            )
      )
    );
  }

}

class _WebView extends StatefulWidget {

  final WebViewController controller;
  final String url;
  final Community? community;
  final Post? post;

  const _WebView({
    super.key,
    required this.controller,
    required this.url,
    required this.community,
    required this.post,
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