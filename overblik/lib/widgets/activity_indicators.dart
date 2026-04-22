import 'package:flutter/material.dart';

import '../models/activity.dart';

class ActivityIndicators extends StatelessWidget {
  final List<Activity> activities;
  final Color Function(Activity activity) activityColorBuilder;
  final int maxDots;
  final int maxStars;
  final double dotSize;
  final double starSize;
  final double countFontSize;
  final double itemSpacing;
  final double sectionSpacing;
  final double verticalSpacing;

  const ActivityIndicators({
    super.key,
    required this.activities,
    required this.activityColorBuilder,
    this.maxDots = 3,
    this.maxStars = 2,
    this.dotSize = 8,
    this.starSize = 12,
    this.countFontSize = 10,
    this.itemSpacing = 3,
    this.sectionSpacing = 8,
    this.verticalSpacing = 4,
  });

  int _favoriteCount(List<Activity> activities) {
    return activities.where((activity) => activity.isFavorite).length;
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleActivities = activities.take(maxDots).toList();
    final hiddenActivityCount = activities.length - visibleActivities.length;

    final favoriteCount = _favoriteCount(activities);
    final visibleStarCount = favoriteCount > maxStars ? maxStars : favoriteCount;
    final hiddenStarCount = favoriteCount - visibleStarCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...visibleActivities.map(
              (activity) => Padding(
                padding: EdgeInsets.only(right: itemSpacing),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: activityColorBuilder(activity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (hiddenActivityCount > 0)
              Flexible(
                child: Text(
                  '+$hiddenActivityCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: countFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            if (favoriteCount > 0) SizedBox(width: sectionSpacing),
            if (favoriteCount > 0)
              ...List.generate(
                visibleStarCount,
                (_) => Padding(
                  padding: EdgeInsets.only(right: itemSpacing),
                  child: Icon(
                    Icons.star,
                    size: starSize,
                    color: Colors.amber,
                  ),
                ),
              ),
            if (hiddenStarCount > 0)
              Flexible(
                child: Text(
                  '+$hiddenStarCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: countFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}