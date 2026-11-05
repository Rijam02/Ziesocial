import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/model/profile_model.dart';
import 'package:ziesocial/model/user_model.dart';
import 'package:ziesocial/view/account_settings_view.dart';
import 'package:ziesocial/view/create_post_view.dart';
import 'package:ziesocial/view/edit_profile_view.dart';
import 'package:ziesocial/view/login_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
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

  void _openAccountSettings(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountSettingsView(
          user: user,
          onProfileUpdated: _loadProfile,
        ),
      ),
    );
  }

  void _showOwnProfileMenu(UserModel? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 10),
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (user != null) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    title: const Text(
                      'Pengaturan Akun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _openAccountSettings(user);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                ],
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppColors.primaryText,
                  ),
                  title: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _handleLogout();
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    size: 20,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Hapus Akun',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _handleDeleteAccount();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi ZieSocial?',
          style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepForest,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    bool isConfirmed = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Hapus Akun Permanen?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Semua data dari akun ini (postingan, cerita, sorotan, pengikut, mengikuti, suka, dan komentar) akan dihapus secara permanen dari aplikasi dan database ZieSocial.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.secondaryText,
                      height: 1.45,
                    ),
                  ),
                  const Gap(12),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        isConfirmed = !isConfirmed;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isConfirmed,
                          activeColor: AppColors.error,
                          onChanged: (val) {
                            setDialogState(() {
                              isConfirmed = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Ya, saya yakin ingin menghapus akun secara permanen.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                ElevatedButton(
                  onPressed: !isConfirmed
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final currentUser =
                              context.read<LoginViewModel>().user;
                          final currentUserId =
                              int.tryParse(currentUser?.id ?? '0') ?? 0;
                          if (currentUserId <= 0) return;

                          final profileVm = context.read<ProfileViewModel>();
                          final loginVm = context.read<LoginViewModel>();
                          final homeVm = context.read<HomeViewModel>();
                          final messenger =
                              ScaffoldMessenger.of(this.context);
                          final navigator = Navigator.of(this.context);

                          final deleted =
                              await profileVm.deleteAccount(currentUserId);
                          if (!mounted) return;

                          if (deleted) {
                            loginVm.logout();
                            homeVm.fetchPosts();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Akun berhasil dihapus.'),
                              ),
                            );
                            navigator.pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginView(),
                              ),
                              (route) => false,
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  profileVm.getErrorMessage(currentUserId) ??
                                      'Gagal menghapus akun.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.pureWhite,
                  ),
                  child: const Text('Hapus Akun'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPostDetail(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detail Postingan',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.secondaryText,
                        ),
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
    final hasUnseenStory =
        context.watch<HomeViewModel>().hasUnseenStoryForUser(targetUserId);

    final avatarUrl = ApiConstants.getImageUrl(profile?.user.avatar);
    final displayedUsername =
        profile?.user.username ?? widget.username ?? 'Profil';
    final displayedName = (profile?.user.name.isNotEmpty ?? false)
        ? profile!.user.name
        : displayedUsername;

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.pureWhite,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const Gap(4),
                  ],
                  Expanded(
                    child: Text(
                      '@$displayedUsername',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.5,
                        color: AppColors.primaryText,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwnProfile)
                    IconButton(
                      onPressed: () =>
                          _showOwnProfileMenu(profile?.user ?? currentUser),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: AppColors.primaryText,
                        size: 23,
                      ),
                      tooltip: 'Menu & Pengaturan Akun',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: (isLoading && profile == null)
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.sageGreen,
                strokeWidth: 2,
              ),
            )
          : (errorMessage != null && profile == null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: AppColors.error,
                        ),
                        const Gap(12),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const Gap(14),
                        OutlinedButton(
                          onPressed: _loadProfile,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : (profile == null)
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.sageGreen,
                        strokeWidth: 2,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.deepForest,
                      backgroundColor: AppColors.pureWhite,
                      onRefresh: () async => _loadProfile(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // 1. Editorial Profile Identity Section
                          Container(
                            color: AppColors.warmIvory,
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 640),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Avatar with conditional unseen story border
                                        Container(
                                          padding: EdgeInsets.all(
                                            hasUnseenStory ? 2.5 : 0,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: hasUnseenStory
                                                ? AppColors.storyGradient
                                                : null,
                                            border: hasUnseenStory
                                                ? null
                                                : Border.all(
                                                    color: AppColors.border,
                                                    width: 1.5,
                                                  ),
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(
                                              hasUnseenStory ? 2 : 0,
                                            ),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.warmIvory,
                                            ),
                                            child: CircleAvatar(
                                              radius: 38,
                                              backgroundColor:
                                                  AppColors.pureWhite,
                                              backgroundImage:
                                                  avatarUrl.isNotEmpty
                                                      ? NetworkImage(avatarUrl)
                                                      : null,
                                              child: avatarUrl.isEmpty
                                                  ? Text(
                                                      displayedName.isNotEmpty
                                                          ? displayedName[0]
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        fontSize: 28,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .deepForest,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const Gap(18),

                                        // Full Name & Handle
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayedName,
                                                style: const TextStyle(
                                                  fontFamily: 'Georgia',
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryText,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              const Gap(3),
                                              Text(
                                                '@$displayedUsername',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.secondaryText,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (profile
                                                  .user.bio.isNotEmpty) ...[
                                                const Gap(8),
                                                Text(
                                                  profile.user.bio,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    color:
                                                        AppColors.primaryText,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(18),

                                    // Editorial Stats Card
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.pureWhite,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatItem(
                                              profile.postsCount.toString(),
                                              'Postingan',
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 28,
                                            color: AppColors.border,
                                          ),
                                          Expanded(
                                            child: _buildStatItem(
                                              profile.followersCount.toString(),
                                              'Pengikut',
                                              onTap: () => _openFollowList(
                                                targetUserId: targetUserId,
                                                username: displayedUsername,
                                                initialTabIndex: 0,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 28,
                                            color: AppColors.border,
                                          ),
                                          Expanded(
                                            child: _buildStatItem(
                                              profile.followingCount.toString(),
                                              'Mengikuti',
                                              onTap: () => _openFollowList(
                                                targetUserId: targetUserId,
                                                username: displayedUsername,
                                                initialTabIndex: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Gap(14),

                                    // Profile Action Buttons
                                    if (isOwnProfile)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 38,
                                              child: ElevatedButton.icon(
                                                onPressed: () async {
                                                  final updated =
                                                      await Navigator.push<
                                                          bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditProfileView(
                                                        user: profile.user,
                                                      ),
                                                    ),
                                                  );
                                                  if (updated == true) {
                                                    _loadProfile();
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                ),
                                                label:
                                                    const Text('Edit Profil'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.deepForest,
                                                  foregroundColor:
                                                      AppColors.pureWhite,
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Gap(10),
                                          Expanded(
                                            child: SizedBox(
                                              height: 38,
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _openAccountSettings(
                                                  profile.user,
                                                ),
                                                icon: const Icon(
                                                  Icons.tune_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text('Pengaturan'),
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.pureWhite,
                                                  foregroundColor:
                                                      AppColors.primaryText,
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 38,
                                              child: profile.isFollowing
                                                  ? OutlinedButton.icon(
                                                      onPressed: () async {
                                                        await context
                                                            .read<
                                                                ProfileViewModel>()
                                                            .toggleFollow(
                                                              targetUserId:
                                                                  targetUserId,
                                                              followerId:
                                                                  currentUserId,
                                                            );
                                                      },
                                                      icon: const Icon(
                                                        Icons.check_rounded,
                                                        size: 16,
                                                      ),
                                                      label: const Text(
                                                        'Mengikuti',
                                                      ),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors.pureWhite,
                                                        foregroundColor:
                                                            AppColors
                                                                .primaryText,
                                                      ),
                                                    )
                                                  : ElevatedButton.icon(
                                                      onPressed: () async {
                                                        await context
                                                            .read<
                                                                ProfileViewModel>()
                                                            .toggleFollow(
                                                              targetUserId:
                                                                  targetUserId,
                                                              followerId:
                                                                  currentUserId,
                                                            );
                                                      },
                                                      icon: const Icon(
                                                        Icons
                                                            .person_add_alt_1_rounded,
                                                        size: 16,
                                                      ),
                                                      label:
                                                          const Text('Ikuti'),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors
                                                                .deepForest,
                                                        foregroundColor:
                                                            AppColors.pureWhite,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),

                          // 2. Sorotan (Highlights) - Hanya muncul apabila user telah membuat sorotan
                          if (profile.highlights.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SOROTAN PILIHAN',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  if (isOwnProfile)
                                    GestureDetector(
                                      onTap: () async {
                                        final created =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CreatePostView(
                                              initialHighlightMode: true,
                                            ),
                                          ),
                                        );
                                        if (created == true && mounted) {
                                          _loadProfile();
                                        }
                                      },
                                      child: const Text(
                                        '+ Tambah Sorotan',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.deepForest,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 92,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: profile.highlights.length,
                                itemBuilder: (context, index) {
                                  final hl = profile.highlights[index];
                                  return _buildHighlightItem(
                                    highlight: hl,
                                    isOwnProfile: isOwnProfile,
                                    currentUserId: currentUserId,
                                  );
                                },
                              ),
                            ),
                            const Gap(8),
                            const Divider(height: 1),
                          ],

                          // 3. Editorial Posts Section Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      size: 16,
                                      color: AppColors.deepForest,
                                    ),
                                    Gap(8),
                                    Text(
                                      'ARSIP PUBLIKASI',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.4,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${profile.posts.length} Foto',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 4. Posts Grid
                          if (profile.posts.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 56,
                                horizontal: 24,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.warmIvory,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 22,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const Gap(12),
                                    const Text(
                                      'Belum Ada Postingan',
                                      style: TextStyle(
                                        fontFamily: 'Georgia',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      isOwnProfile
                                          ? 'Mulai bagikan foto pertama Anda ke jurnal profil.'
                                          : 'Kreator ini belum menerbitkan foto.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.92,
                              ),
                              itemCount: profile.posts.length,
                              itemBuilder: (context, index) {
                                final post = profile.posts[index];
                                final imageUrl =
                                    ApiConstants.getImageUrl(post.image);

                                return GestureDetector(
                                  onTap: () => _openPostDetail(post),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.warmIvory,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) =>
                                                const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: AppColors.secondaryText,
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

  Widget _buildStatItem(
    String count,
    String label, {
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: content,
    );
  }

  void _openHighlightViewer({
    required HighlightModel highlight,
    required bool isOwnProfile,
    required int currentUserId,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => _HighlightViewerDialog(
        highlight: highlight,
        isOwnProfile: isOwnProfile,
        currentUserId: currentUserId,
        onChanged: _loadProfile,
      ),
    );
  }

  Widget _buildHighlightItem({
    required HighlightModel highlight,
    required bool isOwnProfile,
    required int currentUserId,
  }) {
    final coverUrl = ApiConstants.getImageUrl(highlight.coverImage);

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: () => _openHighlightViewer(
          highlight: highlight,
          isOwnProfile: isOwnProfile,
          currentUserId: currentUserId,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.softBeige,
                  width: 1.8,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.warmIvory,
                backgroundImage:
                    coverUrl.isNotEmpty ? NetworkImage(coverUrl) : null,
                child: coverUrl.isEmpty
                    ? const Icon(
                        Icons.bookmarks_outlined,
                        color: AppColors.deepForest,
                        size: 20,
                      )
                    : null,
              ),
            ),
            const Gap(5),
            SizedBox(
              width: 68,
              child: Text(
                highlight.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightViewerDialog extends StatefulWidget {
  final HighlightModel highlight;
  final bool isOwnProfile;
  final int currentUserId;
  final VoidCallback onChanged;

  const _HighlightViewerDialog({
    required this.highlight,
    required this.isOwnProfile,
    required this.currentUserId,
    required this.onChanged,
  });

  @override
  State<_HighlightViewerDialog> createState() => _HighlightViewerDialogState();
}

class _HighlightViewerDialogState extends State<_HighlightViewerDialog> {
  late String _title;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _title = widget.highlight.title;
  }

  void _showEditHighlightDialog() {
    final controller = TextEditingController(text: _title);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Edit Judul Sorotan',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Sorotan',
            hintText: 'Masukkan nama sorotan...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;
              Navigator.pop(dialogCtx);

              final success = await context
                  .read<ProfileViewModel>()
                  .updateHighlight(
                    highlightId: widget.highlight.id,
                    userId: widget.currentUserId,
                    title: newTitle,
                  );

              if (!mounted) return;
              if (success) {
                setState(() {
                  _title = newTitle;
                });
                widget.onChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama sorotan berhasil diperbarui.'),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHighlight() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Hapus Sorotan?',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus sorotan "$_title" dari profil Anda?',
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.secondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final profileVm = context.read<ProfileViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              final deleted = await profileVm.deleteHighlight(
                highlightId: widget.highlight.id,
                userId: widget.currentUserId,
              );

              if (!mounted) return;
              if (deleted) {
                widget.onChanged();
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Sorotan berhasil dihapus.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.highlight.items;
    final hasItems = items.isNotEmpty;
    final currentImage = hasItems
        ? ApiConstants.getImageUrl(items[_currentIndex].image)
        : ApiConstants.getImageUrl(widget.highlight.coverImage);
    final currentCaption = hasItems ? items[_currentIndex].caption : '';
    final coverUrl = ApiConstants.getImageUrl(widget.highlight.coverImage);

    return Scaffold(
      backgroundColor: const Color(0xFF161916),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  if (!hasItems) return;
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < screenWidth * 0.35) {
                    if (_currentIndex > 0) {
                      setState(() => _currentIndex--);
                    }
                  } else {
                    if (_currentIndex < items.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Center(
                  child: currentImage.isNotEmpty
                      ? Image.network(
                          currentImage,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 56,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: Colors.white54,
                          size: 56,
                        ),
                ),
              ),
            ),

            // Header Sorotan + Tombol Edit & Hapus (Khusus Akun Pribadi)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  if (items.length > 1) ...[
                    Row(
                      children: List.generate(items.length, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: i <= _currentIndex
                                  ? AppColors.softBeige
                                  : Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const Gap(14),
                  ],
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.warmIvory,
                        backgroundImage:
                            coverUrl.isNotEmpty ? NetworkImage(coverUrl) : null,
                        child: coverUrl.isEmpty
                            ? const Icon(
                                Icons.bookmarks_outlined,
                                size: 17,
                                color: AppColors.deepForest,
                              )
                            : null,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isOwnProfile) ...[
                        IconButton(
                          onPressed: _showEditHighlightDialog,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 21,
                          ),
                          tooltip: 'Edit Nama Sorotan',
                        ),
                        IconButton(
                          onPressed: _confirmDeleteHighlight,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFF29B9B),
                            size: 21,
                          ),
                          tooltip: 'Hapus Sorotan',
                        ),
                      ],
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (currentCaption.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 18,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    currentCaption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
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

  Future<void> _handleToggleFollow(
    int targetId,
    bool isCurrentlyFollowing,
  ) async {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId <= 0 || targetId <= 0) return;

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

  Future<void> _openUserProfile(int userId, String username) async {
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
        backgroundColor: AppColors.pureWhite,
        appBar: AppBar(
          title: Text(
            '@${widget.username}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: AppColors.primaryText,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.deepForest,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.sageGreen,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
            tabs: [
              Tab(text: '${_followers.length} Pengikut'),
              Tab(text: '${_following.length} Mengikuti'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.sageGreen,
                  strokeWidth: 2,
                ),
              )
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
              Icons.people_outline_rounded,
              size: 44,
              color: AppColors.secondaryText,
            ),
            const Gap(10),
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.deepForest,
      backgroundColor: AppColors.pureWhite,
      onRefresh: _loadBothLists,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 72,
          color: AppColors.border,
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
              horizontal: 18,
              vertical: 4,
            ),
            leading: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.warmIvory,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.deepForest,
                      ),
                    )
                  : null,
            ),
            title: Text(
              name.isNotEmpty ? name : username,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.primaryText,
              ),
            ),
            subtitle: Text(
              '@$username',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondaryText,
              ),
            ),
            trailing: isMe
                ? null
                : SizedBox(
                    height: 32,
                    child: isFollowing
                        ? OutlinedButton(
                            onPressed: () =>
                                _handleToggleFollow(itemUserId, isFollowing),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text(
                              'Mengikuti',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () =>
                                _handleToggleFollow(itemUserId, isFollowing),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepForest,
                              foregroundColor: AppColors.pureWhite,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: const Text(
                              'Ikuti',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
