import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
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
    final String platformLabel = F.appFlavor == Flavor.combined ? 'Platform' : F.appFlavor.platforms.first.name;
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            const _Header(text: 'Home page'),
            if (F.appFlavor == Flavor.combined) ...[
              _ChoiceSettingListTile(
                setting: Settings.homeCommunityPlatform,
                choices: Platform.values,
                choiceLabel: (platform) => platform.name.toTitleCase(),
                selectedColor: (platform) => platform.color,
                onSelected: (platform) {
                  Settings.homeCommunityName.defaultValue = platform.homeCommunity;
                }
              ),
            ],
            ListTile(
              title: ValueListenableBuilder(
                valueListenable: Settings.homeCommunityPlatform,
                builder: (context, homeCommunityPlatform, child) {
                  return ValueListenableBuilder(
                    valueListenable: Settings.homeCommunityName,
                    builder: (context, homeCommunityName, child) {
                      return _TextField(
                        defaultValue: Settings.homeCommunityName.hasSavedValue ? homeCommunityName : null,
                        label: homeCommunityPlatform.communityLabel.toTitleCase(),
                        hintText: homeCommunityPlatform.homeCommunity,
                        prefixText: homeCommunityPlatform.communityPrefix,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        onSubmitted: (value) {
                          debugPrint('saving: $value');
                          Settings.homeCommunityName.value = value.isEmpty ? null : value;
                          debugPrint('saved');
                        },
                      );
                    }
                  );
                }
              ),
            ),
            const _Divider(),
            _Header(text: 'Content'),
            _BoolSettingListTile(
              setting: Settings.showCommentImages,
              label: 'Show comment images'
            ),
            _BoolSettingListTile(
              setting: Settings.autoplayVideos,
              label: 'Autoplay videos'
            ),
            const _Divider(),
            const _Header(
              text: 'Appearance'
            ),
            _ColorSettingListTile(
              setting: Settings.appBarColor,
              label: 'App bar color',
            ),
            _BoolSettingListTile(
              setting: Settings.useBottomBar,
              label: 'Bottom bar'
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
              const _Divider(),
              const _Header(text: 'Digg'),
              const _DiggPostsFetchDepthSetting()
            ],
            const _Divider(),
            const _Header(
              text: 'Other'
            ),
            if (F.appFlavor == Flavor.reddit) ...[
              const _RedditLinksFromOldRedditSetting(),
              const _RedditClientIdSetting(),
              const _RedditRedirectUriSetting(),
            ]
            else if (F.appFlavor == Flavor.digg) ...[
              const _DiggPostsFetchDepthSetting()
            ],
            _TextSettingListTile(
              setting: Settings.customUserAgent,
              label: 'User agent',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
            ),
          ],
        ),
      )
    );
  }

}

class _Divider extends StatelessWidget {

  const _Divider({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 32,
      color: Constants.lighterBackgroundColor
    );
  }

}

class _RedditLinksFromOldRedditSetting extends StatelessWidget {

  const _RedditLinksFromOldRedditSetting({
    super.key
  });

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

  const _RedditClientIdSetting({
    super.key
  });

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

  const _RedditRedirectUriSetting({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: Settings.redditRedirectUri,
      label: 'Redirect URI',
      infoText: "Possibly used to spoof another app's login flow? No one knows.",
    );
  }

}

class _DiggPostsFetchDepthSetting extends StatelessWidget {

  final _maxDepth = 5;

  const _DiggPostsFetchDepthSetting({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceSettingListTile(
      title: 'Posts fetch depth',
      setting: Settings.diggPostsFetchDepth,
      infoText: "Digg's website and app seems to show fewer posts than what actually might exist for smaller communities (unsure if intentional). This setting causes additional requests in attempt to retrieve more posts (up to ${DiggApi.resultsLimit}). When loading popular communties with many posts, this setting should have no effect.\n\nExample (setting value of 3):\nWhen requesting posts from a lesser-known community, Digg might respond with 10 posts but also indicate that there are more posts available. Lurk will do up to 2 more requests to try and get a total of ${DiggApi.resultsLimit} posts.",
      choices: List.generate(_maxDepth, (index) => index + 1),
    );
  }

}

class _Header extends StatelessWidget {

  final String text;

  const _Header({
    super.key,
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
  final Widget? suffixIcon;
  final Function(String value)? onChanged;
  final Function(String value) onSubmitted;

  const _TextField({
    super.key,
    required this.defaultValue,
    this.label,
    this.hintText,
    this.infoText,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.floatingLabelBehavior,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_TextField> createState() => _TextFieldState();

}

class _TextFieldState extends State<_TextField> {

  late final TextEditingController _controller = TextEditingController(text: widget.defaultValue ?? '');
  final FocusNode _focusNode = FocusNode();

  @override void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
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
      widget.onSubmitted(_controller.text);
    }
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
        prefixText: widget.prefixText,
        floatingLabelBehavior: widget.floatingLabelBehavior,
        helperMaxLines: 2,
        suffixIcon: widget.infoText != null
          ? _InfoIconButton(
              title: widget.label,
              text: widget.infoText!
            )
          : null,
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }

}

class _InfoIconButton extends StatelessWidget {

  final String? title;
  final String text;

  const _InfoIconButton({
    super.key,
    required this.title,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
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
      // minVerticalPadding: 0,
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
              setting.value = fromText == null ? (newValue.isEmpty ? null : newValue as T) : fromText!.call(newValue);
            },
          );
        },
      ),
    );
  }

}

class _IntSettingListTile extends StatelessWidget {

  final SettingNotifier<int> setting;
  final String label;
  final String? hintText;
  final String? infoText;

  const _IntSettingListTile({
    super.key,
    required this.setting,
    required this.label,
    this.hintText,
    this.infoText
  });

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: setting,
      label: label,
      hintText: hintText ?? setting.defaultValue?.toString(),
      infoText: infoText,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      textCapitalization: TextCapitalization.characters,
      toText: (value) => value?.toString(),
      fromText: (value) => value != null ? int.parse(value) : null
    );
  }

}

class _ColorSettingListTile extends StatelessWidget {

  final SettingNotifier<Color?> setting;
  final String label;
  final String? hintText;
  final String? infoText;

  const _ColorSettingListTile({
    super.key,
    required this.setting,
    required this.label,
    this.hintText,
    this.infoText
  });

  @override
  Widget build(BuildContext context) {
    return _TextSettingListTile(
      setting: setting,
      label: label,
      hintText: hintText ?? setting.defaultValue?.toHex(),
      infoText: infoText,
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
    super.key,
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

  final String? title;
  final SettingNotifier<T?> setting;
  final List<T> choices;
  final String? infoText;
  final String Function(T choice)? choiceLabel;
  final Color Function(T choice)? selectedColor;
  final Function(T choice)? onSelected;

  const _ChoiceSettingListTile({
    super.key,
    this.title,
    required this.setting,
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
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : Constants.choiceChipGapSize / 2, right: index == choices.length - 1 ? 0 : Constants.choiceChipGapSize / 2),
                        child: ChoiceChip(
                          label: Text(labelString),
                          selected: isSelected,
                          showCheckmark: false, 
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Constants.lighterBackgroundColor, 
                          selectedColor: selectedColor,
                          labelStyle: labelStyle,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onSelected: (bool selected) {
                            if (selected) {
                              setting.value = choice;
                              onSelected?.call(choice);
                            }
                          },
                        ),
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