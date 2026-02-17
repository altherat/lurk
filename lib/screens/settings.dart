import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/platforms.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/services/api/digg.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final String platformLabel = F.appFlavor == Flavor.combined ? 'Platform' : F.appFlavor.platforms.first.name.toTitleCase();
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            const _Header(text: 'Home page'),
            if (F.appFlavor == Flavor.combined) ...[
              _ChoiceChipSettingListTile(
                setting: Settings.homeCommunityPlatform,
                choices: Platform.values,
                choiceLabel: (platform) => platform.name.toTitleCase(),
                selectedColor: (platform) => platform.color,
                onSelected: (platform) {
                  Settings.homeCommunityName.defaultValue = platform.homeCommunityName;
                }
              ),
            ],
            ListTile(
              minVerticalPadding: 0,
              title: ValueListenableBuilder(
                valueListenable: Settings.homeCommunityPlatform,
                builder: (context, homeCommunityPlatform, child) {
                  return ValueListenableBuilder(
                    valueListenable: Settings.homeCommunityName,
                    builder: (context, homeCommunityName, child) {
                      return _TextField(
                        defaultValue: Settings.homeCommunityName.hasSavedValue ? homeCommunityName : null,
                        label: homeCommunityPlatform.communityLabel.toTitleCase(),
                        hintText: Settings.homeCommunityName.defaultValue,
                        prefixText: homeCommunityPlatform.communityPrefix,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        inputFormatters: homeCommunityPlatform.communityNameInputFormatters,
                        showPrefix: (isFocused, value) => isFocused || value.isNotEmpty || (homeCommunityName?.isNotEmpty ?? false),
                        onSubmitted: (value) {
                          Settings.homeCommunityName.value = value.isEmpty ? null : value;
                        },
                      );
                    }
                  );
                }
              ),
            ),
            const _Divider(),
            _Header(text: 'General'),
            _BoolSettingListTile(
              setting: Settings.showCommentImages,
              label: 'Comment images'
            ),
            _BoolSettingListTile(
              setting: Settings.autoplayVideos,
              label: 'Autoplay videos'
            ),
            _BoolSettingListTile(
              setting: Settings.useBottomBar,
              label: 'Bottom bar'
            ),
            _BoolSettingListTile(
              setting: Settings.reverseCommunityList,
              label: 'Reverse community list'
            ),
            _BoolSettingListTile(
              setting: Settings.backOnHomeScreenShowCommunityList,
              label: 'Override back navigation',
              infoText: 'When enabled and on the home screen, navigating back will show the community list rather than exit the app.',
            ),
            if (F.appFlavor.platforms.any((platform) => platform.hasLogin)) ...[
              _BoolSettingListTile(
                setting: Settings.swipePostsToVote,
                label: 'Swipe posts to vote',
              ),
              _BoolSettingListTile(
                setting: Settings.swipeCommentsToVote,
                label: 'Swipe comments to vote',
              ),
              _BoolSettingListTile(
                setting: Settings.showCommentVotingEdges,
                label: 'Comment voting edges',
                infoText: 'Tapping the left side of a comment will upvote it and tapping the right side will downvote it.',
              ),
            ],
            _ChoiceSettingListTile(
              setting: Settings.commentTapBehavior,
              title: 'Comment tap behavior',
              choices: CommentBehavior.values.toList(),
              choiceLabel: (choice) => choice.label
            ),
            _ChoiceSettingListTile(
              setting: Settings.commentLongPressBehavior,
              title: 'Comment long press behavior',
              choices: CommentBehavior.values.toList(),
              choiceLabel: (choice) => choice.label
            ),
            const _Divider(),
            const _Header(text: 'Colors'),
            _ColorSettingListTile(
              setting: Settings.appBarColor,
              label: 'App bar color',
            ),
            _BoolSettingListTile(
              setting: Settings.showPlatformColorAccents,
              label: '$platformLabel color accents'
            ),
            _BoolSettingListTile(
              setting: Settings.showPlatformColorTextAccents,
              label: '$platformLabel color text accents'
            ),
            if (F.appFlavor == Flavor.combined) ...[
              const _Divider(),
              const _Header(text: 'Reddit'),
              const _RedditLinksFromOldRedditSetting(),
              const _RedditClientIdSetting(),
              const _RedditRedirectUriSetting(),
              const _RedditUserAgentSetting(),
              const _Divider(),
              const _Header(text: 'Digg'),
              const _DiggPostsFetchDepthSetting(),
              const _DiggUserAgentSetting()
            ]
            else if (F.appFlavor == Flavor.reddit) ...[
              const _RedditLinksFromOldRedditSetting(),
              const _RedditClientIdSetting(),
              const _RedditRedirectUriSetting(),
              const _RedditUserAgentSetting(),
            ]
            else if (F.appFlavor == Flavor.digg) ...[
              const _DiggPostsFetchDepthSetting(),
              const _DiggUserAgentSetting()
            ],
          ],
        ),
      )
    );
  }

}

class _Divider extends StatelessWidget {

  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 32,
      color: Constants.lighterBackgroundColor
    );
  }

}

class _RedditLinksFromOldRedditSetting extends StatelessWidget {

  const _RedditLinksFromOldRedditSetting();

  @override
  Widget build(BuildContext context) {
    return _BoolSettingListTile(
      setting: Settings.redditCopyOldRedditLinks,
      label: 'Links from old.reddit.com',
      infoText: 'When enabled, any links you copy or open in your browser will be from old.reddit.com rather than www.reddit.com.',
    );
  }

}

class _RedditClientIdSetting extends StatelessWidget {

  const _RedditClientIdSetting();

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: Settings.redditClientId,
      label: 'Client ID',
      infoText: 'Without a client ID, Reddit limits you to 100 requests per 10 minutes.\n\nSpecifying a client ID increases this limit to 1000 requests per 10 minutes (per client ID) and enables login.',
      inputFormatters: [LengthLimitingTextInputFormatter(22)],
    );
  }

}

class _RedditRedirectUriSetting extends StatelessWidget {

  const _RedditRedirectUriSetting();

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: Settings.redditRedirectUri,
      label: 'Redirect URI',
      infoText: "Possibly used to spoof another app's login. No one knows.",
    );
  }

}

class _RedditUserAgentSetting extends StatelessWidget {
  
  const _RedditUserAgentSetting();

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: Settings.redditUserAgent,
      label: 'User agent',
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

}

class _DiggPostsFetchDepthSetting extends StatelessWidget {

  final _maxDepth = 5;

  const _DiggPostsFetchDepthSetting();

  @override
  Widget build(BuildContext context) {
    return _ChoiceChipSettingListTile(
      title: 'Posts fetch depth',
      setting: Settings.diggPostsFetchDepth,
      infoText: "Digg's website and app seems to show fewer posts than what actually might exist for smaller communities (unsure if intentional). This setting causes additional requests in attempt to retrieve more posts (up to ${DiggApi.resultsLimit} posts). When loading popular communties with many posts, this setting should have no effect.\n\nExample (setting value of 3):\nWhen requesting posts from a lesser-known community, Digg might respond with 10 posts but also indicate that there are more posts available. Lurk will do up to 2 more requests to try and get a total of ${DiggApi.resultsLimit} posts.",
      choices: List.generate(_maxDepth, (index) => index + 1),
    );
  }

}

class _DiggUserAgentSetting extends StatelessWidget {
  
  const _DiggUserAgentSetting();

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: Settings.diggUserAgent,
      label: 'User agent',
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

}

class _Header extends StatelessWidget {

  final String text;

  const _Header({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}

class _TextField extends StatefulWidget {

  final String? defaultValue;
  final String? label;
  final String? hintText;
  final String? infoText;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final TextInputType? keyboardType;
  final bool Function(bool isFocused, String value)? showPrefix;
  final Function(String value)? onChanged;
  final Function(String value) onSubmitted;

  const _TextField({
    required this.defaultValue,
    this.label,
    this.hintText,
    this.infoText,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.floatingLabelBehavior,
    this.keyboardType,
    this.showPrefix,
    this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_TextField> createState() => _TextFieldState();

}

class _TextFieldState extends State<_TextField> {

  late final _controller = TextEditingController(text: widget.defaultValue ?? '');
  final _focusNode = FocusNode();
  late bool _showPrefix;
  String? _lastSubmittedValue;

  @override void initState() {
    super.initState();
    _lastSubmittedValue = widget.defaultValue;
    _focusNode.addListener(_onFocusChange);
    _showPrefix = widget.showPrefix?.call(false, _controller.text) ?? true;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      if (_controller.text != _lastSubmittedValue) {
        _submit(_controller.text);
      }
    }
    _updateShowPrefix();
  }

  void _updateShowPrefix() {
    if (widget.showPrefix != null) {
      final showPrefix = widget.showPrefix!(_focusNode.hasFocus, _controller.text);
      if (showPrefix != _showPrefix) {
        setState(() {
          _showPrefix = showPrefix;
        });
      }
    }
  }

  void _submit(String value) {
    _lastSubmittedValue = value;
    widget.onSubmitted(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      controller: _controller,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        prefixText: _showPrefix ? widget.prefixText : null,
        floatingLabelBehavior: widget.floatingLabelBehavior,
        helperMaxLines: 2,
        suffixIcon: widget.infoText != null
          ? _InfoIconButton(
              title: widget.label,
              text: widget.infoText!
            )
          : null,
      ),
      onChanged: (value) {
        _updateShowPrefix();
        widget.onChanged?.call(value);
      },
      onSubmitted: _submit
    );
  }

}

class _InfoIconButton extends StatelessWidget {

  final String? title;
  final String text;

  const _InfoIconButton({
    required this.title,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline_rounded),
      color: Theme.of(context).inputDecorationTheme.suffixIconColor,
      onPressed: () {
        showSimpleTextBottomSheet(
          context: context,
          title: title,
          content: text
        );
      }
    );
  }

}

class _TextSettingListTile<T> extends StatelessWidget {

  final SettingNotifier<T?> setting;
  final String label;
  final String? hintText;
  final String? infoText;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final TextInputType? keyboardType;
  final String? Function(T? value)? toText;
  final T? Function(String? value)? fromText;
  final Function(String value)? onChanged;

  const _TextSettingListTile({
    required this.setting,
    required this.label,
    this.hintText,
    this.infoText,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.floatingLabelBehavior,
    this.keyboardType,
    this.toText,
    this.fromText,
    this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: ValueListenableBuilder<T?>(
        valueListenable: setting,
        builder: (context, value, child) {
          return _TextField(
            defaultValue: setting.hasSavedValue ? toText?.call(value) ?? value.toString() : null,
            label: label,
            hintText: hintText ?? (setting.defaultValue != null ? (toText?.call(setting.defaultValue) ?? setting.defaultValue.toString()) : null),
            infoText: infoText,
            prefixText: prefixText,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            floatingLabelBehavior: floatingLabelBehavior,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onSubmitted: (newValue) {
              setting.value = fromText != null ? fromText!.call(newValue) : (newValue.isEmpty ? null : newValue as T);
            },
          );
        },
      ),
    );
  }

}

class _ColorSettingListTile extends StatelessWidget {

  final SettingNotifier<Color?> setting;
  final String label;

  const _ColorSettingListTile({
    required this.setting,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: setting,
      label: label,
      hintText: setting.defaultValue?.toHex(),
      prefixText: '#',
      inputFormatters: [
        LengthLimitingTextInputFormatter(8),
        FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')), 
      ],
      textCapitalization: TextCapitalization.characters,
      toText: (value) => value?.toHex(),
      fromText: (value) => value?.toColor()
    );
  }

}

class _BoolSettingListTile extends StatelessWidget {

  final SettingNotifier<bool> setting;
  final String label;
  final String? infoText;

  const _BoolSettingListTile({
    required this.setting,
    required this.label,
    this.infoText
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: setting,
      builder: (context, value, child) {
        return SwitchListTile(
          title: infoText != null
            ? Row(
                children: [
                  Expanded(
                    child: Text(label),
                  ),
                  _InfoIconButton(
                    title: label,
                    text: infoText!
                  )
                ]
              )
            : Text(label),
          value: value,
          onChanged: (newValue) => setting.value = newValue,
        );
      }
    );
  }

}

class _ChoiceSettingListTile<T> extends StatelessWidget {

  final SettingNotifier<T?> setting;
  final String title;
  final List<T> choices;
  final String? infoText;
  final String Function(T choice) choiceLabel;

  const _ChoiceSettingListTile({
    super.key,
    required this.setting,
    required this.title,
    required this.choices,
    this.infoText,
    required this.choiceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        showSimpleBottomSheet(
          context: context,
          title: title,
          body: RadioGroup(
            groupValue: setting.value,
            onChanged: (value) {
              context.pop();
              setting.value = value;
            },
            child: Column(
              children: choices.map((entry) {
                return RadioListTile(
                  value: entry,
                  title: Text(choiceLabel(entry)),
                );
              }).toList()
            )
          )
        );
      },
      title: Text(title),
      subtitle: ValueListenableBuilder<T?>(
        valueListenable: setting,
        builder: (context, value, child) {
          return value != null ? Text(choiceLabel(value)) : const SizedBox.shrink();
        }
      )
    );
  }

}

class _ChoiceChipSettingListTile<T> extends StatelessWidget {

  final SettingNotifier<T?> setting;
  final String? title;
  final List<T> choices;
  final String? infoText;
  final String Function(T choice)? choiceLabel;
  final Color Function(T choice)? selectedColor;
  final Function(T choice)? onSelected;

  const _ChoiceChipSettingListTile({
    super.key,
    required this.setting,
    this.title,
    required this.choices,
    this.infoText,
    this.choiceLabel,
    this.selectedColor,
    this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title != null ? Text(title!) : null,
      subtitle: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ValueListenableBuilder(
                valueListenable: setting,
                builder: (context, value, child) {
                  return Row(
                    spacing: Constants.choiceChipGapSize,
                    children: List.generate(choices.length, (index) {
                      final choice = choices[index];
                      final labelString = choiceLabel?.call(choice) ?? choice.toString();
                      final bool isSelected = value == choice;
                      final Color? selectedColor;
                      final TextStyle? labelStyle;
                      if (isSelected && this.selectedColor != null) {
                        selectedColor = this.selectedColor?.call(choice);
                        labelStyle = TextStyle(color: selectedColor!.contrast);
                      }
                      else {
                        selectedColor = null;
                        labelStyle = null;
                      }
                      return ChoiceChip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(labelString),
                        selected: isSelected,
                        backgroundColor: Constants.lighterBackgroundColor, 
                        selectedColor: selectedColor,
                        labelStyle: labelStyle,
                        side: BorderSide.none,
                        onSelected: (bool selected) {
                          if (selected) {
                            setting.value = choice;
                            onSelected?.call(choice);
                          }
                        },
                      );
                    })
                  );
                }
              ),
            ),
          ),
          if (infoText != null)
            _InfoIconButton(
              title: title,
              text: infoText!
            )
        ],
      ),
    );
  }

}