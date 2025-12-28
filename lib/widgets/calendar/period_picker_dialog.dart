import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class PeriodPickerDialog extends StatefulWidget {
  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final String helpText;
  final Function(DateTimeRange) onRangeSelected;

  const PeriodPickerDialog({
    super.key,
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
    required this.helpText,
    required this.onRangeSelected,
  });

  @override
  State<PeriodPickerDialog> createState() => _PeriodPickerDialogState();
}

class _PeriodPickerDialogState extends State<PeriodPickerDialog> {
  late DateTime _displayedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isAllTime = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialRange.start;
    _endDate = widget.initialRange.end;
    _displayedMonth = _startDate != null
        ? DateTime(_startDate!.year, _startDate!.month, 1)
        : DateTime.now();
  }

  InlineSpan _rangeSpan() {
    final primary = Theme.of(context).colorScheme.primary;
    final baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );

    if (_isAllTime) {
      return TextSpan(
        text: 'All time',
        style: baseStyle.copyWith(color: primary, fontWeight: FontWeight.w700),
      );
    }

    if (_startDate == null) {
      return TextSpan(text: 'Select start date', style: baseStyle);
    }

    final startText =
        '${_startDate!.day} ${_getMonthAbbr(_startDate!.month)} ${_startDate!.year}';

    if (_endDate == null) {
      return TextSpan(
        children: [
          TextSpan(
            text: startText,
            style: baseStyle.copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: ' - '),
          TextSpan(text: 'Select end date', style: baseStyle),
        ],
        style: baseStyle,
      );
    }

    final endText =
        '${_endDate!.day} ${_getMonthAbbr(_endDate!.month)} ${_endDate!.year}';
    return TextSpan(
      children: [
        TextSpan(
          text: startText,
          style: baseStyle.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: ' - ', style: baseStyle),
        TextSpan(
          text: endText,
          style: baseStyle.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
      style: baseStyle,
    );
  }

  void _resetSelection() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isAllTime = false;
      _displayedMonth = DateTime.now();
    });
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
                  Text.rich(_rangeSpan()),
                  const SizedBox(height: 8),
                  // All time checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isAllTime,
                        onChanged: (bool? value) {
                          setState(() {
                            _isAllTime = value ?? false;
                          });
                        },
                      ),
                      const Text('All time'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Month selector with navigation arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left),
                        onPressed: _isAllTime
                            ? null
                            : () {
                                setState(() {
                                  final prevMonth = _displayedMonth.month - 1;
                                  final year = prevMonth < 1
                                      ? _displayedMonth.year - 1
                                      : _displayedMonth.year;
                                  final month = prevMonth < 1 ? 12 : prevMonth;
                                  _displayedMonth = DateTime(year, month, 1);
                                });
                              },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                      // Month dropdown
                      DropdownButton2<int>(
                        value: _displayedMonth.month,
                        onChanged: _isAllTime
                            ? null
                            : (int? newMonth) {
                                if (newMonth != null) {
                                  setState(() {
                                    _displayedMonth = DateTime(
                                      _displayedMonth.year,
                                      newMonth,
                                      1,
                                    );
                                  });
                                }
                              },
                        items: List.generate(12, (index) => index + 1)
                            .map(
                              (month) => DropdownMenuItem(
                                value: month,
                                child: Text(_getMonthName(month)),
                              ),
                            )
                            .toList(),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          isOverButton: false,
                          offset: const Offset(0, 5),
                          width: 120,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Year dropdown
                      DropdownButton2<int>(
                        value: _displayedMonth.year,
                        onChanged: _isAllTime
                            ? null
                            : (int? newYear) {
                                if (newYear != null) {
                                  setState(() {
                                    _displayedMonth = DateTime(
                                      newYear,
                                      _displayedMonth.month,
                                      1,
                                    );
                                  });
                                }
                              },
                        items: _generateYearList()
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ),
                            )
                            .toList(),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          isOverButton: false,
                          offset: const Offset(0, 5),
                          width: 90,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right),
                        onPressed: _isAllTime
                            ? null
                            : () {
                                setState(() {
                                  final nextMonth = _displayedMonth.month + 1;
                                  final year = nextMonth > 12
                                      ? _displayedMonth.year + 1
                                      : _displayedMonth.year;
                                  final month = nextMonth > 12 ? 1 : nextMonth;
                                  _displayedMonth = DateTime(year, month, 1);
                                });
                              },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalendar(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _resetSelection,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 8),
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
                    onPressed:
                        (_isAllTime || (_startDate != null && _endDate != null))
                        ? () {
                            if (_isAllTime) {
                              Navigator.pop(
                                context,
                                DateTimeRange(
                                  start: widget.firstDate,
                                  end: widget.lastDate,
                                ),
                              );
                            } else {
                              Navigator.pop(
                                context,
                                DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                ),
                              );
                            }
                          }
                        : null,
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

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    );

    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Build header row
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final children = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dayNames
            .map(
              (dayName) => Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 4),
    ];

    // Build week rows (always 6 rows)
    int weekCount = 0;
    int dayCounter = 1;
    const daysPerWeek = 7;

    // First week: leading blanks then days
    final firstWeek = <Widget>[];
    for (int i = 1; i < firstWeekday; i++) {
      firstWeek.add(const SizedBox(width: 36, height: 36));
    }
    while (firstWeek.length < daysPerWeek && dayCounter <= daysInMonth) {
      firstWeek.add(_buildDayCell(dayCounter));
      dayCounter++;
    }
    while (firstWeek.length < daysPerWeek) {
      firstWeek.add(const SizedBox(width: 36, height: 36));
    }
    children.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: firstWeek,
      ),
    );
    // Add spacer only if not the last row (target: 5 spacers total)
    if (weekCount < 5) {
      children.add(const SizedBox(height: 4));
    }
    weekCount++;

    // Remaining weeks
    while (dayCounter <= daysInMonth) {
      final weekDays = <Widget>[];
      for (int i = 0; i < daysPerWeek && dayCounter <= daysInMonth; i++) {
        weekDays.add(_buildDayCell(dayCounter));
        dayCounter++;
      }
      while (weekDays.length < daysPerWeek) {
        weekDays.add(const SizedBox(width: 36, height: 36));
      }
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekDays,
        ),
      );
      if (weekCount < 5) {
        children.add(const SizedBox(height: 4));
      }
      weekCount++;
    }

    // Pad with empty weeks to always have 6 rows
    while (weekCount < 6) {
      final emptyWeek = List.generate(
        daysPerWeek,
        (_) => const SizedBox(width: 36, height: 36),
      );
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emptyWeek,
        ),
      );
      if (weekCount < 5) {
        children.add(const SizedBox(height: 4));
      }
      weekCount++;
    }

    return Column(children: children);
  }

  Widget _buildDayCell(int day) {
    final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
    final isInRange =
        _startDate != null &&
        _endDate != null &&
        date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_endDate!.add(const Duration(days: 1)));
    final isStart = _startDate != null && _isSameDay(date, _startDate!);
    final isEnd = _endDate != null && _isSameDay(date, _endDate!);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_startDate == null) {
            _startDate = date;
            _endDate = null;
          } else if (_endDate != null) {
            _startDate = date;
            _endDate = null;
          } else if (_isSameDay(date, _startDate!)) {
            _startDate = null;
            _endDate = null;
          } else {
            if (date.isBefore(_startDate!)) {
              _endDate = _startDate;
              _startDate = date;
            } else {
              _endDate = date;
            }
          }
        });
      },
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (isStart || isEnd)
              ? Theme.of(context).colorScheme.primary
              : isInRange
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          day.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: (isStart || isEnd)
                ? FontWeight.w600
                : FontWeight.normal,
            color: (isStart || isEnd)
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
}
