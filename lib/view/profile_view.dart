import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/view/edit_profile_view.dart';
import 'package:ziesocial/view/login_view.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';
import 'package:ziesocial/widget/post_card.dart';

class ProfileView extends StatefulWidget {
  final int? userId; // If null, views own profile
  final String? username;

  const ProfileView({
    super.key,
    this.userId,
    this.username,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final targetId = widget.userId ?? currentUserId;

    if (targetId > 0) {
      context.read<ProfileViewModel>().fetchProfile(
            targetId,
            viewerId: currentUserId > 0 ? currentUserId : null,
          );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi ZieSocial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LoginViewModel>().logout();
              context.read<ProfileViewModel>().clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openPostDetail(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Postingan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      PostCard(
                        post: post,
                        onPostDeleted: () {
                          Navigator.pop(context);
                          _loadProfile();
                        },
                        onPostUpdated: () {
                          _loadProfile();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;

    final targetUserId = widget.userId ?? currentUserId;
    final isOwnProfile = (targetUserId == currentUserId);

    final profile = profileVm.getProfile(targetUserId);
    final isLoading = profileVm.isUserLoading(targetUserId);
    final errorMessage = profileVm.getErrorMessage(targetUserId);

    final avatarUrl = ApiConstants.getImageUrl(profile?.user.avatar);
    final displayedUsername = profile?.user.username ?? widget.username ?? 'Profil';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayedUsername,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (isOwnProfile)
              const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
        actions: [
          if (isOwnProfile) ...[
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppColors.textPrimary),
              tooltip: 'Keluar',
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu opsi profil')),
                );
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ],
      ),
      body: (isLoading && profile == null)
          ? const Center(child: CircularProgressIndicator())
          : (errorMessage != null && profile == null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const Gap(12),
                      Text(errorMessage),
                      const Gap(12),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : (profile == null)
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                  onRefresh: () async => _loadProfile(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // 1. Profile Header Stats & Avatar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.storyGradient,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? Text(
                                          (profile?.user.name.isNotEmpty == true)
                                              ? profile!.user.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const Gap(24),

                            // Stats: Postingan, Pengikut, Mengikuti
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                    profile?.postsCount.toString() ?? '0',
                                    'Postingan',
                                  ),
                                  _buildStatColumn(
                                    profile?.followersCount.toString() ?? '0',
                                    'Pengikut',
                                    onTap: () => _openFollowList(
                                      targetUserId: targetUserId,
                                      username: displayedUsername,
                                      initialTabIndex: 0,
                                    ),
                                  ),
                                  _buildStatColumn(
                                    profile?.followingCount.toString() ?? '0',
                                    'Mengikuti',
                                    onTap: () => _openFollowList(
                                      targetUserId: targetUserId,
                                      username: displayedUsername,
                                      initialTabIndex: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. User Info: Name & Bio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.user.name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (profile?.user.bio.isNotEmpty == true) ...[
                              const Gap(4),
                              Text(
                                profile!.user.bio,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Gap(16),

                      // 3. Action Buttons (Edit Profile / Follow)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: isOwnProfile
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _buildButton(
                                      text: 'Edit Profil',
                                      backgroundColor: const Color(0xFFEFEFEF),
                                      textColor: AppColors.textPrimary,
                                      onPressed: () async {
                                        final updated = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditProfileView(
                                              user: profile!.user,
                                            ),
                                          ),
                                        );
                                        if (updated == true) {
                                          _loadProfile();
                                        }
                                      },
                                    ),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: _buildButton(
                                      text: 'Bagikan Profil',
                                      backgroundColor: const Color(0xFFEFEFEF),
                                      textColor: AppColors.textPrimary,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Tautan profil disalin.'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _buildButton(
                                      text: profile?.isFollowing == true
                                          ? 'Mengikuti'
                                          : 'Ikuti',
                                      backgroundColor: profile?.isFollowing == true
                                          ? const Color(0xFFEFEFEF)
                                          : AppColors.primary,
                                      textColor: profile?.isFollowing == true
                                          ? AppColors.textPrimary
                                          : Colors.white,
                                      onPressed: () async {
                                        await context
                                            .read<ProfileViewModel>()
                                            .toggleFollow(
                                              targetUserId: targetUserId,
                                              followerId: currentUserId,
                                            );
                                      },
                                    ),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: _buildButton(
                                      text: 'Pesan',
                                      backgroundColor: const Color(0xFFEFEFEF),
                                      textColor: AppColors.textPrimary,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Membuka pesan langsung...'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const Gap(16),

                      // 4. Story Highlights Mock
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildHighlightItem('Liburan', Icons.beach_access),
                            _buildHighlightItem('Kuliner', Icons.restaurant),
                            _buildHighlightItem('Kegiatan', Icons.fitness_center),
                            _buildHighlightItem('Musik', Icons.music_note),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // 5. Tabs (Grid Posts, Tagged)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.textPrimary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.grid_on,
                                size: 22,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: const Icon(
                                Icons.person_pin_outlined,
                                size: 22,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 6. 3x3 Photo Grid of Posts
                      if (profile?.posts.isEmpty ?? true)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                Gap(12),
                                Text(
                                  'Belum Ada Postingan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1.5,
                            mainAxisSpacing: 1.5,
                          ),
                          itemCount: profile!.posts.length,
                          itemBuilder: (context, index) {
                            final post = profile.posts[index];
                            final imageUrl = ApiConstants.getImageUrl(post.image);

                            return GestureDetector(
                              onTap: () => _openPostDetail(post),
                              child: Container(
                                color: AppColors.surface,
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _openFollowList({
    required int targetUserId,
    required String username,
    required int initialTabIndex,
  }) async {
    if (targetUserId <= 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListScreen(
          userId: targetUserId,
          username: username,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );

    if (mounted) {
      _loadProfile();
    }
  }

  Widget _buildStatColumn(
    String count,
    String label, {
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
    );
  }

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.surface,
              child: Icon(icon, color: AppColors.textPrimary, size: 24),
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class FollowListScreen extends StatefulWidget {
  final int userId;
  final String username;
  final int initialTabIndex;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBothLists();
    });
  }

  Future<void> _loadBothLists() async {
    setState(() => _isLoading = true);

    final currentUser = context.read<LoginViewModel>().user;
    final viewerId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final profileVm = context.read<ProfileViewModel>();

    final results = await Future.wait([
      profileVm.fetchFollowList(
        userId: widget.userId,
        type: 'followers',
        viewerId: viewerId,
      ),
      profileVm.fetchFollowList(
        userId: widget.userId,
        type: 'following',
        viewerId: viewerId,
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _followers = results[0];
      _following = results[1];
      _isLoading = false;
    });
  }

  Future<void> _handleToggleFollow(int targetId, bool isCurrentlyFollowing) async {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId <= 0 || targetId <= 0) return;

    // Optimistic UI update in both lists
    setState(() {
      for (final item in _followers) {
        if (int.tryParse(item['id'].toString()) == targetId) {
          item['is_following'] = !isCurrentlyFollowing;
        }
      }
      for (final item in _following) {
        if (int.tryParse(item['id'].toString()) == targetId) {
          item['is_following'] = !isCurrentlyFollowing;
        }
      }
    });

    await context.read<ProfileViewModel>().toggleFollow(
          targetUserId: targetId,
          followerId: currentUserId,
        );

    if (mounted) {
      _loadBothLists();
    }
  }

  void _openUserProfile(int userId, String username) async {
    if (userId <= 0) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          userId: userId,
          username: username,
        ),
      ),
    );
    if (mounted) {
      _loadBothLists();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.username,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: TabBar(
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.textPrimary,
            indicatorWeight: 1.8,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: '${_followers.length} Pengikut'),
              Tab(text: '${_following.length} Mengikuti'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUserList(
                    users: _followers,
                    emptyText: 'Belum ada pengikut.',
                    currentUserId: currentUserId,
                  ),
                  _buildUserList(
                    users: _following,
                    emptyText: 'Belum mengikuti siapa pun.',
                    currentUserId: currentUserId,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUserList({
    required List<Map<String, dynamic>> users,
    required String emptyText,
    required int currentUserId,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 52,
              color: AppColors.textSecondary,
            ),
            const Gap(12),
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBothLists,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 76,
          color: AppColors.borderLight,
        ),
        itemBuilder: (context, index) {
          final item = users[index];
          final itemUserId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
          final username = item['username']?.toString() ?? '';
          final name = item['name']?.toString() ?? '';
          final avatarUrl = ApiConstants.getImageUrl(item['avatar']?.toString());
          final isFollowing = item['is_following'] == true;
          final isMe = itemUserId == currentUserId;

          return ListTile(
            onTap: () => _openUserProfile(itemUserId, username),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surface,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : null,
            ),
            title: Text(
              username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: name.isNotEmpty
                ? Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
            trailing: isMe
                ? null
                : SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleToggleFollow(itemUserId, isFollowing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? const Color(0xFFEFEFEF)
                            : AppColors.primary,
                        foregroundColor: isFollowing
                            ? AppColors.textPrimary
                            : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Mengikuti' : 'Ikuti',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isFollowing
                              ? AppColors.textPrimary
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
