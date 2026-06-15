import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  final _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

Future<void> _loadPosts() async {
  setState(() => _isLoading = true);
  try {
    // Load posts without join
    final posts = await Supabase.instance.client
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    final postsList = List<Map<String, dynamic>>.from(posts);

    // For each post, load the profile separately
    for (var post in postsList) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, username, xp_points')
            .eq('id', post['user_id'])
            .single();
        post['profiles'] = profile;
      } catch (e) {
        post['profiles'] = {
          'full_name': 'EcoUser',
          'username': 'ecouser',
          'xp_points': 0
        };
      }
    }

    setState(() => _posts = postsList);
  } catch (e) {
    debugPrint('Error loading posts: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('posts').insert({
          'user_id': user.id,
          'content': _postController.text.trim(),
        });
        _postController.clear();
        _loadPosts();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
    }
  }

  Future<void> _likePost(String postId, int currentLikes) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Check if already liked
        final existing = await Supabase.instance.client
            .from('post_likes')
            .select()
            .eq('user_id', user.id)
            .eq('post_id', postId);

        if ((existing as List).isEmpty) {
          // Like
          await Supabase.instance.client
              .from('post_likes')
              .insert({'user_id': user.id, 'post_id': postId});
          await Supabase.instance.client
              .from('posts')
              .update({'likes': currentLikes + 1}).eq('id', postId);
        } else {
          // Unlike
          await Supabase.instance.client
              .from('post_likes')
              .delete()
              .eq('user_id', user.id)
              .eq('post_id', postId);
          await Supabase.instance.client
              .from('posts')
              .update({'likes': currentLikes - 1}).eq('id', postId);
        }
        _loadPosts();
      }
    } catch (e) {
      debugPrint('Error liking post: $e');
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .delete()
          .eq('id', postId);
      _loadPosts();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share with Community', style: AppText.subheading),
            const SizedBox(height: 4),
            const Text('Inspire others with your eco actions!',
                style: AppText.body),
            const SizedBox(height: 16),
            TextField(
              controller: _postController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText:
                    'What eco-friendly action did you take today? 🌿',
                hintStyle:
                    const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _createPost,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Post',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(String createdAt) {
    final date = DateTime.parse(createdAt);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _getEcoEmoji(int xp) {
    if (xp >= 1000) return '🌍';
    if (xp >= 500) return '🏆';
    if (xp >= 200) return '⚔️';
    if (xp >= 100) return '🌱';
    return '🌿';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.eco, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Community',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌍',
                          style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text('No posts yet',
                          style: AppText.subheading),
                      const SizedBox(height: 8),
                      const Text(
                          'Be the first to share your eco action!',
                          style: AppText.body),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showCreatePostSheet,
                        icon: const Icon(Icons.add,
                            color: Colors.white),
                        label: const Text('Create Post',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final profile = post['profiles'];
                      final isOwner = post['user_id'] == currentUserId;
                      final xp = profile?['xp_points'] ?? 0;

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
                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary
                                        .withOpacity(0.3),
                                    border: Border.all(
                                        color: AppColors.accent
                                            .withOpacity(0.5)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getEcoEmoji(xp),
                                      style: const TextStyle(
                                          fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile?['full_name'] ??
                                            'EcoUser',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(post['created_at']),
                                        style: AppText.body.copyWith(
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  GestureDetector(
                                    onTap: () =>
                                        _deletePost(post['id']),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Content
                            Text(
                              post['content'],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Footer
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _likePost(
                                      post['id'], post['likes'] ?? 0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite_border,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${post['likes'] ?? 0}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  '#EcoTrack',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}