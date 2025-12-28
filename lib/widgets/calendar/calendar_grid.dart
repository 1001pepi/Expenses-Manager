import 'package:flutter/material.dart';

class CalendarGrid extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onDateSelected;

  const CalendarGrid({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    final lastDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month + 1,
      0,
    );
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

    // First week with leading empty cells
    final firstWeek = <Widget>[];
    // Add leading empty cells
    for (int i = 1; i < firstWeekday; i++) {
      firstWeek.add(SizedBox(width: 40, height: 40, child: Container()));
    }

    // Add days for first week
    while (firstWeek.length < daysPerWeek && dayCounter <= daysInMonth) {
      final day = dayCounter;
      final date = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        day,
      );
      final isSelected = day == widget.selectedDate.day;

      firstWeek.add(
        GestureDetector(
          onTap: () {
            widget.onDateSelected(date);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        final date = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          day,
        );
        final isSelected = day == widget.selectedDate.day;

        weekDays.add(
          GestureDetector(
            onTap: () {
              widget.onDateSelected(date);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected
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
}
