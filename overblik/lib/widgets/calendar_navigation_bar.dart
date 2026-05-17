import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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

  String _buildTitle(BuildContext context) {
    final l = AppLocalizations.of(context);

    switch (viewType) {
      case CalendarViewType.day:
        final weekday = l.weekdayNames[focusedDate.weekday - 1];
        return '$weekday ${focusedDate.day}/${focusedDate.month}';

      case CalendarViewType.week:
        final weekNumber = _getWeekNumber(focusedDate);
        return l.weekLabel(weekNumber);

      case CalendarViewType.month:
        final month = l.monthNames[focusedDate.month - 1];
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

    final colorScheme = Theme.of(context).colorScheme;

    final titleFontSize = isLandscape ? 22.0 : 24.0;
    final iconSize = isLandscape ? 24.0 : 26.0;

    final mainColor = colorScheme.onSurface;

    return SizedBox(
      height: isLandscape ? 44 : 48,
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: iconSize,
              color: mainColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _buildTitle(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Italiana',
                fontSize: titleFontSize,
                fontWeight: FontWeight.w400,
                color: mainColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onNext,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: iconSize,
              color: mainColor,
            ),
          ),
        ],
      ),
    );
  }
}
