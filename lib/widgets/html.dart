import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/image_viewer.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_circular_progress_indicator.dart';

class Html extends StatelessWidget {

  final Platform platform;
  final String html;

  const Html({
    super.key,
    required this.platform,
    required this.html,
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
                  url: url
                );
              }
              else if (element.localName == 'a') {
                final String url = element.attributes['href']!;
                if (Uri.tryParse(url)?.host == 'preview.redd.it') {
                  return _Image(
                    platform: platform,
                    url: url
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
            if (url.startsWith('/r/')) {
              context.push(
                () => PostsScreen(
                  community: Community(
                    platform: Platform.reddit,
                    name: Uri.parse(url).pathSegments[1].toLowerCase()
                  )
                )
              );
            }
            else if (url.startsWith('/u/')) {
              context.push(
                () => UserDetailsScreen(
                  platform: Platform.reddit,
                  username: Uri.parse(url).pathSegments[1].toLowerCase()
                )
              );
            }
            else {
              navigate(context, platform, url);
            }
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
    super.key,
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

  const _Image({
    super.key,
    required this.platform,
    required this.url
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.25;
    return Align(
      alignment: Alignment.topLeft,
      child: ExtendedImage.network(
        url,
        headers: {'User-Agent': platform.api.savedOrDefaultUserAgent},
        cacheHeight: (maxHeight * MediaQuery.devicePixelRatioOf(context)).round(),
        fit: BoxFit.contain,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 8
                ),
                child: PlatformCircularProgressIndicator(
                  platform: platform,
                  strokeWidth: 4
                ),
              );
            case LoadState.completed:
              return Stack(
                children: [
                  Container(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    decoration: BoxDecoration(border: Border.all(color: Constants.commentIndentColor)),
                    child: state.completedWidget,
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onLongPress: () {
                          showSimpleTextOptionsBottomSheet(
                            context: context,
                            options: {
                              'Save image': () {}, //TODO
                              'View in browser': () => openInBrowser(url),
                              'Copy link': () => copyToClipboard(url)
                            }
                          );
                        },
                        onTap: () {
                          context.push(() {
                            return ImageViewerScreen(
                              platform: platform,
                              url: url
                            );
                          });
                        }
                      ),
                    ),
                  )
                ],
              );
            case LoadState.failed:
              return const Icon(
                Icons.broken_image_rounded,
                color: Constants.secondaryTextColor
              );
          }
        }
      ),
    );
  }

}