import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _challenges = [];
  List<Map<String, dynamic>> _userChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final challenges = await Supabase.instance.client
            .from('challenges')
            .select()
            .eq('is_active', true)
            .order('xp_reward');

        final userChallenges = await Supabase.instance.client
            .from('user_challenges')
            .select()
            .eq('user_id', user.id);

        setState(() {
          _challenges = List<Map<String, dynamic>>.from(challenges);
          _userChallenges = List<Map<String, dynamic>>.from(userChallenges);
        });
      }
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isChallengeAccepted(String challengeId) {
    return _userChallenges.any((uc) => uc['challenge_id'] == challengeId);
  }

  bool _isChallengeCompleted(String challengeId) {
    return _userChallenges.any((uc) =>
        uc['challenge_id'] == challengeId && uc['is_completed'] == true);
  }

  Future<void> _acceptChallenge(String challengeId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_challenges').insert({
          'user_id': user.id,
          'challenge_id': challengeId,
        });
        _loadChallenges();
      }
    } catch (e) {
      debugPrint('Error accepting challenge: $e');
    }
  }

  Future<void> _completeChallenge(
      String userChallengeId, String challengeId, int xpReward) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('user_challenges')
            .update({
              'is_completed': true,
              'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id)
            .eq('challenge_id', challengeId);

        // Add XP to user profile
        final profile = await Supabase.instance.client
            .from(Tables.profiles)
            .select('xp_points')
            .eq('id', user.id)
            .single();

        await Supabase.instance.client.from(Tables.profiles).update({
          'xp_points': (profile['xp_points'] ?? 0) + xpReward,
        }).eq('id', user.id);

        // Send notification
        await Supabase.instance.client.from('notifications').insert({
          'user_id': user.id,
          'title': 'Challenge Completed! 🎯',
          'message': 'You earned $xpReward XP! Keep up the great work!',
          'type': 'challenge',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Challenge completed! +$xpReward XP earned!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        _loadChallenges();
      }
    } catch (e) {
      debugPrint('Error completing challenge: $e');
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final challengeId = challenge['id'];
    final isAccepted = _isChallengeAccepted(challengeId);
    final isCompleted = _isChallengeCompleted(challengeId);
    final difficulty = challenge['difficulty'] ?? 'easy';
    final xpReward = challenge['xp_reward'] ?? 30;

    final userChallenge = _userChallenges.firstWhere(
      (uc) => uc['challenge_id'] == challengeId,
      orElse: () => {},
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppColors.accent.withOpacity(0.5)
              : isAccepted
                  ? AppColors.primary.withOpacity(0.6)
                  : AppColors.primary.withOpacity(0.2),
          width: isAccepted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                challenge['icon'] ?? '🎯',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['title'],
                  style: TextStyle(
                    color: isCompleted
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge['description'] ?? '',
                  style: AppText.body.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '+$xpReward XP',
                      style: const TextStyle(
                        color: AppColors.xpColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(difficulty)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        difficulty.toUpperCase(),
                        style: TextStyle(
                          color: _getDifficultyColor(difficulty),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action button
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.accent, size: 32)
          else if (isAccepted)
            GestureDetector(
              onTap: () => _completeChallenge(
                userChallenge['id'] ?? '',
                challengeId,
                xpReward,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _acceptChallenge(challengeId),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedChallenges =
        _challenges.where((c) => _isChallengeCompleted(c['id'])).toList();
    final activeChallenges =
        _challenges.where((c) => _isChallengeAccepted(c['id']) && !_isChallengeCompleted(c['id'])).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Challenges',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'All Challenges'),
            Tab(text: 'My Challenges'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                // All Challenges Tab
                RefreshIndicator(
                  onRefresh: _loadChallenges,
                  color: AppColors.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats row
                      Row(
                        children: [
                          _statChip(
                              '${_challenges.length}', 'Total', Icons.flag),
                          const SizedBox(width: 10),
                          _statChip('${activeChallenges.length}', 'Active',
                              Icons.play_arrow),
                          const SizedBox(width: 10),
                          _statChip('${completedChallenges.length}',
                              'Done', Icons.check),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._challenges.map(_buildChallengeCard),
                    ],
                  ),
                ),

                // My Challenges Tab
                _userChallenges.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎯',
                                style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            const Text('No active challenges',
                                style: AppText.subheading),
                            const SizedBox(height: 8),
                            const Text('Accept a challenge to get started!',
                                style: AppText.body),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: _challenges
                            .where((c) => _isChallengeAccepted(c['id']))
                            .map(_buildChallengeCard)
                            .toList(),
                      ),
              ],
            ),
    );
  }

  Widget _statChip(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(label, style: AppText.body.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}