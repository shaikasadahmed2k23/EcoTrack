import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../rewards/rewards_screen.dart';
import '../donations/donations_screen.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  int _completedChallenges = 0;
  int _completedHabits = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from(Tables.profiles)
            .select()
            .eq('id', user.id)
            .single();

        final challenges = await Supabase.instance.client
            .from('user_challenges')
            .select()
            .eq('user_id', user.id)
            .eq('is_completed', true);

        final habits = await Supabase.instance.client
            .from(Tables.habits)
            .select()
            .eq('user_id', user.id)
            .eq('is_completed', true);

        setState(() {
          _profile = profile;
          _completedChallenges = (challenges as List).length;
          _completedHabits = (habits as List).length;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  String _getEcoTitle(int xp) {
    if (xp >= 1000) return 'Eco Master 🌍';
    if (xp >= 500) return 'Green Champion 🏆';
    if (xp >= 200) return 'Eco Warrior ⚔️';
    if (xp >= 100) return 'Green Starter 🌱';
    return 'Eco Newbie 🌿';
  }

  Color _getEcoTitleColor(int xp) {
    if (xp >= 1000) return Colors.purple;
    if (xp >= 500) return Colors.orange;
    if (xp >= 200) return AppColors.accent;
    if (xp >= 100) return Colors.blue;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final xp = _profile?['xp_points'] ?? 0;
    final name = _profile?['full_name'] ?? 'Greenie';
    final username = _profile?['username'] ?? 'greenie';
    final streak = _profile?['streak_days'] ?? 0;
    final level = _profile?['level'] ?? 1;
    final ecoTitle = _getEcoTitle(xp);

    // XP progress to next level
    final xpForNextLevel = level * 100;
    final xpProgress = (xp % 100) / 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.3),
                        border: Border.all(
                            color: AppColors.accent, width: 3),
                      ),
                      child: const Icon(Icons.person,
                          color: AppColors.accent, size: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: AppText.heading),
                    const SizedBox(height: 4),
                    Text('@$username', style: AppText.body),
                    const SizedBox(height: 8),

                    // Eco title badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEcoTitleColor(xp).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _getEcoTitleColor(xp).withOpacity(0.5)),
                      ),
                      child: Text(
                        ecoTitle,
                        style: TextStyle(
                          color: _getEcoTitleColor(xp),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Level & XP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Level $level',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: xpProgress,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.2),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppColors.xpColor),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$xp XP',
                          style: const TextStyle(
                            color: AppColors.xpColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _statCard('🔥', '$streak', 'Day Streak',
                        AppColors.accent),
                    _statCard('⭐', '$xp', 'Total XP',
                        AppColors.xpColor),
                    _statCard('🎯', '$_completedChallenges',
                        'Challenges Done', Colors.blue),
                    _statCard('✅', '$_completedHabits',
                        'Habits Done', Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Impact Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Environmental Impact',
                          style: AppText.subheading),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _impactItem('🌿',
                              '${_profile?['co2_saved'] ?? 0} kg',
                              'CO₂ Saved'),
                          _impactItem('⚡',
                              '${_profile?['energy_saved'] ?? 0} kWh',
                              'Energy'),
                          _impactItem('💧',
                              '${_profile?['water_saved'] ?? 0} L',
                              'Water'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Show admin button only if user is admin
              if (_profile?['is_admin'] == true) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                      label: const Text('Admin Panel',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Donations button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DonationsScreen(),
                      ),
                    ),
                    icon: const Text('💚', style: TextStyle(fontSize: 18)),
                    label: const Text('Donations & Impact',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Rewards button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RewardsScreen(),
                      ),
                    ),
                    icon: const Text('🎁', style: TextStyle(fontSize: 18)),
                    label: const Text('Rewards Store',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
      String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label,
              style: AppText.body.copyWith(fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _impactItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: AppText.body),
      ],
    );
  }
}