import 'package:flutter/material.dart';

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
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(118, 118, 128, 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Dag',
            isSelected: selectedView == CalendarScreenType.day,
            onTap: () => _handleTap(context, CalendarScreenType.day),
          ),
          _Segment(
            label: 'Uge',
            isSelected: selectedView == CalendarScreenType.week,
            onTap: () => _handleTap(context, CalendarScreenType.week),
          ),
          _Segment(
            label: 'Måned',
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}