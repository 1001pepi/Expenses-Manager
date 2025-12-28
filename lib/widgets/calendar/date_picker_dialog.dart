import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'calendar_grid.dart';

class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String helpText;
  final Function(DateTime) onDateSelected;

  const CustomDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.helpText,
    required this.onDateSelected,
  });

  @override
  State<CustomDatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
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
                    _formatDate(_selectedDate),
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
            // Simple grid calendar view
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 320,
                child: CalendarGrid(
                  selectedDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onDateSelected: (DateTime date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
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

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  int _getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
