import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaders = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, username, xp_points, level, streak_days')
          .order('xp_points', ascending: false)
          .limit(20);

      setState(() {
        _leaders = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getEcoTitle(int xp) {
    if (xp >= 1000) return 'Eco Master';
    if (xp >= 500) return 'Green Champion';
    if (xp >= 200) return 'Eco Warrior';
    if (xp >= 100) return 'Green Starter';
    return 'Eco Newbie';
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return AppColors.textSecondary;
    }
  }

  String _getAvatarEmoji(int xp) {
    if (xp >= 1000) return '🌍';
    if (xp >= 500) return '🏆';
    if (xp >= 200) return '⚔️';
    if (xp >= 100) return '🌱';
    return '🌿';
  }

  @override
  Widget build(BuildContext context) {
    // Find current user rank
    final myRank = _leaders.indexWhere((l) => l['id'] == _currentUserId) + 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Leaderboard',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // My rank card
                  if (myRank > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              color: AppColors.accent, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Your Rank',
                                    style: AppText.body),
                                Text(
                                  myRank <= 3
                                      ? _getRankEmoji(myRank)
                                      : 'Rank #$myRank',
                                  style: TextStyle(
                                    color: _getRankColor(myRank),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_leaders[myRank - 1]['xp_points']} XP',
                                style: const TextStyle(
                                  color: AppColors.xpColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _getEcoTitle(
                                    _leaders[myRank - 1]['xp_points']),
                                style: AppText.body.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Top 3 podium
                  if (_leaders.length >= 3) ...[
                    const Text('🏆 Top Eco Warriors',
                        style: AppText.subheading),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 2nd place
                        _podiumItem(_leaders[1], 2, 80),
                        // 1st place
                        _podiumItem(_leaders[0], 1, 110),
                        // 3rd place
                        _podiumItem(_leaders[2], 3, 60),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Full list
                  const Text('All Rankings', style: AppText.subheading),
                  const SizedBox(height: 12),
                  ..._leaders.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final leader = entry.value;
                    final isMe = leader['id'] == _currentUserId;
                    final xp = leader['xp_points'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMe
                              ? AppColors.accent.withOpacity(0.5)
                              : AppColors.primary.withOpacity(0.2),
                          width: isMe ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rank
                          SizedBox(
                            width: 36,
                            child: rank <= 3
                                ? Text(
                                    _getRankEmoji(rank),
                                    style: const TextStyle(fontSize: 22),
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    '#$rank',
                                    style: TextStyle(
                                      color: _getRankColor(rank),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                          const SizedBox(width: 10),

                          // Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.2),
                              border: Border.all(
                                color: isMe
                                    ? AppColors.accent
                                    : AppColors.primary.withOpacity(0.4),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getAvatarEmoji(xp),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name & title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      leader['full_name'] ?? 'EcoUser',
                                      style: TextStyle(
                                        color: isMe
                                            ? AppColors.accent
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _getEcoTitle(xp),
                                  style:
                                      AppText.body.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),

                          // XP & streak
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$xp XP',
                                style: const TextStyle(
                                  color: AppColors.xpColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '🔥 ${leader['streak_days'] ?? 0}',
                                style: AppText.body.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _podiumItem(
      Map<String, dynamic> leader, int rank, double height) {
    final xp = leader['xp_points'] ?? 0;
    final isMe = leader['id'] == _currentUserId;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(_getAvatarEmoji(xp),
            style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          leader['full_name']?.split(' ')[0] ?? 'Eco',
          style: TextStyle(
            color: isMe ? AppColors.accent : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$xp XP',
          style: const TextStyle(
              color: AppColors.xpColor,
              fontSize: 11),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: rank == 1
                ? const Color(0xFFFFD700).withOpacity(0.2)
                : rank == 2
                    ? const Color(0xFFC0C0C0).withOpacity(0.2)
                    : const Color(0xFFCD7F32).withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: rank == 1
                  ? const Color(0xFFFFD700).withOpacity(0.5)
                  : rank == 2
                      ? const Color(0xFFC0C0C0).withOpacity(0.5)
                      : const Color(0xFFCD7F32).withOpacity(0.5),
            ),
          ),
          child: Center(
            child: Text(
              _getRankEmoji(rank),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ],
    );
  }
}