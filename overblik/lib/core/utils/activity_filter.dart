import '../../models/activity.dart';

bool activityMatchesFilter({
  required Activity activity,
  required Set<String> selectedProfileIds,
  required bool showFamilyActivities,
}) {
  // No selected filters should show nothing.
  // This avoids confusing "empty filter = everything" behavior.
  if (selectedProfileIds.isEmpty && !showFamilyActivities) {
    return false;
  }

  final matchesSelectedProfile = selectedProfileIds.any((profileId) {
    final matchesOwner = activity.ownerProfileId == profileId;

    final matchesParticipant = activity.participants.any((participant) {
      return participant.profileId == profileId;
    });

    return matchesOwner || matchesParticipant;
  });

  final matchesFamily =
      showFamilyActivities &&
      activity.visibility == ActivityVisibility.family;

  return matchesSelectedProfile || matchesFamily;
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