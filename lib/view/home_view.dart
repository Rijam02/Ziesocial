import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/view/activity_view.dart';
import 'package:ziesocial/view/create_post_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';
import 'package:ziesocial/widget/post_card.dart';
import 'package:ziesocial/widget/story_tray.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Timer? _notificationPoller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
      _loadNotifications(silent: true);
    });

    // Polling real-time untuk notifikasi aktivitas
    _notificationPoller = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadNotifications(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _notificationPoller?.cancel();
    super.dispose();
  }

  void _loadFeed() {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0');
    context.read<HomeViewModel>().fetchPosts(viewerId: currentUserId);
  }

  void _loadNotifications({bool silent = false}) {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId > 0) {
      context
          .read<ProfileViewModel>()
          .fetchNotifications(currentUserId, silent: silent);
    }
  }

  void _openActivityView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivityView()),
    );
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostView()),
    );

    if (result == true && mounted) {
      _loadFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final currentUser = context.watch<LoginViewModel>().user;
    final notificationsCount =
        context.watch<ProfileViewModel>().notifications.length;

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Text(
                    'ZieSocial',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Gap(10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmIvory,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Text(
                      'EDITORIAL',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.sageGreen,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _navigateToCreatePost,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 22,
                      color: AppColors.primaryText,
                    ),
                    tooltip: 'Unggah Postingan',
                  ),
                  IconButton(
                    onPressed: _openActivityView,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 23,
                          color: AppColors.primaryText,
                        ),
                        if (notificationsCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.sageGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.pureWhite,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    tooltip: 'Aktivitas',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.deepForest,
        backgroundColor: AppColors.pureWhite,
        onRefresh: () async {
          _loadFeed();
          _loadNotifications(silent: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Stories Tray
            SliverToBoxAdapter(
              child: StoryTray(currentUser: currentUser),
            ),

            // 2. Loading State
            if (homeVm.isLoading && homeVm.posts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.sageGreen,
                    strokeWidth: 2,
                  ),
                ),
              )
            // 3. Error State
            else if (homeVm.errorMessage != null && homeVm.posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.warmIvory,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.cloud_off_outlined,
                              size: 24,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const Gap(16),
                          const Text(
                            'Tidak dapat memuat beranda',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            homeVm.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                          const Gap(18),
                          OutlinedButton.icon(
                            onPressed: _loadFeed,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Muat Ulang'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            // 4. Empty State
            else if (homeVm.posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.warmIvory,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.photo_camera_back_outlined,
                            size: 26,
                            color: AppColors.deepForest,
                          ),
                        ),
                        const Gap(16),
                        const Text(
                          'Jurnal Beranda Masih Kosong',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const Gap(6),
                        const Text(
                          'Bagikan karya visual pertama Anda atau jelajahi kreator lain di ZieSocial.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                        const Gap(20),
                        ElevatedButton.icon(
                          onPressed: _navigateToCreatePost,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Unggah Postingan Pertama'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // 5. Editorial Posts Feed List
            else
              SliverPadding(
                padding: const EdgeInsets.only(top: 4, bottom: 28),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = homeVm.posts[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: PostCard(
                            post: post,
                            onPostDeleted: () => _loadFeed(),
                            onPostUpdated: () => _loadFeed(),
                          ),
                        ),
                      );
                    },
                    childCount: homeVm.posts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
