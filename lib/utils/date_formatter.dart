class DateFormatter {
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats date as "EEE, d MMM yyyy • HH:mm"
  /// Example: "Fri, 19 Dec 2025 • 14:32"
  static String formatDateTime(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final day = date.day;
    final month = _months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday, $day $month $year • $hour:$minute';
  }
}
