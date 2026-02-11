import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/screens/community.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_progress_indicators.dart';

class CustomHtml extends StatelessWidget {

  final Platform platform;
  final String html;
  final Map<String, Size>? imageSizes;

  const CustomHtml({
    super.key,
    required this.platform,
    required this.html,
    this.imageSizes,
  });

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
            if (showImages) {
              if (element.localName == 'img') {
                final String url = element.attributes['src']!;
                return _Image(
                  platform: platform,
                  url: url,
                  size: imageSizes?[url]
                );
              }
              else if (element.localName == 'a') {
                final String url = element.attributes['href']!;
                if (Uri.tryParse(url)?.host == 'preview.redd.it') {
                  return _Image(
                    platform: platform,
                    url: url,
                    size: imageSizes?[url]
                  );
                }
              }
            }
            else if (element.localName == 'img') {
              return _HtmlLink(
                platform: platform,
                url: element.attributes['src']!,
                placeholder: '[gif]',
                textStyle: textStyle
              );
            }
            else if (element.localName == 'a') {
              final String url = element.attributes['href']!;
              if (Uri.tryParse(url)?.host == 'preview.redd.it') {
                return _HtmlLink(
                  platform: platform,
                  url: url,
                  placeholder: '[image]',
                  textStyle: textStyle
                );
              }
            }
            return null;
          },
          onTapUrl: (url) {

            final communityName = platform.getCommunityNameFromPath(url);
            if (communityName != null) {
              context.push(
                () => CommunityScreen(
                  community: Community(
                    platform: platform,
                    name: communityName.toLowerCase(),
                  ),
                ),
              );
              return true;
            }

            final userName = platform.getUserNameFromPath(url);
            if (userName != null) {
              context.push(
                () => UserDetailsScreen(
                  platform: platform,
                  username: userName.toLowerCase(),
                ),
              );
              return true;
            }

            navigate(context, platform, url);
            return true;
          },
          onTapImage: (imageMetadata) {
            final url = imageMetadata.sources.firstOrNull?.url;
            if (url != null) {
              navigate(context, platform, url);
            }
          },
        );
      }
    );
  }

}

class _HtmlLink extends StatelessWidget {

  final Platform platform;
  final String url;
  final String placeholder;
  final TextStyle textStyle;

  const _HtmlLink({
    required this.platform,
    required this.url,
    required this.placeholder,
    required this.textStyle
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: () => navigate(context, platform, url),
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
  final String url;
  final Size? size;

  const _Image({
    required this.platform,
    required this.url,
    required this.size
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
          headers: {'User-Agent': platform.api.savedOrDefaultUserAgent},
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
              child = const Icon(
                Icons.broken_image_rounded,
                color: Constants.secondaryTextColor,
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
                          showSimpleTextOptionsBottomSheet(
                            context: context,
                            options: {
                              'Save image': () {
                                saveImage(
                                  context: context,
                                  platform: platform,
                                  url: url
                                );
                              },
                              'View in browser': () => openInBrowser(url),
                              'Copy link': () => copyToClipboard(url)
                            }
                          );
                        },
                        onTap: () {
                          context.push(() {
                            return ImageViewerScreen(
                              platform: platform,
                              url: url,
                              size: size
                            );
                          });
                        }
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