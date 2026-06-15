import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _rewards = [];
  List<Map<String, dynamic>> _myRewards = [];
  bool _isLoading = true;
  int _userXP = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from(Tables.profiles)
            .select('xp_points')
            .eq('id', user.id)
            .single();

        final rewards = await Supabase.instance.client
            .from(Tables.rewards)
            .select()
            .eq('is_available', true)
            .order('points_required');

        final myRewards = await Supabase.instance.client
            .from('user_rewards')
            .select('*, rewards(*)')
            .eq('user_id', user.id);

        setState(() {
          _userXP = profile['xp_points'] ?? 0;
          _rewards = List<Map<String, dynamic>>.from(rewards);
          _myRewards = List<Map<String, dynamic>>.from(myRewards);
        });
      }
    } catch (e) {
      debugPrint('Error loading rewards: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isRedeemed(String rewardId) {
    return _myRewards.any((r) => r['reward_id'] == rewardId);
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final pointsRequired = reward['points_required'] ?? 0;

    if (_userXP < pointsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough XP! You need $pointsRequired XP but have $_userXP XP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Redeem ${reward['title']}?',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will cost $pointsRequired XP. You currently have $_userXP XP.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Redeem',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Deduct XP
        await Supabase.instance.client.from(Tables.profiles).update({
          'xp_points': _userXP - pointsRequired,
        }).eq('id', user.id);

        // Add to user rewards
        await Supabase.instance.client.from('user_rewards').insert({
          'user_id': user.id,
          'reward_id': reward['id'],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🎉 ${reward['title']} redeemed! -$pointsRequired XP'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        _loadData();
      }
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error redeeming reward. Try again!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final pointsRequired = reward['points_required'] ?? 0;
    final isRedeemed = _isRedeemed(reward['id']);
    final canAfford = _userXP >= pointsRequired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRedeemed
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRedeemed
              ? AppColors.accent.withOpacity(0.5)
              : canAfford
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reward['icon'] ?? '🎁',
                style: const TextStyle(fontSize: 28),
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
                  reward['title'],
                  style: TextStyle(
                    color: isRedeemed
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reward['description'] ?? '',
                  style: AppText.body.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '⭐ $pointsRequired XP',
                      style: TextStyle(
                        color: canAfford
                            ? AppColors.xpColor
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!canAfford && !isRedeemed) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Need ${pointsRequired - _userXP} more XP',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Button
          if (isRedeemed)
            const Icon(Icons.check_circle,
                color: AppColors.accent, size: 32)
          else
            GestureDetector(
              onTap: canAfford ? () => _redeemReward(reward) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: canAfford
                        ? AppColors.primary
                        : AppColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Redeem',
                  style: TextStyle(
                    color: canAfford
                        ? Colors.white
                        : AppColors.textSecondary,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Rewards Store',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.xpColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.xpColor.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_userXP XP',
                  style: const TextStyle(
                    color: AppColors.xpColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Store (${_rewards.length})'),
            Tab(text: 'My Rewards (${_myRewards.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                // Store tab
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // XP info banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Text('💡',
                                style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Complete challenges and habits to earn XP and redeem amazing eco-rewards!',
                                style:
                                    AppText.body.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._rewards.map(_buildRewardCard),
                    ],
                  ),
                ),

                // My Rewards tab
                _myRewards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎁',
                                style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            const Text('No rewards yet',
                                style: AppText.subheading),
                            const SizedBox(height: 8),
                            const Text(
                                'Earn XP and redeem your first reward!',
                                style: AppText.body),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myRewards.length,
                        itemBuilder: (context, index) {
                          final userReward = _myRewards[index];
                          final reward = userReward['rewards'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.accent
                                      .withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  reward?['icon'] ?? '🎁',
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reward?['title'] ?? 'Reward',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        reward?['description'] ?? '',
                                        style: AppText.body
                                            .copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle,
                                    color: AppColors.accent, size: 28),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}