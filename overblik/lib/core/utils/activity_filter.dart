import '../../models/activity.dart';

bool activityMatchesFilter({
  required Activity activity,
  required Set<String> selectedProfileIds,
  required bool showFamilyActivities,
}) {
  // Nothing selected = show nothing.
  if (selectedProfileIds.isEmpty && !showFamilyActivities) {
    return false;
  }

  final profileParticipantIds = activity.participants
      .map((participant) => participant.profileId)
      .whereType<String>()
      .toSet();

  final externalParticipantNames = activity.participants
      .map((participant) => participant.externalName?.trim())
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .toSet();

  final hasFamilyMarker = externalParticipantNames.contains('Familie');

  final hasExternalNonFamilyParticipant = externalParticipantNames.any(
    (name) => name != 'Familie',
  );

  final isFamilyActivity =
      activity.visibility == ActivityVisibility.family || hasFamilyMarker;

  final relatedToSelectedProfile =
      (activity.ownerProfileId != null &&
          selectedProfileIds.contains(activity.ownerProfileId)) ||
      profileParticipantIds.any(selectedProfileIds.contains);

  final hasMultipleProfileParticipants = profileParticipantIds.length > 1;

  final isSharedActivity =
      relatedToSelectedProfile &&
      (hasMultipleProfileParticipants || hasExternalNonFamilyParticipant);

  final isPersonalActivity =
      relatedToSelectedProfile &&
      !isFamilyActivity &&
      !hasMultipleProfileParticipants &&
      !hasExternalNonFamilyParticipant;

  final matchesPersonalProfileActivity =
      selectedProfileIds.isNotEmpty && isPersonalActivity;

  final matchesSharedOrFamilyActivity =
      showFamilyActivities && (isFamilyActivity || isSharedActivity);

  return matchesPersonalProfileActivity || matchesSharedOrFamilyActivity;
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