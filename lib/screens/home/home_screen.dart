import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _todayChallenge;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from(Tables.profiles)
            .select()
            .eq('id', user.id)
            .single();

        // Get a random active challenge
        final challenges = await Supabase.instance.client
            .from('challenges')
            .select()
            .eq('is_active', true)
            .limit(1);

        setState(() {
          _profile = profile;
          if ((challenges as List).isNotEmpty) {
            _todayChallenge = challenges[0];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading home data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name']?.split(' ')[0] ?? 'Greenie';
    final xp = _profile?['xp_points'] ?? 0;
    final streak = _profile?['streak_days'] ?? 0;
    final co2 = _profile?['co2_saved'] ?? 0;
    final energy = _profile?['energy_saved'] ?? 0;
    final water = _profile?['water_saved'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.accent),
            SizedBox(width: 8),
            Text('EcoTrack',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          // Notification bell
          StreamBuilder(
            stream: Supabase.instance.client
                .from('notifications')
                .stream(primaryKey: ['id'])
                .eq('user_id', Supabase.instance.client.auth.currentUser?.id ?? '')
                .order('created_at'),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                final data = snapshot.data as List;
                unreadCount = data.where((n) => n['is_read'] == false).length;
              }
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: AppColors.textSecondary),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          // XP display
          Container(
            margin: const EdgeInsets.only(right: 8),
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
                const Text('⭐',
                    style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: AppColors.xpColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout,
                color: AppColors.textSecondary, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(_getGreeting(), style: AppText.body),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$name 🌿', style: AppText.heading),
                        // Leaderboard button
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Text('🏆',
                                    style: TextStyle(fontSize: 14)),
                                SizedBox(width: 4),
                                Text(
                                  'Leaderboard',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Impact Today Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color:
                                AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Impact Today',
                                  style: AppText.subheading),
                              const Icon(Icons.arrow_forward_ios,
                                  color: AppColors.textSecondary,
                                  size: 14),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _impactItem(Icons.eco,
                                  '${co2.toStringAsFixed(2)} kg',
                                  'CO₂ Saved', Colors.green),
                              _impactItem(Icons.flash_on,
                                  '${energy.toStringAsFixed(2)} kWh',
                                  'Energy Saved', Colors.yellow),
                              _impactItem(Icons.water_drop,
                                  '${water.toStringAsFixed(0)} L',
                                  'Water Saved', Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Streak & XP row
                    Row(
                      children: [
                        // Streak card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('Daily Streak',
                                    style: AppText.body),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$streak Days',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const Text('🔥',
                                        style:
                                            TextStyle(fontSize: 28)),
                                  ],
                                ),
                                const Text('Keep it up!',
                                    style: AppText.body),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // XP card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('Total XP',
                                    style: AppText.body),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$xp XP',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.xpColor,
                                      ),
                                    ),
                                    const Text('⭐',
                                        style:
                                            TextStyle(fontSize: 28)),
                                  ],
                                ),
                                const Text('Keep earning!',
                                    style: AppText.body),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Today's Challenge Card
                    if (_todayChallenge != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Challenge",
                                style: AppText.body),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _todayChallenge!['icon'] ?? '🎯',
                                    style: const TextStyle(
                                        fontSize: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _todayChallenge!['title'] ??
                                            '',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '+${_todayChallenge!['xp_reward']} XP',
                                        style: const TextStyle(
                                            color: AppColors.xpColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Quick actions
                    const Text('Quick Actions',
                        style: AppText.subheading),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            '🎯',
                            'Challenges',
                            'Complete daily tasks',
                            () => Navigator.of(context).popUntil((route) => route.isFirst),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            '✅',
                            'Habits',
                            'Track your habits',
                            () => Navigator.of(context).popUntil((route) => route.isFirst),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _impactItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Text(label, style: AppText.body),
      ],
    );
  }

  Widget _quickAction(String emoji, String title, String subtitle,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: AppText.body.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
} 