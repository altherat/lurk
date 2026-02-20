import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/extensions.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';

class CustomHtml extends StatelessWidget {

  final Community activeCommunity;
  final String html;
  final Map<String, Size>? imageSizes;

  const CustomHtml({
    super.key,
    required this.activeCommunity,
    required this.html,
    this.imageSizes,
  });

  void _onLinkTap(BuildContext context, String url) => navigate(context, activeCommunity, url);

  void _onImageTap(BuildContext context, String url, [Size? size]) {
    context.push(() {
      return ImageViewerScreen(
        activeCommunity: activeCommunity,
        url: url,
        size: size
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      fontSize: 13,
      height: 1.25,
    );
    return ValueListenableBuilder(
      valueListenable: Settings.showCommentImages,
      builder: (context, showImages, child) {
        return HtmlWidget(
          html,
          rebuildTriggers: [showImages],
          textStyle: textStyle,
          onLoadingBuilder: (context, element, loadingProgress) {
            return Center(child: const CircularProgressIndicator());
          },
          customStylesBuilder: (element) {
            if (element.localName == 'p') {
              if (element.parent?.localName == 'blockquote') {
                return {
                  'margin-top': element.previousElementSibling == null ? '0' : '4px',
                  'margin-bottom': element.nextElementSibling == null ? '0' : '4px',
                };
              }
              return {
                'margin-top': '4px', 
                'margin-bottom': '4px', 
              };
            }
            if (element.localName == 'a') {
              final String linkColorCss = Constants.htmlLinkColor.toCss();
              return {
                'color': linkColorCss,
                'text-decoration-color': linkColorCss,
              };
            }
            if (element.localName == 'h1') {
              return {
                'font-size': '20px'
              };
            }
            if (element.localName == 'ul') {
              return {
                'margin': '0',
                'padding-left': '25px'
              };
            }
            if (element.localName == 'li') {
              return {
                'list-style-position': 'inside',
              };
            }
            if (element.localName == 'blockquote') {
              return {
                'margin': '0',
                'padding': '0 0 0 5px',
                'border-left': '1px solid ${Constants.htmlQuoteLineColor.toCss()}',
                // 'color': Constants.htmlQuoteTextColor.toCss(),
                'font-style': 'italic',
              };
            }
            return null;
          },
          customWidgetBuilder: (element) {
            if (element.localName == 'hr') {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 1,
                color: Constants.commentIndentColor,
              );
            }
            if (element.localName == 'img') {
              final String url = element.attributes['src']!;
              final imageSize = imageSizes?[url];
              if (showImages) {
                return _Image(
                  platform: activeCommunity.platform,
                  activeHost: activeCommunity.host,
                  url: url,
                  size: imageSize,
                  onTap: () => _onImageTap(context, url, imageSize)
                );
              }
              return _HtmlLink(
                placeholder: '[gif]',
                textStyle: textStyle,
                onTap: () => _onLinkTap(context, element.attributes['src']!),
              );
            }
            else if (element.localName == 'a') {
              final String url = element.attributes['href']!;
              final uri = Uri.tryParse(url)!;
              final host = uri.host;
              final imageSize = imageSizes?[url];
              if (host == 'preview.redd.it') {
                if (showImages) {
                  return _Image(
                    platform: activeCommunity.platform,
                    activeHost: activeCommunity.host,
                    url: url,
                    size: imageSize,
                    onTap: () => _onImageTap(context, url, imageSize)
                  );
                }
                return _HtmlLink(
                  placeholder: '[image]',
                  textStyle: textStyle,
                  onTap: () => _onLinkTap(context, url),
                );
              }
              if (host == 'giphy.com' || host == 'www.giphy.com') {
                if (showImages) {
                  final directGiphyUrl = getGiphyDirectUrl(url);
                  if (directGiphyUrl != null) {
                    return _Image(
                      platform: activeCommunity.platform,
                      activeHost: activeCommunity.host,
                      url: directGiphyUrl,
                      onTap: () => _onImageTap(context, directGiphyUrl)
                    );
                  }
                }
                return _HtmlLink(
                  placeholder: '[gif]',
                  textStyle: textStyle,
                  onTap: () => _onLinkTap(context, url),
                );
              }
            }
            return null;
          },
          onTapUrl: (url) {

            final communityName = activeCommunity.platform.getCommunityNameFromPath(url);
            if (communityName != null) {
              final communty = Community(
                platform: activeCommunity.platform,
                host: activeCommunity.host,
                name: communityName,
              );
              context.push(
                () => CommunityScreen(
                  activeCommunity: activeCommunity.platform.supportsMultipleHosts ? activeCommunity : communty,
                  community: communty
                ),
              );
              return true;
            }

            final userName = activeCommunity.platform.getUserNameFromPath(url);
            if (userName != null) {
              context.push(
                () => UserDetailsScreen(
                  activeCommunity: activeCommunity,
                  username: userName,
                ),
              );
              return true;
            }

            navigate(context, activeCommunity, url);
            return true;
          },
          onTapImage: (imageMetadata) {
            final url = imageMetadata.sources.firstOrNull?.url;
            if (url != null) {
              navigate(context, activeCommunity, url);
            }
          },
        );
      }
    );
  }

}

class _HtmlLink extends StatelessWidget {

  final String placeholder;
  final TextStyle textStyle;
  final VoidCallback onTap;

  const _HtmlLink({
    required this.placeholder,
    required this.textStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(right: 64),
          child: Text(
            placeholder,
            style: textStyle.copyWith(
              color: Constants.htmlLinkColor,
              decoration: TextDecoration.underline,
              decorationColor: Constants.htmlLinkColor,
            ),
          ),
        ),
      ),
    );
  }
  
}

class _Image extends StatelessWidget {

  final Platform platform;
  final String activeHost;
  final String url;
  final Size? size;
  final VoidCallback onTap;

  const _Image({
    required this.platform,
    required this.activeHost,
    required this.url,
    this.size,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.25;
    final double minWidth;
    final double maxWidth;
    final double minHeight;
    final BoxDecoration? outerContainerDecoration;
    if (size != null) {
      maxWidth = screenSize.width;
      minHeight = min(size!.height, maxHeight);
      minWidth = min(minHeight * size!.aspectRatio, maxWidth);
      outerContainerDecoration =  BoxDecoration(border: Border.all(color: Constants.commentIndentColor));
    }
    else {
      minWidth = 0;
      maxWidth = double.infinity;
      minHeight = 0;
      outerContainerDecoration = null;
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        decoration: outerContainerDecoration,
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
          minHeight: minHeight,
          maxHeight: maxHeight
        ),
        child: ExtendedImage.network(
          url,
          headers: {'User-Agent': platform.savedOrDefaultUserAgent},
          cacheHeight: (maxHeight * MediaQuery.devicePixelRatioOf(context)).round(),
          fit: BoxFit.contain,
          loadStateChanged: (state) {
            if (state.extendedImageLoadState == LoadState.loading) {
              return UnconstrainedBox(
                child: CustomCircularProgressIndicator(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                ),
              );
            }
            Widget child;
            if (state.extendedImageLoadState == LoadState.completed) {
              child = DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: Constants.commentIndentColor)),
                child: state.completedWidget,
              );
            }
            else {
              child = Icon(
                Icons.broken_image_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 32
              );
            }
            return Hero(
              tag: 'media_$url',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  child,
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onLongPress: () {
                          showSimpleOptionsBottomSheet(
                            context: context,
                            options: {
                              Text('Save image'): (context) {
                                saveImage(
                                  context: context,
                                  platform: platform,
                                  url: url
                                );
                              },
                              Text('View in browser'): (context) => openInBrowser(url),
                              Text('Copy link'): (context) => copyToClipboard(url)
                            }
                          );
                        },
                        onTap: onTap
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        ),
      ),
    );
  }

}