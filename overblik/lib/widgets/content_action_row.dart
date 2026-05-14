import 'package:flutter/material.dart';

class ContentActionRow extends StatelessWidget {
  final bool canCreate;
  final bool isDisabled;
  final VoidCallback? onNew;
  final VoidCallback? onToday;
  final VoidCallback? onFilter;

  const ContentActionRow({
    super.key,
    required this.canCreate,
    this.isDisabled = false,
    this.onNew,
    this.onToday,
    this.onFilter,
  });

  static const _buttonStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final baseStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: canCreate
                      ? TextButton.icon(
                          onPressed: isDisabled ? null : onNew,
                          icon: Icon(Icons.add, size: 18, color: color),
                          label: Text(
                            'Ny aktivitet',
                            style: _buttonStyle.copyWith(color: color),
                          ),
                          style: baseStyle,
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Keeps left/right buttons away from the centered filter button.
              const SizedBox(width: 48),

              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: isDisabled ? null : onToday,
                    icon: Icon(Icons.today_outlined, size: 18, color: color),
                    label: Text(
                      'I dag',
                      style: _buttonStyle.copyWith(color: color),
                    ),
                    style: baseStyle,
                  ),
                ),
              ),
            ],
          ),

          // This is now centered relative to the whole row, not the remaining space.
          IconButton(
            onPressed: isDisabled ? null : onFilter,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(Icons.tune, size: 22, color: onSurface),
          ),
        ],
      ),
    );
  }
}