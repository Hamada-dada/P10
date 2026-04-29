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
  return '$weekday ${focusedDate.day}/${focusedDate.month}';

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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final titleFontSize = isLandscape ? 24.0 : 26.0;
    final iconSize = isLandscape ? 26.0 : 28.0;
    final topSpacing = isLandscape ? 6.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: isLandscape ? 44 : 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onPrevious,
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: iconSize,
                    color: Colors.black,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 72),
                  child: Text(
                    _buildTitle(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Italiana',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showFilter)
                      IconButton(
                        onPressed: onFilterTap,
                        icon: Icon(
                          Icons.tune,
                          size: iconSize,
                          color: Colors.black,
                        ),
                      ),
                    IconButton(
                      onPressed: onNext,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: iconSize,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: topSpacing),
        Center(
          child: OutlinedButton(
            onPressed: onToday,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('I dag'),
          ),
        ),
      ],
    );
  }
}