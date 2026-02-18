import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lurk/core/constants.dart';
import 'package:lurk/models/community.dart';
import 'package:lurk/services/api.dart';

final _commaFormatter = NumberFormat.decimalPattern();

extension CommunityExtension on Community {

  ApiService getApi(String? activeUserId) => platform.getApi(host, activeUserId);
  
}

extension NumExtension on num {

  String toCommaString() => _commaFormatter.format(this);

  String toPluralString(String plural)  => this == 1 ? '1 $plural' : '${toCommaString()} ${plural}s';
  
}

extension StringExtension on String {

  String toPosessive() => endsWith('s') || endsWith('S') ? "$this'" : "$this's";
  
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Color? toColor() {
    final trimmed = trim();
    try {
      return trimmed.length == 6 ? Color(int.parse('FF$trimmed', radix: 16)) : trimmed.length == 8 ? Color(int.parse(trimmed, radix: 16)) : null;
    } catch (_) {
      return null;
    }
  }
  
}

extension DateTimeExtension on DateTime {

  String get timeAgo => _timeAgo(false);

  String get timeAgoLong => _timeAgo(true);

  String get timeAgoCompact {
    final Duration diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    if (diff.inDays < 30)    return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365)   return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  String _timeAgo(bool showAgo) {
    final Duration diff = DateTime.now().difference(this);
    final thresholds = {
      'year': 31536000,
      'month': 2592000,
      'week': 604800,
      'day': 86400,
      'hour': 3600,
      'minute': 60,
      'second': 1,
    };

    for (var entry in thresholds.entries) {
      final int count = diff.inSeconds ~/ entry.value;
      if (count >= 1) {
        final String unit = '$count ${entry.key}${count == 1 ? '' : 's'}';
        return showAgo ? '$unit ago' : unit;
      }
    }
    return 'just now';
  }

}

extension ColorExtension on Color {
  
  String toHex() => toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  String toCss() => '#${toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

  Color get contrast => computeLuminance() > 0.5 ? Colors.black : Colors.white;
  
}

extension BuildContextExtension on BuildContext {

  void pop<T>([T? result]) => Navigator.pop<T>(this, result);

  Future<T?> push<T>(Widget Function() builder) {
    return Navigator.push<T>(
      this,
      _PageRoute(builder: (_) => builder())
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar({Duration duration = const Duration(seconds: 4), required Widget content, SnackBarAction? action}) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        duration: duration,
        content: content,
        action: action
      )
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBarMessage(String text) => showSnackBar(content: Text(text));

}

class _PageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  
  _PageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
  });

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => Constants.screenTransitionDuration;

  @override
  Duration get reverseTransitionDuration => Constants.reverseScreenTransitionDuration;
  
}
