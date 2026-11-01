import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/view/create_post_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/widget/post_card.dart';
import 'package:ziesocial/widget/story_tray.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
  }

  void _loadFeed() {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0');
    context.read<HomeViewModel>().fetchPosts(viewerId: currentUserId);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ZieSocial',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tidak ada notifikasi baru.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.favorite_border, size: 26),
            tooltip: 'Aktivitas',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesan Langsung (Direct Message)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(CupertinoIcons.paperplane, size: 24),
            tooltip: 'Pesan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadFeed(),
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
                  child: CircularProgressIndicator(),
                ),
              )
            // 3. Error State
            else if (homeVm.errorMessage != null && homeVm.posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_outlined,
                          size: 56,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(12),
                        const Text(
                          'Gagal Memuat Beranda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          homeVm.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Gap(16),
                        ElevatedButton.icon(
                          onPressed: _loadFeed,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // 4. Empty State
            else if (homeVm.posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const Gap(12),
                      const Text(
                        'Selamat Datang di ZieSocial!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Gap(6),
                      const Text(
                        'Mulai ikuti teman atau bagikan foto pertama Anda.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(20),
                      ElevatedButton.icon(
                        onPressed: _navigateToCreatePost,
                        icon: const Icon(Icons.add),
                        label: const Text('Buat Postingan Baru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // 5. Posts Feed List
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = homeVm.posts[index];
                    return PostCard(
                      post: post,
                      onPostDeleted: () => _loadFeed(),
                      onPostUpdated: () => _loadFeed(),
                    );
                  },
                  childCount: homeVm.posts.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}