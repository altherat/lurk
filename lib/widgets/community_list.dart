import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/screens/posts.dart';
import 'package:lurk/screens/search.dart';
import 'package:lurk/screens/user_details.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_refresh_indicator.dart';
import 'package:lurk/widgets/custom_search_bar.dart';
import 'package:lurk/widgets/prefixed_community_name.dart';

class CommunityList extends StatefulWidget {

  final Platform platform;
  final String? activeCommunityName;
  final EdgeInsetsGeometry? padding;
  final void Function(bool isActive)? onCommunitySelected;

  const CommunityList({
    super.key,
    required this.platform,
    required this.activeCommunityName,
    this.padding,
    required this.onCommunitySelected
  });

  @override
  State<CommunityList> createState() => _CommunityListState();

}

class _CommunityListState extends State<CommunityList> {

  static final RegExp _searchNameAllowedRegex = RegExp(
    '[a-zA-Z0-9${
      F.appFlavor.platforms
      .expand((platform) => hexEscape('${platform.communityPrefix}${platform.userPrefix}${platform.communityNameAllowedChars}${platform.userNameAllowedChars}'))
      .toSet()
      .join()
    }]'
  );

  final TextEditingController _searchController = TextEditingController();
  late List<Community> _visibleCommunities;
  final FocusNode _searchBarFocusNode = FocusNode();
  late Platform _searchPlatform;
  late SearchType _searchType;
  String _searchQuery = '';
  String? _searchBarPrefixText;
  late String _searchBarHint;
  bool _isSearchBarFocused = false;
  bool _isSearchValid = false;

  @override
  void initState() {
    super.initState();
    _visibleCommunities = Settings.communities.value.toList();
    _searchPlatform = widget.platform;
    _searchType = Settings.searchType.value ?? SearchType.community;
    _updateSearchBarTexts();
    _searchBarFocusNode.addListener(_onSearchBarFocusChanged);
    Settings.communities.addListener(_onCommunitiesSettingChanged);
    _sortVisibleCommunities();
  }

  @override
  void dispose() {
    _searchBarFocusNode.removeListener(_onSearchBarFocusChanged);
    _searchController.dispose();
    _searchBarFocusNode.dispose();
    super.dispose();
  }

  void _onCommunitiesSettingChanged() {
    if (!mounted) return;
    setState(() {
      _updateVisibleCommunities();
      _sortVisibleCommunities();
    });
  }

  void _updateVisibleCommunities() {
    _visibleCommunities = (_searchQuery.isEmpty ? Settings.communities.value : Settings.communities.value.where((community) => community.name?.contains(_searchQuery) ?? false)).toList();
  }

  void _sortVisibleCommunities() {
    _visibleCommunities.sort((c1, c2) {
      if (c1.isFavorite != c2.isFavorite) return c1.isFavorite ? -1 : 1;
      return (c1.name ?? '').compareTo((c2.name ?? ''));
    });
  }

  void _onSearchBarFocusChanged() {
    setState(() {
      _isSearchBarFocused = _searchBarFocusNode.hasFocus;
      if (_searchType != SearchType.all) {
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchBarHint.toLowerCase() : _searchBarHint.toTitleCase();
      }
    });
  }

  void _navigateToCommunity(Community community) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => PostsScreen(community: community)),
      (route) => route.isFirst
    );
  }

  void _onCommunityTap(Community community) {
    if (community.platform == widget.platform && community.name == (widget.activeCommunityName ?? widget.platform.homeCommunity)) {
      context.pop();
      widget.onCommunitySelected?.call(true);
      return;
    }
    widget.onCommunitySelected?.call(false);
    _navigateToCommunity(community);
  }

  void _cyclePlatform() {

    setState(() {
      _searchPlatform = Platform.values[(Platform.values.indexOf(_searchPlatform) + 1) % Platform.values.length];
      _updateSearchBarTexts();
      _updateIsSearchValid();
    });
  }

  void _cycleSearchType() {
    setState(() {
      _updateSearchType(SearchType.values[(SearchType.values.indexOf(_searchType) + 1) % SearchType.values.length]);
      _updateSearchBarTexts();
      _updateIsSearchValid();
    });
  }

  void _updateSearchType(SearchType searchType) {
    _searchType = searchType;
    Settings.searchType.value = searchType;
  }

  void _updateSearchBarTexts() {
    switch (_searchType) {
      case SearchType.community:
        _searchBarPrefixText = _searchPlatform.communityPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? _searchPlatform.communityLabel : _searchPlatform.communityLabel.toTitleCase();
      case SearchType.user:
        _searchBarPrefixText = _searchPlatform.userPrefix;
        _searchBarHint = _searchBarFocusNode.hasFocus ? 'username' : 'Username';
      case SearchType.all:
        _searchBarPrefixText = null;
        _searchBarHint = 'Search ${_searchPlatform.name.toTitleCase()}';
    }
  }

  void _updateIsSearchValid() {
    _isSearchValid = switch (_searchType) {
      SearchType.community => RegExp(_searchPlatform.communityNameValidation).hasMatch(_searchQuery),
      SearchType.user => RegExp(_searchPlatform.userNameValidation).hasMatch(_searchQuery),
      SearchType.all => _searchQuery.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.activeUser,
      builder: (context, activeUser, child) {
        final showRootPage = activeUser?.platform.api.hasLogin ?? false;
        final headerCount = showRootPage ? 2 : 1;
        return ValueListenableBuilder(
          valueListenable: Settings.showPlatformColorAccents,
          builder: (context, showPlatformColorAccents, child) {
            final Color accentColor;
            final Color leadingForegroundColor;
            if (showPlatformColorAccents) {
              accentColor = _searchPlatform.color;
              leadingForegroundColor = Colors.white;
            }
            else {
              accentColor = Theme.of(context).colorScheme.primary;
              leadingForegroundColor = Colors.black;
            }
            final listView = ListView.builder(
              padding: widget.padding,
              itemCount: headerCount + _visibleCommunities.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isCombinedFlavor = F.appFlavor == Flavor.combined;
                  final double width;
                  final double rightCornerRadius;
                  final Alignment? alignment;
                  final Widget child;
                  if (_searchBarPrefixText != null && _isSearchBarFocused) {
                    width = 48;
                    rightCornerRadius = 6;
                    alignment = Alignment.centerRight;
                    child = Transform.translate(
                      offset: const Offset(0, 0.5), // Can't get text aligned without this
                      child: Text(
                        _searchBarPrefixText!,
                        style: TextStyle(
                          fontSize: Theme.of(context).searchBarTheme.textStyle?.resolve({})?.fontSize ?? 16,
                          color: leadingForegroundColor.withAlpha(200),
                          // color: Colors.black
                          // fontWeight: FontWeight.bold
                        ),
                      ),
                    );
                  }
                  else {
                    width = 40;
                    rightCornerRadius = 20;
                    alignment = null;
                    child = Icon(
                      Icons.search_rounded,
                      color: leadingForegroundColor
                    );
                  }
                  final leadingIcon = AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: width,
                    height: 40,
                    alignment: alignment,
                    decoration: BoxDecoration(
                      color: accentColor,
                      // color: _searchPlatform.color.withAlpha(Constants.platformColorBackgroundAlpha),
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(20),
                        right: Radius.circular(rightCornerRadius),
                      ),
                    ),
                    child: child
                  );
                  final searchBar = SearchBar(
                    controller: _searchController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(right: 8)),
                    hintText: _searchBarHint,
                    hintStyle: WidgetStatePropertyAll(TextStyle(color: Colors.white60)),
                    inputFormatters: _searchType != SearchType.all ? [FilteringTextInputFormatter.allow(_searchNameAllowedRegex)] : null,
                    backgroundColor: WidgetStateProperty.all(Constants.lighterBackgroundColor),
                    side: _isSearchValid && _isSearchBarFocused ? WidgetStatePropertyAll(BorderSide(color: accentColor),) : null,
                    leading: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.only(left: 8),
                      child: isCombinedFlavor
                        ? GestureDetector(
                            onTap: _cyclePlatform,
                            child: leadingIcon
                          )
                        : leadingIcon
                    ),
                    trailing: _isSearchBarFocused
                      ? [
                          IconButton(
                            icon: Icon(
                              _searchType.icon,
                              color: Colors.white54
                            ),
                            onPressed: _cycleSearchType,
                          )
                        ]
                      : null,
                    onChanged: (value) {
            
                      var cleanValue = value;
                      var lowerCase = value.toLowerCase();
            
                      bool handledPrefix = false;
                      for (Platform platform in F.appFlavor.platforms) {
                        if (lowerCase.startsWith(platform.communityPrefix)) {
                          cleanValue = cleanValue.substring(platform.communityPrefix.length);
                          _updateSearchType(SearchType.community);
                          _searchPlatform = platform;
                          _searchBarPrefixText = platform.communityPrefix;
                          _searchBarHint = platform.communityLabel;
                          handledPrefix = true;
                          break;
                        }
                        else if (lowerCase.startsWith(platform.userPrefix)) {
                          cleanValue = cleanValue.substring(platform.userPrefix.length);
                          _updateSearchType(SearchType.user);
                          _searchPlatform = platform;
                          _searchBarPrefixText = platform.userPrefix;
                          _searchBarHint = 'username';
                          handledPrefix = true;
                          break;
                        }
                      }
            
                      if (cleanValue.isNotEmpty) {
            
                        void clean(String allowedChars) {
                          final escaped = hexEscape(allowedChars).join();
                          cleanValue = cleanValue
                            .toLowerCase()
                            .replaceAll(RegExp('[^a-z0-9$escaped]'), '')
                            .replaceAllMapped(RegExp('[$escaped]{2,}'), (m) => m.group(0)![0])
                            .replaceFirst(RegExp('^[$escaped]'), '');
            
                        }
            
                        if (_searchType == SearchType.community) {
                          clean(_searchPlatform.communityNameAllowedChars);
                        }
                        else if (_searchType == SearchType.user) {
                          clean(_searchPlatform.userNameAllowedChars);
                        }
                      }
            
                      if (cleanValue != value) {
                        _searchController.text = cleanValue;
                        _searchController.selection = TextSelection.fromPosition(TextPosition(offset: cleanValue.length));
                      }
                      
                      if (handledPrefix || cleanValue != _searchQuery) {
                        setState(() {
                          _searchQuery = cleanValue;
                          _updateVisibleCommunities();
                          _updateIsSearchValid();
                        });
                      }
                    },
                    onSubmitted: (value) {
                      switch (_searchType) {
                        case SearchType.community:
                          if (!RegExp(_searchPlatform.communityNameValidation).hasMatch(value)) {
                            return;
                          }
                          String? query = value;
                          if (query.isEmpty) {
                            if (_searchPlatform.homeCommunity != null) {
                              return;
                            }
                            query = null;
                          }
                          final community = Community(
                            platform: _searchPlatform,
                            name: query
                          );
                          context.pop();
                          _navigateToCommunity(community);
                          Settings.communities.add(community);
                        case SearchType.user:
                          if (!RegExp(_searchPlatform.userNameValidation).hasMatch(value)) {
                            return;
                          }
                          context.pop();
                          context.push(() {
                            return UserDetailsScreen(
                              platform: _searchPlatform,
                              username: value
                            );
                          });
                        case SearchType.all:
                          final query = value.trim();
                          if (query.isEmpty) return;
                          context.pop();
                          context.push(() {
                            return SearchScreen(
                              platform: _searchPlatform,
                              query: query
                            );
                          });
                      }
                    },
                  );
            
                  return ListTile(
                    minVerticalPadding: 0,
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KeyboardListener(
                        focusNode: _searchBarFocusNode,
                        onKeyEvent: (KeyEvent event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _searchController.text.isEmpty) {
                            if (isCombinedFlavor) {
                              _cyclePlatform();
                            }
                            else {
                              _cycleSearchType();
                            }
                          }
                        },
                        child: searchBar,
                      )
                    ),
                  );
                }
                
                if (index == 1 && showRootPage) {
                  return _CommunityNameListTile(
                    platform: widget.platform,
                    community: Community(platform: activeUser!.platform),
                    activeCommunityName: widget.activeCommunityName,
                    leading: IconButton(
                      onPressed: () {},
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            )
                          ),
                          Icon(
                            Icons.reddit_rounded, //TODO
                            size: 32,
                            color: activeUser.platform.color
                          ),
                        ],
                      )
                    ),
                    title: Text(activeUser.platform.rootCommunityName),
                    onTap: (community) => _onCommunityTap(community),
                  );
                }
            
                final community = _visibleCommunities[index - headerCount];
                return _CommunityNameListTile(
                  platform: widget.platform,
                  community: community,
                  activeCommunityName: widget.activeCommunityName,
                  leading: IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: Settings.showPlatformColorAccents,
                      builder: (context, showPlatformColorAccents, child) {
                        final IconData icon;
                        final Color? color;
                        if (community.isFavorite) {
                          icon = Icons.star_rounded;
                          color = showPlatformColorAccents ? null : Theme.of(context).colorScheme.primary;
                          // color = showPlatformColorAccents ? community.platform.color : Theme.of(context).colorScheme.primary;
                        }
                        else {
                          icon = Icons.star_border_rounded;
                          color = null;
                        }
                        return Icon(
                          icon,
                          color: color,
                          size: 24
                        );
                      }
                    ),
                    onPressed: () {
                      Settings.communities.update(community.copyWith(isFavorite: !community.isFavorite));
                    }
                  ),
                  title: F.appFlavor == Flavor.combined || community.platform.homeCommunity == null ? PrefixedCommunityName(community: community) : Text(community.name!),
                  onTap: (community) => _onCommunityTap(community),
                );
              }
            );
            if (activeUser == null) {
              return listView;
            }
            return CustomRefreshIndicator(
              platform: widget.platform,
              edgeOffset: MediaQuery.of(context).padding.top + 56,
              onRefresh: () async {
                final List<Community> subcscribedCommunities = [];
                for (var platform in F.appFlavor.platforms) {
                  if (platform.api.hasLogin) {
                    final subscribedCommunityNames = await widget.platform.api.getSubscribedCommunityNames();
                    subscribedCommunityNames.map((name) {
                      return Community(
                        platform: platform,
                        name: name
                      );
                    });
                  }
                }
                Settings.communities.addAll(subcscribedCommunities);
              },
              child: listView
            );
          }
        );
      }
    );
  }

}

class _CommunityNameListTile extends StatelessWidget {
  
  final Platform platform;
  final Community community;
  final String? activeCommunityName;
  final Widget? leading;
  final Widget title;
  final void Function(Community community) onTap;

  const _CommunityNameListTile({
    super.key,
    required this.platform,
    required this.community,
    required this.activeCommunityName,
    required this.leading,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListTile(
          horizontalTitleGap: 8,
          leading: leading,
          title: title,
          onTap: () => onTap(community),
          onLongPress: () {
            final activeUser = Settings.activeUser.value;
            showSimpleOptionsDialog(
              context: context,
              title: community.prefixedName,
              options: {
                if (community.name != null && activeUser != null)
                  'Unsubscribe': () => activeUser.platform.api.unsubscribe(community.name!),
                'Remove': () => Settings.communities.remove(community)
              },
            );
          }
        ),
        if (community.platform == platform && community.name == activeCommunityName)
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: ValueListenableBuilder(
              valueListenable: Settings.showPlatformColorAccents,
              builder: (context, showPlatformColorAccents, child) {
                return Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: showPlatformColorAccents ? community.platform.color : Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                );
              }
            ),
          )
      ]
    );
  }

}