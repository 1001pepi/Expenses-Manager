import 'package:flutter/material.dart';

class DateFormatUtils {
  static String formatDate(DateTime date) {
    return '${date.day} ${getMonthName(date.month)}';
  }

  static String formatFullDate(DateTime date) {
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static String getMonthAbbr(int month) {
    const abbrs = [
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
    return abbrs[month - 1];
  }

  static int getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static String getPeriodText(
    String tabName,
    DateTime date, {
    DateTimeRange? customRange,
  }) {
    switch (tabName) {
      case 'Day':
        final now = DateTime.now();
        if (date.day == now.day &&
            date.month == now.month &&
            date.year == now.year) {
          return 'Today, ${formatDate(date)}';
        } else if (date.year == now.year) {
          return formatDate(date);
        } else {
          return formatFullDate(date);
        }
      case 'Week':
        final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
        final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
        final currentYear = DateTime.now().year;

        // If the week spans two different years, show both years explicitly
        if (firstDayOfWeek.year != lastDayOfWeek.year) {
          return '${firstDayOfWeek.day} ${getMonthAbbr(firstDayOfWeek.month)} ${firstDayOfWeek.year} - ${lastDayOfWeek.day} ${getMonthAbbr(lastDayOfWeek.month)} ${lastDayOfWeek.year}';
        }

        // Check if the week is entirely within the current year
        if (firstDayOfWeek.year == currentYear &&
            lastDayOfWeek.year == currentYear) {
          return '${firstDayOfWeek.day} ${getMonthAbbr(firstDayOfWeek.month)} - ${lastDayOfWeek.day} ${getMonthAbbr(lastDayOfWeek.month)}';
        } else {
          // Show year if week spans different years or is not in current year
          return '${firstDayOfWeek.day} ${getMonthAbbr(firstDayOfWeek.month)} - ${lastDayOfWeek.day} ${getMonthAbbr(lastDayOfWeek.month)}, ${lastDayOfWeek.year}';
        }
      case 'Month':
        return '${getMonthName(date.month)} ${date.year}';
      case 'Year':
        return '${date.year}';
      case 'Period':
        if (customRange == null) {
          return 'Custom Period';
        }

        final start = customRange.start;
        final end = customRange.end;
        final sameYear = start.year == end.year;

        final startText = sameYear
            ? '${start.day} ${getMonthAbbr(start.month)}'
            : '${start.day} ${getMonthAbbr(start.month)}, ${start.year}';
        final endText = '${end.day} ${getMonthAbbr(end.month)}, ${end.year}';

        return 'from $startText to $endText';
      default:
        return '';
    }
  }
}
