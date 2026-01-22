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
    late final PlatformWebViewWidgetCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewWidgetCreationParams(
        controller: _controller.platform,
        displayWithHybridComposition: true,
      );
    } else {
      params = PlatformWebViewWidgetCreationParams(
        controller: _controller.platform,
      );
    }
    return MainScaffold(
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
      body: WebViewWidget.fromPlatformCreationParams(
        params: params
      )
    );
  }

}