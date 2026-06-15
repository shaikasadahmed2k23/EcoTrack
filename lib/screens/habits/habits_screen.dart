import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Map<String, dynamic>> _habits = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _habitSuggestions = [
    {'name': 'Use public transport', 'icon': '🚌', 'xp': 30, 'category': 'transport'},
    {'name': 'Save energy at home', 'icon': '⚡', 'xp': 20, 'category': 'energy'},
    {'name': 'Avoid single-use plastic', 'icon': '♻️', 'xp': 25, 'category': 'waste'},
    {'name': 'Recycle waste', 'icon': '🗑️', 'xp': 20, 'category': 'waste'},
    {'name': 'Carry reusable bottle', 'icon': '💧', 'xp': 15, 'category': 'water'},
    {'name': 'Plant a tree', 'icon': '🌱', 'xp': 50, 'category': 'nature'},
    {'name': 'Walk instead of drive', 'icon': '🚶', 'xp': 25, 'category': 'transport'},
    {'name': 'Eat plant-based meal', 'icon': '🥗', 'xp': 20, 'category': 'food'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from(Tables.habits)
            .select()
            .eq('user_id', user.id)
            .order('created_at');
        setState(() => _habits = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHabit(Map<String, dynamic> habit) async {
    final isCompleted = !(habit['is_completed'] ?? false);
    try {
      await Supabase.instance.client
          .from(Tables.habits)
          .update({
            'is_completed': isCompleted,
            'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', habit['id']);
      _loadHabits();
    } catch (e) {
      debugPrint('Error toggling habit: $e');
    }
  }

  Future<void> _addHabit(Map<String, dynamic> suggestion) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from(Tables.habits).insert({
          'user_id': user.id,
          'name': suggestion['name'],
          'icon': suggestion['icon'],
          'category': suggestion['category'],
          'xp_reward': suggestion['xp'],
          'frequency': 'daily',
        });
        _loadHabits();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error adding habit: $e');
    }
  }

  Future<void> _deleteHabit(String habitId) async {
    try {
      await Supabase.instance.client
          .from(Tables.habits)
          .delete()
          .eq('id', habitId);
      _loadHabits();
    } catch (e) {
      debugPrint('Error deleting habit: $e');
    }
  }

  void _showAddHabitSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a Habit', style: AppText.subheading),
            const SizedBox(height: 4),
            const Text('Choose from eco-friendly habits', style: AppText.body),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _habitSuggestions.length,
                itemBuilder: (context, index) {
                  final s = _habitSuggestions[index];
                  return GestureDetector(
                    onTap: () => _addHabit(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Text(s['icon'],
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s['name'],
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '+${s['xp']} XP',
                                  style: const TextStyle(
                                    color: AppColors.xpColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        _habits.where((h) => h['is_completed'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Habits', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: _showAddHabitSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _habits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌱',
                          style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text('No habits yet', style: AppText.subheading),
                      const SizedBox(height: 8),
                      const Text('Add your first eco habit!',
                          style: AppText.body),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddHabitSheet,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Habit',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Progress bar
                    Container(
                      margin: const EdgeInsets.all(16),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Today's Progress",
                                  style: AppText.body),
                              Text(
                                '$completedCount/${_habits.length} done',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _habits.isEmpty
                                  ? 0
                                  : completedCount / _habits.length,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.accent),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Habits list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _habits.length,
                        itemBuilder: (context, index) {
                          final habit = _habits[index];
                          final isCompleted =
                              habit['is_completed'] ?? false;
                          return Dismissible(
                            key: Key(habit['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete,
                                  color: Colors.red),
                            ),
                            onDismissed: (_) => _deleteHabit(habit['id']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppColors.primary.withOpacity(0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCompleted
                                      ? AppColors.accent.withOpacity(0.5)
                                      : AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(habit['icon'] ?? '🌿',
                                      style:
                                          const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          habit['name'],
                                          style: TextStyle(
                                            color: isCompleted
                                                ? AppColors.accent
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '+${habit['xp_reward']} XP',
                                              style: const TextStyle(
                                                  color: AppColors.xpColor,
                                                  fontSize: 12),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '🔥 ${habit['streak']} streak',
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleHabit(habit),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCompleted
                                            ? AppColors.accent
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isCompleted
                                              ? AppColors.accent
                                              : AppColors.textSecondary,
                                          width: 2,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 16)
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _habits.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddHabitSheet,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}