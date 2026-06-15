import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('notifications')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      _loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', user.id);
        _loadNotifications();
      }
    } catch (e) {
      debugPrint('Error marking all notifications: $e');
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', id);
      _loadNotifications();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  String _timeAgo(String createdAt) {
    final date = DateTime.parse(createdAt);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'welcome': return Icons.waving_hand;
      case 'challenge': return Icons.flag;
      case 'habit': return Icons.calendar_today;
      case 'xp': return Icons.star;
      case 'streak': return Icons.local_fire_department;
      case 'reward': return Icons.card_giftcard;
      case 'community': return Icons.people;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'welcome': return AppColors.accent;
      case 'challenge': return Colors.blue;
      case 'habit': return Colors.green;
      case 'xp': return AppColors.xpColor;
      case 'streak': return Colors.orange;
      case 'reward': return Colors.purple;
      case 'community': return Colors.teal;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.accent),
            const SizedBox(width: 8),
            const Text('Notifications',
                style: TextStyle(color: AppColors.textPrimary)),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.accent, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none,
                          color: AppColors.textSecondary, size: 64),
                      const SizedBox(height: 16),
                      const Text('No notifications yet',
                          style: AppText.subheading),
                      const SizedBox(height: 8),
                      const Text('We\'ll notify you of important updates!',
                          style: AppText.body),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] ?? false;
                      final type = notification['type'] ?? 'general';

                      return Dismissible(
                        key: Key(notification['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        onDismissed: (_) =>
                            _deleteNotification(notification['id']),
                        child: GestureDetector(
                          onTap: () => _markAsRead(notification['id']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? AppColors.surface
                                  : AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRead
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.accent.withOpacity(0.4),
                                width: isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(type)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: _getNotificationColor(type),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title'],
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['message'],
                                        style: AppText.body
                                            .copyWith(fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _timeAgo(notification['created_at']),
                                        style: AppText.body
                                            .copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}