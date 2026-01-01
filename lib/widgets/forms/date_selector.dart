import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../calendar/date_picker_dialog.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String helpText;

  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.helpText = 'Select Date',
  }) : super(key: key);

  String _formatDate(DateTime date) => DateFormat('d MMMM y').format(date);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          Icons.calendar_month,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picked = await showDialog<DateTime>(
              context: context,
              builder: (context) => CustomDatePickerDialog(
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                helpText: helpText,
                onDateSelected: (_) {},
              ),
            );
            if (picked != null) onDateSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDate(selectedDate),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
