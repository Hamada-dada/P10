import 'package:flutter/material.dart';

enum CalendarView { day, week, month }

class ViewSwitcher extends StatelessWidget {
  final CalendarView selectedView;
  final ValueChanged<CalendarView>? onChanged;

  const ViewSwitcher({
    super.key,
    required this.selectedView,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(118, 118, 128, 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'Dag',
            selected: selectedView == CalendarView.day,
            onTap: () => onChanged?.call(CalendarView.day),
          ),
          _SegmentButton(
            label: 'Uge',
            selected: selectedView == CalendarView.week,
            onTap: () => onChanged?.call(CalendarView.week),
          ),
          _SegmentButton(
            label: 'Måned',
            selected: selectedView == CalendarView.month,
            onTap: () => onChanged?.call(CalendarView.month),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: selected
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
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}