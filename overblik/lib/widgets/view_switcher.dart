import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum CalendarScreenType {
  day,
  week,
  month,
}

class ViewSwitcher extends StatelessWidget {
  final CalendarScreenType selectedView;

  final VoidCallback? onDayTap;
  final VoidCallback? onWeekTap;
  final VoidCallback? onMonthTap;

  const ViewSwitcher({
    super.key,
    required this.selectedView,
    this.onDayTap,
    this.onWeekTap,
    this.onMonthTap,
  });

  void _handleTap(BuildContext context, CalendarScreenType targetView) {
    if (targetView == selectedView) return;

    switch (targetView) {
      case CalendarScreenType.day:
        if (onDayTap != null) {
          onDayTap!();
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }
        break;

      case CalendarScreenType.week:
        if (onWeekTap != null) {
          onWeekTap!();
        } else {
          Navigator.pushReplacementNamed(context, '/weekly');
        }
        break;

      case CalendarScreenType.month:
        if (onMonthTap != null) {
          onMonthTap!();
        } else {
          Navigator.pushReplacementNamed(context, '/monthly');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF101312)
            : const Color.fromRGBO(118, 118, 128, 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D2C) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          _Segment(
            label: l.viewDay,
            isSelected: selectedView == CalendarScreenType.day,
            onTap: () => _handleTap(context, CalendarScreenType.day),
          ),
          _Segment(
            label: l.viewWeek,
            isSelected: selectedView == CalendarScreenType.week,
            onTap: () => _handleTap(context, CalendarScreenType.week),
          ),
          _Segment(
            label: l.viewMonth,
            isSelected: selectedView == CalendarScreenType.month,
            onTap: () => _handleTap(context, CalendarScreenType.month),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final selectedBackground =
        isDark ? const Color(0xFF2A2D2C) : Colors.white;
    final selectedTextColor = isDark ? Colors.white : Colors.black;
    final unselectedTextColor =
        isDark ? Colors.white70 : colorScheme.onSurface;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: double.infinity,
            decoration: isSelected
                ? BoxDecoration(
                    color: selectedBackground,
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedTextColor : unselectedTextColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
