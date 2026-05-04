import '../../models/activity.dart';

bool activityMatchesFilter({
  required Activity activity,
  required Set<String> selectedProfileIds,
  required bool showFamilyActivities,
}) {
  // No active filter = show everything.
  if (selectedProfileIds.isEmpty && !showFamilyActivities) {
    return true;
  }

  final matchesParticipant = activity.participants.any((participant) {
    return participant.profileId != null &&
        selectedProfileIds.contains(participant.profileId);
  });

  final matchesOwner = activity.ownerProfileId != null &&
      selectedProfileIds.contains(activity.ownerProfileId);

  final matchesFamily = showFamilyActivities &&
      (activity.visibility == ActivityVisibility.family ||
          activity.participants.any(
            (participant) => participant.externalName == 'Familie',
          ));

  return matchesParticipant || matchesOwner || matchesFamily;
}

List<Activity> filterActivities({
  required List<Activity> activities,
  required Set<String> selectedProfileIds,
  required bool showFamilyActivities,
}) {
  return activities.where((activity) {
    return activityMatchesFilter(
      activity: activity,
      selectedProfileIds: selectedProfileIds,
      showFamilyActivities: showFamilyActivities,
    );
  }).toList();
}