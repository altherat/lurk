import 'package:flutter/material.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/models/post.dart';
import 'package:lurk/screens/post_details.dart';
import 'package:lurk/widgets/main_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  late final WebViewController controller;
  late String? _title;

  @override
  void initState() {
    super.initState();
    _title = widget.post?.title;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) async {
            if (progress == 100) {
                final String? title = await controller.getTitle();
                if (mounted && title != null && title.isNotEmpty) {
                  setState(() {
                    _title = title;
                  });
                }
              }
          }
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: _title != null ? Text(_title!) : null,
      subtitle: Text(widget.url),
      popupMenuActions: {
        if (widget.post != null)
          'View comments': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  return PostDetailsScreen(
                    community: widget.community!,
                    post: widget.post,
                    url: widget.url
                  );
                }
              )
            );
          },
      'View in browser': () => openInBrowser(widget.url),
      'Copy link': () => copyToClipboard(widget.url)
      },
      body: WebViewWidget(
        controller: controller
      )
    );
  }

}