import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String helpText;
  final Function(DateTime) onDateSelected;

  const MonthPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.helpText,
    required this.onDateSelected,
  });

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  String _formatMonth(DateTime date) {
    final currentYear = DateTime.now().year;
    if (date.year == currentYear) {
      return _getMonthName(date.month);
    } else {
      return '${_getMonthName(date.month)} ${date.year}';
    }
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
                    _formatMonth(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Year selector with navigation arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year - 1,
                              _selectedDate.month,
                              1,
                            );
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      // Year dropdown
                      DropdownButton2<int>(
                        value: _selectedDate.year,
                        onChanged: (int? newYear) {
                          if (newYear != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                newYear,
                                _selectedDate.month,
                                1,
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
                          width: 100,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year + 1,
                              _selectedDate.month,
                              1,
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
            // Month grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMonthGrid(),
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

  Widget _buildMonthGrid() {
    return Column(
      children: [
        for (int row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 0; col < 3; col++)
                  _buildMonthCell(row * 3 + col + 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMonthCell(int month) {
    final isSelected = month == _selectedDate.month;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = DateTime(_selectedDate.year, month, 1);
        });
      },
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            _getMonthAbbr(month),
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
