import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/view/create_post_view.dart';
import 'package:ziesocial/view/explore_view.dart';
import 'package:ziesocial/view/home_view.dart';
import 'package:ziesocial/view/messages_view.dart';
import 'package:ziesocial/view/profile_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class MainNavigationView extends StatefulWidget {
  final int initialIndex;

  const MainNavigationView({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Future<void> _onTabSelected(int index) async {
    if (index == 2) {
      // Tombol unggah postingan
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostView()),
      );
      if (created == true && mounted) {
        setState(() => _currentIndex = 0);
        final currentUser = context.read<LoginViewModel>().user;
        final currentUserId = int.tryParse(currentUser?.id ?? '0');
        context.read<HomeViewModel>().fetchPosts(viewerId: currentUserId);
      }
      return;
    }

    setState(() => _currentIndex = index);

    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;

    if (index == 3 && currentUserId > 0) {
      context.read<ProfileViewModel>().fetchNotesAndUsers(
            currentUserId,
            silent: false,
          );
    } else if (index == 4 && currentUserId > 0) {
      context.read<ProfileViewModel>().fetchProfile(
            currentUserId,
            viewerId: currentUserId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeView(),
      const ExploreView(),
      const SizedBox.shrink(),
      const MessagesView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.90),
              border: Border(
                top: BorderSide(
                  color:
                      AppColors.surfaceContainerHighest.withValues(alpha: 0.60),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 1. Beranda (home)
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'home',
                      ),
                      // 2. Eksplor (explore)
                      _buildNavItem(
                        index: 1,
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore_rounded,
                        label: 'explore',
                      ),
                      // 3. Tombol Tambah (+) / Post Squircle Center Button
                      GestureDetector(
                        onTap: () => _onTabSelected(2),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      // 4. Pesan (Forum)
                      _buildNavItem(
                        index: 3,
                        icon: Icons.forum_outlined,
                        activeIcon: Icons.forum_rounded,
                        label: 'Forum',
                      ),
                      // 5. Profil
                      _buildNavItem(
                        index: 4,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profil',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
            const Gap(2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const Gap(2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 14 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
