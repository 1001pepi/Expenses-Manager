import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class WeekPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String helpText;
  final Function(DateTime) onDateSelected;

  const WeekPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.helpText,
    required this.onDateSelected,
  });

  @override
  State<WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<WeekPickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  String _formatWeekRange(DateTime date) {
    final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
    return '${firstDayOfWeek.day} ${_getMonthAbbr(firstDayOfWeek.month)} ${firstDayOfWeek.year} - ${lastDayOfWeek.day} ${_getMonthAbbr(lastDayOfWeek.month)} ${lastDayOfWeek.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    widget.helpText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatWeekRange(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Month selector with navigation arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left),
                        onPressed: () {
                          setState(() {
                            final prevMonth = _selectedDate.month - 1;
                            final year = prevMonth < 1
                                ? _selectedDate.year - 1
                                : _selectedDate.year;
                            final month = prevMonth < 1 ? 12 : prevMonth;
                            final day = _getLastDayOfMonth(year, month);
                            _selectedDate = DateTime(
                              year,
                              month,
                              _selectedDate.day <= day
                                  ? _selectedDate.day
                                  : day,
                            );
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      // Month dropdown
                      DropdownButton2<int>(
                        value: _selectedDate.month,
                        onChanged: (int? newMonth) {
                          if (newMonth != null) {
                            setState(() {
                              final day = _getLastDayOfMonth(
                                _selectedDate.year,
                                newMonth,
                              );
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                newMonth,
                                _selectedDate.day <= day
                                    ? _selectedDate.day
                                    : day,
                              );
                            });
                          }
                        },
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          return DropdownMenuItem<int>(
                            value: month,
                            child: Text(_getMonthName(month)),
                          );
                        }).toList(),
                        dropdownStyleData: const DropdownStyleData(
                          maxHeight: 200,
                          isOverButton: false,
                          offset: Offset(0, 5),
                          width: 120,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Year dropdown
                      DropdownButton2<int>(
                        value: _selectedDate.year,
                        onChanged: (int? newYear) {
                          if (newYear != null) {
                            setState(() {
                              final day = _getLastDayOfMonth(
                                newYear,
                                _selectedDate.month,
                              );
                              _selectedDate = DateTime(
                                newYear,
                                _selectedDate.month,
                                _selectedDate.day <= day
                                    ? _selectedDate.day
                                    : day,
                              );
                            });
                          }
                        },
                        items: _generateYearList()
                            .map<DropdownMenuItem<int>>(
                              (int year) => DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString()),
                              ),
                            )
                            .toList(),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          isOverButton: false,
                          offset: const Offset(0, 5),
                          width: 80,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right),
                        onPressed: () {
                          setState(() {
                            final nextMonth = _selectedDate.month + 1;
                            final year = nextMonth > 12
                                ? _selectedDate.year + 1
                                : _selectedDate.year;
                            final month = nextMonth > 12 ? 1 : nextMonth;
                            final day = _getLastDayOfMonth(year, month);
                            _selectedDate = DateTime(
                              year,
                              month,
                              _selectedDate.day <= day
                                  ? _selectedDate.day
                                  : day,
                            );
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Calendar grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(height: 320, child: _buildCalendarGrid()),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, null);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedDate);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
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

  String _getMonthAbbr(int month) {
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

  List<int> _generateYearList() {
    final years = <int>[];
    for (
      int year = widget.firstDate.year;
      year <= widget.lastDate.year;
      year++
    ) {
      years.add(year);
    }
    return years;
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    return Column(
      children: [
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map(
                (day) => SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days in proper grid
        Column(children: _buildWeeks(firstWeekday, daysInMonth)),
      ],
    );
  }

  List<Widget> _buildWeeks(int firstWeekday, int daysInMonth) {
    final weeks = <Widget>[];
    var dayCounter = 1;
    final daysPerWeek = 7;
    int weekCount = 0;
    final selectedWeekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    // First week with leading empty cells
    final firstWeek = <Widget>[];
    // Add leading empty cells
    for (int i = 1; i < firstWeekday; i++) {
      firstWeek.add(SizedBox(width: 40, height: 40, child: Container()));
    }

    // Add days for first week
    while (firstWeek.length < daysPerWeek && dayCounter <= daysInMonth) {
      final day = dayCounter;
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final isInSelectedWeek = weekStart.isAtSameMomentAs(selectedWeekStart);

      firstWeek.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isInSelectedWeek
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.transparent,
              border: isInSelectedWeek
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isInSelectedWeek
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isInSelectedWeek
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
      dayCounter++;
    }

    weeks.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: firstWeek,
      ),
    );
    weeks.add(const SizedBox(height: 8));
    weekCount++;

    // Remaining weeks
    while (dayCounter <= daysInMonth) {
      final weekDays = <Widget>[];

      for (int i = 0; i < daysPerWeek && dayCounter <= daysInMonth; i++) {
        final day = dayCounter;
        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        final isInSelectedWeek = weekStart.isAtSameMomentAs(selectedWeekStart);

        weekDays.add(
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isInSelectedWeek
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Colors.transparent,
                border: isInSelectedWeek
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color: isInSelectedWeek
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isInSelectedWeek
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
        dayCounter++;
      }

      // Pad week with empty cells if needed
      while (weekDays.length < daysPerWeek) {
        weekDays.add(SizedBox(width: 40, height: 40, child: Container()));
      }

      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekDays,
        ),
      );
      weeks.add(const SizedBox(height: 8));
      weekCount++;
    }

    // Add empty rows to always have 6 rows
    while (weekCount < 6) {
      final emptyWeek = List.generate(
        daysPerWeek,
        (_) => SizedBox(width: 40, height: 40, child: Container()),
      );
      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emptyWeek,
        ),
      );
      if (weekCount < 5) {
        weeks.add(const SizedBox(height: 8));
      }
      weekCount++;
    }

    return weeks;
  }

  int _getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
