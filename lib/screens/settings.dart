import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/core/enums.dart';
import 'package:lurk/core/utils.dart';
import 'package:lurk/core/flavors.dart';
import 'package:lurk/services/settings.dart';
import 'package:lurk/widgets/themed_app_bar.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

}

class _SettingsScreenState extends State<SettingsScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _Header(text: 'Home page'),
            ValueListenableBuilder(
              valueListenable: Settings.homeCommunity,
              builder: (context, homeCommunity, child) {
                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (F.appFlavor == Flavor.combined) ...[
                        Row(
                          children: Platform.values.map((platform) {
                            final bool isSelected = homeCommunity.platform == platform;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(platform.name.toTitleCase()),
                                selected: isSelected,
                                showCheckmark: false, 
                                backgroundColor: Constants.lighterBackgroundColor, 
                                selectedColor: platform.color.withAlpha(200),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                ),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (bool selected) {
                                  if (selected) {
                                    Settings.homeCommunity.value = homeCommunity.copyWith(platform: platform);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _TextField(
                        defaultValue: Settings.homeCommunity.hasSavedValue ? homeCommunity.name : null,
                        label: homeCommunity.platform.communityLabel.toTitleCase(),
                        hintText: homeCommunity.platform.communityHome,
                        prefixText: homeCommunity.platform.communityPrefix,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        onSubmitted: (value) {
                          Settings.homeCommunity.value = homeCommunity.copyWith(name: value.isEmpty ? null : value);
                        },
                      )
                    ],
                  )
                );
              }
            ),
            const _Divider(),
            _Header(text: 'Content'),
            _SettingSwitchListTile(
              setting: Settings.showCommentImages,
              label: 'Show comment images'
            ),
            _SettingSwitchListTile(
              setting: Settings.autoplayVideos,
              label: 'Autoplay videos'
            ),
            const _Divider(),
            _Header(
              text: 'Appearance'
            ),
            _SettingColorListTile(
              setting: Settings.appBarColor,
              label: 'App bar color',
            ),
            _SettingSwitchListTile(
              setting: Settings.useBottomBar,
              label: 'Bottom bar'
            ),
            if (F.appFlavor == Flavor.combined) ...[
              _SettingSwitchListTile(
                setting: Settings.showPlatformColorAccents,
                label: 'Platform color accents'
              ),
              const _Divider(),
              _Header(text: 'Reddit'),
              const _ClientIdSetting(),
              const _RedirectUriSetting(),
              const _LinksFromOldRedditSetting(),
            ],
            const _Divider(),
            _Header(
              text: 'Other'
            ),
            if (F.appFlavor == Flavor.reddit) ...[
              const _LinksFromOldRedditSetting(),
              const _ClientIdSetting(),
              const _RedirectUriSetting()
            ],
            _SettingStringListTile(
              setting: Settings.userAgent,
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

class _ClientIdSetting extends StatelessWidget {

  const _ClientIdSetting({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return _SettingStringListTile(
      setting: Settings.clientId,
      label: 'Client ID',
      hintText: 'Not yet implemented',
      helpText: 'Without a client ID, Reddit limits you to 100 requests per 10 minutes.\n\nSpecifying a client ID increases this limit to 100 requests per 1 minute (per client ID) and enables login (not yet implemented).',
    );
  }

}

class _RedirectUriSetting extends StatelessWidget {

  const _RedirectUriSetting({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.clientId,
      builder: (context, clientId, child) {
        if (clientId != null && clientId.isNotEmpty) {
          return _SettingStringListTile(
            setting: Settings.redirectUri,
            label: 'Redirect URI',
            hintText: 'Not yet implemented',
            helperText: (value) => "Used to spoof another app's authorization flow",
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

}

class _LinksFromOldRedditSetting extends StatelessWidget {

  const _LinksFromOldRedditSetting({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return _SettingSwitchListTile(
      setting: Settings.copyOldRedditLinks,
      label: 'Links from old.reddit.com',
      helpText: 'When enabled, any links you copy or open in your browser will be from old.reddit.com rather than www.reddit.com.',
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
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
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
  final Function(String)? helperText;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final Widget? suffixIcon;
  final Function(String) onSubmitted;

  const _TextField({
    super.key,
    required this.defaultValue,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.floatingLabelBehavior,
    this.suffixIcon,
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
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        helperText: widget.helperText?.call(_controller.text),
        prefixText: widget.prefixText,
        floatingLabelBehavior: widget.floatingLabelBehavior,
        helperMaxLines: 2,
        suffixIcon: widget.suffixIcon
      ),
      onSubmitted: widget.onSubmitted,
    );
  }

}

class _SettingStringListTile<T> extends StatelessWidget {

  final SettingNotifier<T?> setting;
  final String label;
  final String? hintText;
  final String? helpText;
  final Function(String)? helperText;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final String? Function(T? value)? toText;
  final T? Function(String? value)? fromText;

  const _SettingStringListTile({
    required this.setting,
    required this.label,
    this.hintText,
    this.helpText,
    this.helperText,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.floatingLabelBehavior,
    this.toText,
    this.fromText,
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
            helperText: helperText,
            prefixText: prefixText,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            floatingLabelBehavior: floatingLabelBehavior,
            suffixIcon: helpText != null
              ? IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () {
                  showSimpleBottomSheet(
                    context: context,
                    title: label,
                    content: helpText!
                  );
                }
              ) : null,
            onSubmitted: (newValue) {
              setting.value = fromText == null ? (newValue.isEmpty ? null : newValue as T) : fromText!.call(newValue);
            },
          );
        },
      ),
    );
  }

}

class _SettingColorListTile extends StatelessWidget {

  final SettingNotifier<Color?> setting;
  final String label;
  final String? hintText;
  final String? helpText;

  const _SettingColorListTile({
    super.key,
    required this.setting,
    required this.label,
    this.hintText,
    this.helpText
  });

  @override
  Widget build(BuildContext context) {
    return _SettingStringListTile(
      setting: setting,
      label: label,
      hintText: hintText ?? setting.defaultValue?.toHex(),
      helpText: helpText,
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

class _SettingSwitchListTile extends StatelessWidget {

  final SettingNotifier<bool> setting;
  final String label;
  final String? helpText;

  const _SettingSwitchListTile({
    super.key,
    required this.setting,
    required this.label,
    this.helpText
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: setting,
      builder: (context, value, child) {
        return SwitchListTile(
          title: helpText != null
            ? Row(
                children: [
                  Expanded(
                    child: Text(label),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded),
                    color: Theme.of(context).inputDecorationTheme.suffixIconColor,
                    onPressed: () {
                      showSimpleBottomSheet(
                        context: context,
                        title: label,
                        content: helpText!
                      );
                    },
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