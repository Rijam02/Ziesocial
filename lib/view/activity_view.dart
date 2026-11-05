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
  String _selectedFilter = 'all'; // 'all', 'follow', 'interaction'
  final Set<String> _readKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications(silent: false);
    });

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

  String _notifKey(NotificationModel item) {
    return '${item.type}_${item.actorId}_${item.postId ?? 0}_${item.createDate}';
  }

  bool _isUnread(NotificationModel item, int index) {
    if (_readKeys.contains(_notifKey(item))) return false;
    // Highlight recent items (top 3 or within recent hours) until tapped or marked read
    return index < 3 ||
        item.relativeTime.contains('d') ||
        item.relativeTime.contains('m') ||
        item.relativeTime.contains('j');
  }

  void _markAllAsRead(List<NotificationModel> items) {
    setState(() {
      for (final item in items) {
        _readKeys.add(_notifKey(item));
      }
    });
  }

  void _openUserProfile(NotificationModel item) {
    setState(() {
      _readKeys.add(_notifKey(item));
    });
    if (item.actorId <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          userId: item.actorId,
          username: item.actorUsername,
        ),
      ),
    );
  }

  Future<void> _handleFollowBack(NotificationModel item) async {
    setState(() {
      _readKeys.add(_notifKey(item));
    });
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId <= 0 || item.actorId <= 0) return;

    await context.read<ProfileViewModel>().toggleFollow(
          targetUserId: item.actorId,
          followerId: currentUserId,
        );
  }

  String _buildActionText(NotificationModel item) {
    switch (item.type) {
      case 'follow':
        return 'mulai mengikuti jurnal Anda.';
      case 'comment':
        final comment = item.commentText ?? '';
        return 'mengomentari karya Anda: "$comment"';
      case 'like':
      default:
        return 'menyukai karya foto Anda.';
    }
  }

  IconData _buildTypeBadgeIcon(String type) {
    switch (type) {
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'like':
      default:
        return Icons.favorite_rounded;
    }
  }

  Color _buildTypeBadgeColor(String type) {
    switch (type) {
      case 'follow':
        return AppColors.deepForest;
      case 'comment':
        return AppColors.sageGreen;
      case 'like':
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final allNotifications = profileVm.notifications;
    final isLoading = profileVm.isLoadingNotifications;

    final filteredNotifications = allNotifications.where((n) {
      if (_selectedFilter == 'follow') return n.type == 'follow';
      if (_selectedFilter == 'interaction') {
        return n.type == 'like' || n.type == 'comment';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(112),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: AppColors.primaryText,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Gap(12),
                      ],
                      const Expanded(
                        child: Text(
                          'Aktivitas',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      if (allNotifications.isNotEmpty)
                        GestureDetector(
                          onTap: () => _markAllAsRead(allNotifications),
                          child: const Text(
                            'Tandai dibaca',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sageGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', 'all'),
                        const Gap(8),
                        _buildFilterChip('Pengikut', 'follow'),
                        const Gap(8),
                        _buildFilterChip('Suka & Komentar', 'interaction'),
                        const Gap(14),
                        const Text(
                          '• 7 Hari Terakhir',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: isLoading && allNotifications.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.sageGreen,
                strokeWidth: 2,
              ),
            )
          : RefreshIndicator(
              color: AppColors.deepForest,
              backgroundColor: AppColors.pureWhite,
              onRefresh: () => _loadNotifications(silent: false),
              child: filteredNotifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.62,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.warmIvory,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      size: 24,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const Gap(14),
                                  const Text(
                                    'Belum Ada Aktivitas Terbaru',
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  const Gap(6),
                                  const Text(
                                    'Pemberitahuan pengikut baru, suka, dan komentar dalam 7 hari terakhir akan ditampilkan di sini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.secondaryText,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredNotifications.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredNotifications[index];
                        final avatarUrl =
                            ApiConstants.getImageUrl(item.actorAvatar);
                        final postImageUrl =
                            ApiConstants.getImageUrl(item.postImage);
                        final unread = _isUnread(item, index);

                        return InkWell(
                          onTap: () => _openUserProfile(item),
                          child: Container(
                            color: unread
                                ? AppColors.warmIvory.withValues(alpha: 0.75)
                                : AppColors.pureWhite,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Unread Dot Indicator
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: unread
                                        ? AppColors.sageGreen
                                        : Colors.transparent,
                                  ),
                                ),

                                // Actor Avatar with Type Badge
                                GestureDetector(
                                  onTap: () => _openUserProfile(item),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 21,
                                        backgroundColor: AppColors.warmIvory,
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
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.deepForest,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: _buildTypeBadgeColor(
                                              item.type,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.pureWhite,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            _buildTypeBadgeIcon(item.type),
                                            size: 9,
                                            color: AppColors.pureWhite,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(14),

                                // Notification Text + Timestamp
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        height: 1.4,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${item.actorUsername} ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _buildActionText(item),
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        if (item.relativeTime.isNotEmpty)
                                          TextSpan(
                                            text: '  •  ${item.relativeTime}',
                                            style: const TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Gap(12),

                                // Action Button ("Ikuti balik" / "Mengikuti") or Post Thumbnail
                                if (item.type == 'follow')
                                  SizedBox(
                                    height: 32,
                                    child: item.isFollowingBack
                                        ? OutlinedButton(
                                            onPressed: () =>
                                                _handleFollowBack(item),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              side: const BorderSide(
                                                color: AppColors.border,
                                              ),
                                              backgroundColor:
                                                  AppColors.pureWhite,
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
                                                _handleFollowBack(item),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.deepForest,
                                              foregroundColor:
                                                  AppColors.pureWhite,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                            ),
                                            child: const Text(
                                              'Ikuti balik',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                  )
                                else if (postImageUrl.isNotEmpty)
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.network(
                                      postImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          Container(
                                        color: AppColors.warmIvory,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          size: 18,
                                          color: AppColors.secondaryText,
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepForest : AppColors.warmIvory,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.deepForest : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.pureWhite : AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}
