import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  List<Map<String, dynamic>> _causes = [];
  List<Map<String, dynamic>> _myDonations = [];
  bool _isLoading = true;
  int _userXP = 0;

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
            .select('xp_points')
            .eq('id', user.id)
            .single();

        final causes = await Supabase.instance.client
            .from('donations')
            .select()
            .eq('is_active', true)
            .order('created_at');

        final myDonations = await Supabase.instance.client
            .from('user_donations')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        setState(() {
          _userXP = profile['xp_points'] ?? 0;
          _causes = List<Map<String, dynamic>>.from(causes);
          _myDonations = List<Map<String, dynamic>>.from(myDonations);
        });
      }
    } catch (e) {
      debugPrint('Error loading donations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _myTotalDonations() {
    return _myDonations.fold(0, (sum, d) => sum + (d['amount'] as int));
  }

  Future<void> _donate(Map<String, dynamic> cause) async {
    int selectedAmount = 50;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Text(cause['icon'] ?? '🌍',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cause['title'],
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cause['description'] ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select XP to donate:',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Amount options
              Wrap(
                spacing: 8,
                children: [25, 50, 100, 200].map((amount) {
                  final isSelected = selectedAmount == amount;
                  final canAfford = _userXP >= amount;
                  return GestureDetector(
                    onTap: canAfford
                        ? () => setDialogState(
                            () => selectedAmount = amount)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : canAfford
                                ? AppColors.background
                                : AppColors.background
                                    .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : canAfford
                                  ? AppColors.primary
                                      .withOpacity(0.4)
                                  : AppColors.textSecondary
                                      .withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '$amount XP',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : canAfford
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Your XP: $_userXP',
                style: const TextStyle(
                  color: AppColors.xpColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: _userXP >= selectedAmount
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text(
                'Donate $selectedAmount XP',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Deduct XP from user
        await Supabase.instance.client
            .from(Tables.profiles)
            .update({'xp_points': _userXP - selectedAmount})
            .eq('id', user.id);

        // Add donation record
        await Supabase.instance.client.from('user_donations').insert({
          'user_id': user.id,
          'donation_id': cause['id'],
          'amount': selectedAmount,
        });

        // Update cause current amount
        await Supabase.instance.client.from('donations').update({
          'current_amount':
              (cause['current_amount'] ?? 0) + selectedAmount,
        }).eq('id', cause['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '💚 Donated $selectedAmount XP to ${cause['title']}!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        _loadData();
      }
    } catch (e) {
      debugPrint('Error donating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDonated = _myTotalDonations();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Donations & Impact',
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
            child: Text(
              '⭐ $_userXP XP',
              style: const TextStyle(
                color: AppColors.xpColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My impact summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text('🌍', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          const Text('Your Real-World Impact',
                              style: AppText.subheading),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _impactStat('💚', '$totalDonated XP',
                                  'Total Donated'),
                              _impactStat('🎯',
                                  '${_myDonations.length}', 'Causes Supported'),
                              _impactStat('🌳',
                                  '${(totalDonated / 100).floor()}',
                                  'Trees Equivalent'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Active Causes', style: AppText.subheading),
                    const SizedBox(height: 12),

                    // Causes list
                    ..._causes.map((cause) {
                      final target = cause['target_amount'] ?? 1000;
                      final current = cause['current_amount'] ?? 0;
                      final progress = (current / target).clamp(0.0, 1.0);
                      final percentage = (progress * 100).toInt();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(cause['icon'] ?? '🌍',
                                        style: const TextStyle(
                                            fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cause['title'],
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        cause['description'] ?? '',
                                        style: AppText.body
                                            .copyWith(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _donate(cause),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Donate',
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
                            const SizedBox(height: 12),

                            // Progress bar
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$current / $target XP',
                                  style: AppText.body
                                      .copyWith(fontSize: 11),
                                ),
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.2),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.accent),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _impactStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label,
            style: AppText.body.copyWith(fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}