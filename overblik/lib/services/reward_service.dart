import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reward.dart';

class RewardService {
  RewardService._internal();

  static final RewardService _instance = RewardService._internal();

  factory RewardService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Reward> _cachedRewards = [];
  String? _cachedFamilyId;

  List<Reward> get cachedRewards => List.unmodifiable(_cachedRewards);

  Future<String?> _getFamilyId() async {
    if (_cachedFamilyId != null) return _cachedFamilyId;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final result = await _supabase
          .from('profiles')
          .select('family_id')
          .eq('auth_user_id', userId)
          .single();
      _cachedFamilyId = result['family_id'] as String?;
      return _cachedFamilyId;
    } catch (_) {
      return null;
    }
  }

  void clearCache() {
    _cachedFamilyId = null;
    _cachedRewards = [];
  }

  Future<List<Reward>> getAllRewards() async {
    final familyId = await _getFamilyId();

    var query = _supabase.from('rewards').select();
    if (familyId != null) {
      query = query.eq('family_id', familyId);
    }
    final result = await query.order('created_at', ascending: false);

    final rewards = (result as List)
        .map((item) => Reward.fromMap(item))
        .toList();

    _cachedRewards = rewards;

    return rewards;
  }

  Future<Reward?> getRewardById(String id) async {
    try {
      final result = await _supabase
          .from('rewards')
          .select()
          .eq('id', id)
          .single();

      return Reward.fromMap(result);
    } catch (_) {
      return null;
    }
  }

  Future<List<Reward>> getRewardsForProfile(String profileId) async {
    final familyId = await _getFamilyId();

    var query = _supabase
        .from('rewards')
        .select()
        .eq('profile_id', profileId);
    if (familyId != null) {
      query = query.eq('family_id', familyId);
    }
    final result = await query.order('created_at');

    return (result as List)
        .map((item) => Reward.fromMap(item))
        .toList();
  }

  Future<List<Reward>> getRewardsForProfileAndType(
      String profileId,
      RewardType type,
      ) async {
    final familyId = await _getFamilyId();
    final rewardType = type == RewardType.direct ? 'direct' : 'streak';

    var query = _supabase
        .from('rewards')
        .select()
        .eq('profile_id', profileId)
        .eq('reward_type', rewardType);
    if (familyId != null) {
      query = query.eq('family_id', familyId);
    }
    final result = await query.order('created_at');

    return (result as List)
        .map((item) => Reward.fromMap(item))
        .toList();
  }

  Future<void> addReward(Reward reward) async {
    await _supabase
        .from('rewards')
        .insert(reward.toInsertMap());

    await getAllRewards();
  }

  Future<void> updateReward(Reward reward) async {
    await _supabase
        .from('rewards')
        .update(reward.toInsertMap())
        .eq('id', reward.id);

    await getAllRewards();
  }

  Future<void> deleteReward(String rewardId) async {
    await _supabase
        .from('activities')
        .update({
      'direct_reward_id': null,
      'streak_reward_id': null,
    })
        .or('direct_reward_id.eq.$rewardId,streak_reward_id.eq.$rewardId');

    await _supabase
        .from('rewards')
        .delete()
        .eq('id', rewardId);

    _cachedRewards.removeWhere((reward) => reward.id == rewardId);
  }

  Future<void> updateRewardProgress({
    required String rewardId,
    required int delta,
  }) async {
    await _supabase.rpc(
      'update_reward_progress',
      params: {
        'input_reward_id': rewardId,
        'input_delta': delta,
      },
    );

    await getAllRewards();
  }
}