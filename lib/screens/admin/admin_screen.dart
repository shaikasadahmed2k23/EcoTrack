import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _challenges = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final users = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final challenges = await Supabase.instance.client
          .from('challenges')
          .select()
          .order('created_at', ascending: false);

      final posts = await Supabase.instance.client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final userChallenges = await Supabase.instance.client
          .from('user_challenges')
          .select();

      final habits = await Supabase.instance.client
          .from('habits')
          .select();

      setState(() {
        _users = List<Map<String, dynamic>>.from(users);
        _challenges = List<Map<String, dynamic>>.from(challenges);
        _posts = List<Map<String, dynamic>>.from(posts);
        _stats = {
          'total_users': _users.length,
          'total_challenges': _challenges.length,
          'total_posts': _posts.length,
          'completed_challenges': (userChallenges as List)
              .where((uc) => uc['is_completed'] == true)
              .length,
          'total_habits': (habits as List).length,
          'total_xp': _users.fold<int>(
              0, (sum, u) => sum + ((u['xp_points'] ?? 0) as int)),
        };
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotificationToAll(String title, String message, String type) async {
    try {
      for (final user in _users) {
        await Supabase.instance.client.from('notifications').insert({
          'user_id': user['id'],
          'title': title,
          'message': message,
          'type': type,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Notification sent to ${_users.length} users!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<void> _toggleChallenge(String id, bool currentStatus) async {
    try {
      await Supabase.instance.client
          .from('challenges')
          .update({'is_active': !currentStatus})
          .eq('id', id);
      _loadData();
    } catch (e) {
      debugPrint('Error toggling challenge: $e');
    }
  }

  Future<void> _deletePost(String id) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .delete()
          .eq('id', id);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  Future<void> _addXPToUser(String userId, int amount) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('xp_points')
          .eq('id', userId)
          .single();

      await Supabase.instance.client
          .from('profiles')
          .update({'xp_points': (profile['xp_points'] ?? 0) + amount})
          .eq('id', userId);

      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': 'Bonus XP Received! ⭐',
        'message': 'Admin awarded you $amount bonus XP. Keep it up!',
        'type': 'xp',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added $amount XP successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      _loadData();
    } catch (e) {
      debugPrint('Error adding XP: $e');
    }
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Send Notification to All',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Message',
                  labelStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['general', 'challenge', 'streak', 'reward', 'community']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendNotificationToAll(
                  titleController.text.trim(),
                  messageController.text.trim(),
                  selectedType,
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Send',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddXPDialog(Map<String, dynamic> user) {
    int selectedXP = 50;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add XP to ${user['full_name']}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current XP: ${user['xp_points'] ?? 0}',
                style: const TextStyle(color: AppColors.xpColor),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [25, 50, 100, 200, 500].map((amount) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedXP = amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedXP == amount
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedXP == amount
                              ? AppColors.accent
                              : AppColors.primary.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        '+$amount',
                        style: TextStyle(
                          color: selectedXP == amount
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addXPToUser(user['id'], selectedXP);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text('Add $selectedXP XP',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
            Icon(Icons.admin_panel_settings, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Admin Panel',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Users'),
            Tab(text: 'Challenges'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildChallengesTab(),
                _buildCommunityTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: AppText.subheading),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard('👥', '${_stats?['total_users'] ?? 0}',
                  'Total Users', Colors.blue),
              _statCard('🎯', '${_stats?['total_challenges'] ?? 0}',
                  'Challenges', AppColors.accent),
              _statCard('✅', '${_stats?['completed_challenges'] ?? 0}',
                  'Completed', Colors.green),
              _statCard('💬', '${_stats?['total_posts'] ?? 0}',
                  'Posts', Colors.purple),
              _statCard('⭐', '${_stats?['total_xp'] ?? 0}',
                  'Total XP', AppColors.xpColor),
              _statCard('✔️', '${_stats?['total_habits'] ?? 0}',
                  'Habits', Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Quick Actions', style: AppText.subheading),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showSendNotificationDialog,
              icon: const Icon(Icons.notifications, color: Colors.white),
              label: const Text('Send Notification to All Users',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('App Health', style: AppText.subheading),
                const SizedBox(height: 12),
                _healthItem('Database', 'Connected', Colors.green),
                _healthItem('Auth', 'Active', Colors.green),
                _healthItem(
                    'Users',
                    '${_stats?['total_users'] ?? 0} registered',
                    AppColors.accent),
                _healthItem(
                    'Content',
                    '${_stats?['total_challenges'] ?? 0} challenges active',
                    Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final xp = user['xp_points'] ?? 0;
        final isAdmin = user['is_admin'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAdmin
                  ? AppColors.accent.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                  border: Border.all(
                    color: isAdmin
                        ? AppColors.accent
                        : AppColors.primary.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    (user['full_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['full_name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${user['username'] ?? 'unknown'} • $xp XP • Streak: ${user['streak_days'] ?? 0}',
                      style: AppText.body.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showAddXPDialog(user),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: const Text(
                    '+XP',
                    style: TextStyle(
                      color: AppColors.xpColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChallengesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _challenges.length,
      itemBuilder: (context, index) {
        final challenge = _challenges[index];
        final isActive = challenge['is_active'] ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.surface
                : AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.textSecondary.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Text(challenge['icon'] ?? '🎯',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['title'],
                      style: TextStyle(
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '+${challenge['xp_reward']} XP • ${challenge['difficulty']}',
                      style: AppText.body.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (val) =>
                    _toggleChallenge(challenge['id'], isActive),
                activeColor: AppColors.accent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Post',
                    style: AppText.body.copyWith(fontSize: 11),
                  ),
                  Row(
                    children: [
                      Text(
                        '❤️ ${post['likes'] ?? 0}',
                        style: AppText.body.copyWith(fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _deletePost(post['id']),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post['content'],
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
      String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: AppText.body.copyWith(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _healthItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}