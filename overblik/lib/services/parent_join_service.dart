import 'package:supabase_flutter/supabase_flutter.dart';

enum ParentOnboardingStateType {
  activeParent,
  pendingParentRequest,
  needsOnboarding,
}

ParentOnboardingStateType parentOnboardingStateTypeFromString(String value) {
  switch (value) {
    case 'active_parent':
      return ParentOnboardingStateType.activeParent;
    case 'pending_parent_request':
      return ParentOnboardingStateType.pendingParentRequest;
    case 'needs_onboarding':
    default:
      return ParentOnboardingStateType.needsOnboarding;
  }
}

class ParentOnboardingState {
  final ParentOnboardingStateType state;

  final String? profileId;
  final String? familyId;
  final String? familyName;
  final String? familyCode;

  final String? requestId;
  final String? requestStatus;

  const ParentOnboardingState({
    required this.state,
    this.profileId,
    this.familyId,
    this.familyName,
    this.familyCode,
    this.requestId,
    this.requestStatus,
  });

  factory ParentOnboardingState.fromMap(Map<String, dynamic> map) {
    return ParentOnboardingState(
      state: parentOnboardingStateTypeFromString(
        map['state'] as String? ?? 'needs_onboarding',
      ),
      profileId: map['profile_id'] as String?,
      familyId: map['family_id'] as String?,
      familyName: map['family_name'] as String?,
      familyCode: map['family_code'] as String?,
      requestId: map['request_id'] as String?,
      requestStatus: map['request_status'] as String?,
    );
  }
}

class ParentJoinRequestResult {
  final String requestId;
  final String familyId;
  final String familyName;
  final String status;

  const ParentJoinRequestResult({
    required this.requestId,
    required this.familyId,
    required this.familyName,
    required this.status,
  });

  factory ParentJoinRequestResult.fromMap(Map<String, dynamic> map) {
    return ParentJoinRequestResult(
      requestId: map['request_id'] as String,
      familyId: map['family_id'] as String,
      familyName: map['family_name'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }
}

class RemovedParentResult {
  final String removedProfileId;
  final String familyId;
  final String name;
  final String displayName;
  final bool isActive;

  const RemovedParentResult({
    required this.removedProfileId,
    required this.familyId,
    required this.name,
    required this.displayName,
    required this.isActive,
  });

  factory RemovedParentResult.fromMap(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    final displayName = map['display_name'] as String?;

    return RemovedParentResult(
      removedProfileId: map['removed_profile_id'] as String,
      familyId: map['family_id'] as String,
      name: name,
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!
          : name,
      isActive: map['is_active'] as bool? ?? false,
    );
  }
}

class ParentJoinRequest {
  final String requestId;
  final String familyId;

  final String requestedName;
  final String requestedDisplayName;
  final String requestedEmoji;

  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ParentJoinRequest({
    required this.requestId,
    required this.familyId,
    required this.requestedName,
    required this.requestedDisplayName,
    required this.requestedEmoji,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentJoinRequest.fromMap(Map<String, dynamic> map) {
    final requestedName = map['requested_name'] as String? ?? '';
    final requestedDisplayName = map['requested_display_name'] as String?;

    return ParentJoinRequest(
      requestId: map['request_id'] as String,
      familyId: map['family_id'] as String,
      requestedName: requestedName,
      requestedDisplayName: requestedDisplayName?.trim().isNotEmpty == true
          ? requestedDisplayName!
          : requestedName,
      requestedEmoji: map['requested_emoji'] as String? ?? '🙂',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}

class ParentJoinService {
  final SupabaseClient _client;

  ParentJoinService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  Future<ParentOnboardingState> getParentOnboardingState() async {
    final result = await _client.rpc('get_parent_onboarding_state');

    final rows = result as List;

    if (rows.isEmpty) {
      return const ParentOnboardingState(
        state: ParentOnboardingStateType.needsOnboarding,
      );
    }

    final row = Map<String, dynamic>.from(rows.first as Map);

    return ParentOnboardingState.fromMap(row);
  }

  Future<ParentJoinRequestResult> requestParentJoin({
    required String familyCode,
    required String name,
    String? displayName,
    String emoji = '🙂',
  }) async {
    final result = await _client.rpc(
      'request_parent_join',
      params: {
        'p_family_code': familyCode.trim().toUpperCase(),
        'p_name': name.trim(),
        'p_display_name': displayName?.trim(),
        'p_emoji': emoji.trim().isEmpty ? '🙂' : emoji.trim(),
      },
    );

    final rows = result as List;

    if (rows.isEmpty) {
      throw Exception('Kunne ikke oprette anmodning.');
    }

    final row = Map<String, dynamic>.from(rows.first as Map);

    return ParentJoinRequestResult.fromMap(row);
  }

  Future<List<ParentJoinRequest>> getJoinRequestsForFamily(
    String familyId,
  ) async {
    final result = await _client.rpc(
      'get_parent_join_requests_for_family',
      params: {
        'p_family_id': familyId,
      },
    );

    final rows = List<Map<String, dynamic>>.from(result as List);

    return rows.map(ParentJoinRequest.fromMap).toList();
  }

  Future<void> approveJoinRequest(String requestId) async {
    await _client.rpc(
      'approve_parent_join_request',
      params: {
        'p_request_id': requestId,
      },
    );
  }

  Future<void> rejectJoinRequest(String requestId) async {
    await _client.rpc(
      'reject_parent_join_request',
      params: {
        'p_request_id': requestId,
      },
    );
  }

  Future<void> cancelMyJoinRequest(String requestId) async {
    await _client.rpc(
      'cancel_my_parent_join_request',
      params: {
        'p_request_id': requestId,
      },
    );
  }

  Future<RemovedParentResult> removeParentFromFamily(String profileId) async {
    final result = await _client.rpc(
      'remove_parent_from_family',
      params: {
        'p_profile_id': profileId,
      },
    );

    final rows = result as List;

    if (rows.isEmpty) {
      throw Exception('Kunne ikke fjerne forælderen.');
    }

    final row = Map<String, dynamic>.from(rows.first as Map);

    return RemovedParentResult.fromMap(row);
  }
}