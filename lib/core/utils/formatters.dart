import 'package:intl/intl.dart';

/// Date helpers used across screens so every date looks the same.
///
/// The locale is fixed to `en_US`, whose data ships with `intl`, so
/// formatting never fails on devices set to a locale that was not loaded.
abstract final class Formatters {
  static const String _locale = 'en_US';
  static final DateFormat _date = DateFormat('d MMM yyyy', _locale);
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a', _locale);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  /// Strips the time component so dates compare by calendar day.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Human friendly relative description such as "Today" or "In 3 days".
  static String relativeDay(DateTime target, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final days = dateOnly(target).difference(today).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days == -1) return 'Yesterday';
    if (days > 1) return 'In $days days';
    return '${-days} days ago';
  }
}

/// Generates collision-resistant identifiers without an extra dependency.
abstract final class IdGenerator {
  static int _counter = 0;

  static String next(String prefix) {
    _counter = (_counter + 1) % 100000;
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$micros-${_counter.toRadixString(36)}';
  }
}
