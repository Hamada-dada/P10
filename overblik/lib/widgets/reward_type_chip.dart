import 'package:flutter/material.dart';

class RewardTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const RewardTypeChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.primary.withValues(alpha: 0.14)
            : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.35)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark
                ? colorScheme.primary
                : Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? colorScheme.onSurface
                  : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}