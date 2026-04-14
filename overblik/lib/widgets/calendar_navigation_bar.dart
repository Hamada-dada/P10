import 'package:flutter/material.dart';

enum CalendarViewType {
  day,
  week,
  month,
}

class CalendarNavigationBar extends StatelessWidget {
  final DateTime focusedDate;
  final CalendarViewType viewType;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final VoidCallback? onFilterTap;
  final bool showFilter;

  const CalendarNavigationBar({
    super.key,
    required this.focusedDate,
    required this.viewType,
    this.onPrevious,
    this.onNext,
    this.onToday,
    this.onFilterTap,
    this.showFilter = true,
  });

  String _buildTitle() {
    const weekdays = [
      'Mandag',
      'Tirsdag',
      'Onsdag',
      'Torsdag',
      'Fredag',
      'Lørdag',
      'Søndag',
    ];

    const months = [
      'januar',
      'februar',
      'marts',
      'april',
      'maj',
      'juni',
      'juli',
      'august',
      'september',
      'oktober',
      'november',
      'december',
    ];

    switch (viewType) {
      case CalendarViewType.day:
        final weekday = weekdays[focusedDate.weekday - 1];
        final month = months[focusedDate.month - 1];
        return '$weekday d. ${focusedDate.day}. $month';

      case CalendarViewType.week:
        final weekNumber = _getWeekNumber(focusedDate);
        return 'Uge $weekNumber';

      case CalendarViewType.month:
        final month = months[focusedDate.month - 1];
        return '${month[0].toUpperCase()}${month.substring(1)} ${focusedDate.year}';
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final difference = date.difference(firstMonday).inDays;
    return (difference / 7).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _buildTitle(),
                  style: const TextStyle(
                    fontFamily: 'Italiana',
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            if (showFilter)
              IconButton(
                onPressed: onFilterTap,
                icon: const Icon(Icons.filter_alt_outlined, size: 24, color: Colors.black),
              )
            else
              const SizedBox(width: 48),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: onToday,
            child: const Text(
              'I dag',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}