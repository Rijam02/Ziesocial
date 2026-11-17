import 'dart:async';
import 'dart:ui';
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
  static const String _logoUrl =
      'https://lh3.googleusercontent.com/aida/ALJJyrAGz0ngow3as-1-re5ci2YrUi5fcQVaSwLyJuphJXXcEeZCsLYn1KWDiOWWi8n8QFxhfWPHifPhM973z39xjzRvUFc70o1PmKvKzdcfe7O0PHkczjocI9iCpf5giaF2_R9nULtM_F0XtZQmX9kjfBpU_QXPK2uhne2dmPzIiMv-LnTDmjV4H3WlH44_P8wQGggIjaqhrgY7_R4h43bMywuhZCS1eY1I9TgCpjXZi7BayQ';

  Timer? _notificationPoller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
      _loadNotifications(silent: true);
    });

    // Polling real-time untuk notifikasi aktivitas & story
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
      context.read<HomeViewModel>().fetchStories(viewerId: currentUserId);
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
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Brand Logo + ZieSocial Title
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surfaceContainer,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.onSurface
                                        .withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Image.network(
                                _logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Text(
                                    'Z',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Gap(8),
                            const Text(
                              'ZieSocial',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),

                        // Love / Notifications Button
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: _openActivityView,
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.favorite_border_rounded,
                                    size: 24,
                                    color: AppColors.onSurface,
                                  ),
                                  if (notificationsCount > 0)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.surface,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Micro Luminescent Background Blur Spheres
          Positioned(
            top: -48,
            left: -64,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                child: Container(
                  width: 224,
                  height: 224,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryFixed.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -64,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                child: Container(
                  width: 208,
                  height: 208,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tertiaryFixedDim.withValues(alpha: 0.30),
                  ),
                ),
              ),
            ),
          ),

          // Main Feed Stream
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLowest,
            onRefresh: () async {
              _loadFeed();
              _loadNotifications(silent: true);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Story Harian Section
                SliverToBoxAdapter(
                  child: StoryTray(currentUser: currentUser),
                ),

                // 2. Loading State
                if (homeVm.isLoading && homeVm.posts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
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
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.surfaceContainer,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.cloud_off_outlined,
                                  size: 24,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const Gap(16),
                              const Text(
                                'Tidak dapat memuat beranda',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const Gap(6),
                              Text(
                                homeVm.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const Gap(18),
                              OutlinedButton.icon(
                                onPressed: _loadFeed,
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
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
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.surfaceContainer,
                                ),
                              ),
                              child: const Icon(
                                Icons.photo_camera_back_outlined,
                                size: 26,
                                color: AppColors.primary,
                              ),
                            ),
                            const Gap(16),
                            const Text(
                              'Beranda Masih Kosong',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Gap(6),
                            const Text(
                              'Bagikan karya visual pertama Anda atau jelajahi kreator lain di ZieSocial.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13.5,
                                color: AppColors.onSurfaceVariant,
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
                // 5. Post Feed Stream + "Semua Cerita Telah Diperbarui" Footer Card
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = homeVm.posts[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 512),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: PostCard(
                                  post: post,
                                  onPostDeleted: () => _loadFeed(),
                                  onPostUpdated: () => _loadFeed(),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: homeVm.posts.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 512),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.surfaceContainer,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 22,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Gap(8),
                                const Text(
                                  'Semua Cerita Telah Diperbarui',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const Gap(2),
                                const Text(
                                  'Anda telah melihat postingan terbaru dalam 24 jam terakhir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
