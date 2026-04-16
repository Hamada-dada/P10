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
        return 'Uge ${_getWeekNumber(focusedDate)}';

      case CalendarViewType.month:
        final month = months[focusedDate.month - 1];
        return '${month[0].toUpperCase()}${month.substring(1)} ${focusedDate.year}';
    }
  }

  int _getWeekNumber(DateTime date) {
    final thursday =
        date.add(Duration(days: 4 - (date.weekday == 7 ? 7 : date.weekday)));
    final firstJanuary = DateTime(thursday.year, 1, 1);
    final days = thursday.difference(firstJanuary).inDays;
    return ((days + firstJanuary.weekday - 1) / 7).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final titleFontSize = isLandscape ? 18.0 : 22.0;
    final metaFontSize = isLandscape ? 11.0 : 12.0;
    final iconSize = isLandscape ? 24.0 : 26.0;
    final smallGap = isLandscape ? 4.0 : 6.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onPrevious,
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: iconSize,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Text(
                _buildTitle(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: smallGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (viewType == CalendarViewType.day) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1A000000),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Uge ${_getWeekNumber(focusedDate)}',
                        style: TextStyle(
                          fontSize: metaFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: onToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD8D8D8),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'I dag',
                        style: TextStyle(
                          fontSize: metaFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (showFilter)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onFilterTap,
            icon: Icon(
              Icons.filter_alt_outlined,
              size: iconSize,
              color: Colors.black,
            ),
          )
        else
          SizedBox(width: iconSize),
        const SizedBox(width: 12),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onNext,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: iconSize,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}