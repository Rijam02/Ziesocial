import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/notification_model.dart';
import 'package:ziesocial/view/profile_view.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class ActivityView extends StatefulWidget {
  const ActivityView({super.key});

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications(silent: false);
    });

    // Polling real-time setiap 4 detik selama halaman Aktivitas dibuka
    _realtimeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _loadNotifications(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId > 0) {
      await context
          .read<ProfileViewModel>()
          .fetchNotifications(currentUserId, silent: silent);
    }
  }

  void _openUserProfile(int userId, String username) {
    if (userId <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          userId: userId,
          username: username,
        ),
      ),
    );
  }

  Future<void> _handleFollowBack(int targetUserId) async {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId <= 0 || targetUserId <= 0) return;

    await context.read<ProfileViewModel>().toggleFollow(
          targetUserId: targetUserId,
          followerId: currentUserId,
        );
  }

  String _buildActionText(NotificationModel item) {
    switch (item.type) {
      case 'follow':
        return 'mulai mengikuti Anda.';
      case 'comment':
        final comment = item.commentText ?? '';
        return 'mengomentari postingan Anda: "$comment"';
      case 'like':
      default:
        return 'menyukai postingan Anda.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final notifications = profileVm.notifications;
    final isLoading = profileVm.isLoadingNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Aktivitas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadNotifications(silent: false),
              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.favorite_border,
                                  size: 56,
                                  color: AppColors.textSecondary,
                                ),
                                Gap(12),
                                Text(
                                  'Belum Ada Aktivitas',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Gap(6),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Notifikasi saat seseorang mengikuti Anda, menyukai, atau mengomentari postingan Anda dalam 7 hari terakhir akan muncul di sini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final avatarUrl =
                            ApiConstants.getImageUrl(item.actorAvatar);
                        final postImageUrl =
                            ApiConstants.getImageUrl(item.postImage);

                        return InkWell(
                          onTap: () => _openUserProfile(
                            item.actorId,
                            item.actorUsername,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                // Avatar Pengguna (Klik untuk mengunjungi profil)
                                GestureDetector(
                                  onTap: () => _openUserProfile(
                                    item.actorId,
                                    item.actorUsername,
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.surface,
                                    backgroundImage: avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl.isEmpty
                                        ? Text(
                                            item.actorUsername.isNotEmpty
                                                ? item.actorUsername[0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const Gap(12),

                                // Deskripsi Aktivitas + Waktu
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${item.actorUsername} ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _buildActionText(item),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        if (item.relativeTime.isNotEmpty)
                                          TextSpan(
                                            text: '  ${item.relativeTime}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Gap(10),

                                // Bagian Kanan: Tombol "Ikuti balik" / "Mengikuti" untuk follow, atau thumbnail foto untuk like/comment
                                if (item.type == 'follow')
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _handleFollowBack(item.actorId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: item.isFollowingBack
                                            ? const Color(0xFFEFEFEF)
                                            : AppColors.primary,
                                        foregroundColor: item.isFollowingBack
                                            ? AppColors.textPrimary
                                            : Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        item.isFollowingBack
                                            ? 'Mengikuti'
                                            : 'Ikuti balik',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: item.isFollowingBack
                                              ? AppColors.textPrimary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (postImageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      postImageUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          Container(
                                        width: 44,
                                        height: 44,
                                        color: AppColors.surface,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
