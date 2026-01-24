import 'package:lurk/core/utils.dart';

abstract class UserStat<T> {

  final String label;
  final T value;

  UserStat({
    required this.label,
    required this.value
  });

  String get displayValue;

}

class DateTimeUserStat extends UserStat<DateTime> {
  
  DateTimeUserStat({
    required super.label,
    required super.value
  });
  
  @override
  String get displayValue => value.timeAgo;

}

class NumberUserStat extends UserStat<num> {

  NumberUserStat({
    required super.label,
    required super.value
  });

  @override
  String get displayValue => value.toCommaString();

}