import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/view/activity_view.dart';
import 'package:ziesocial/view/create_post_view.dart';
import 'package:ziesocial/view/explore_view.dart';
import 'package:ziesocial/view/home_view.dart';
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
      context.read<ProfileViewModel>().fetchNotifications(
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
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final profileVm = context.watch<ProfileViewModel>();
    final ownProfile = profileVm.getProfile(currentUserId);
    final notificationsCount = profileVm.notifications.length;
    final avatarUrl = ApiConstants.getImageUrl(
      ownProfile?.user.avatar ?? currentUser?.avatar,
    );

    final List<Widget> pages = [
      const HomeView(),
      const ExploreView(),
      const SizedBox.shrink(),
      const ActivityView(),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Beranda',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  label: 'Eksplor',
                ),
                // Center Compose Button
                GestureDetector(
                  onTap: () => _onTabSelected(2),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 42,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.deepForest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.pureWhite,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.notifications_none_rounded,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Aktivitas',
                  badgeCount: notificationsCount,
                ),
                _buildProfileNavItem(
                  index: 4,
                  avatarUrl: avatarUrl,
                  fallbackLetter: currentUser?.username.isNotEmpty == true
                      ? currentUser!.username[0].toUpperCase()
                      : 'U',
                ),
              ],
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
    int badgeCount = 0,
  }) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.deepForest
                      : AppColors.secondaryText,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pureWhite,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.deepForest
                    : AppColors.secondaryText,
                letterSpacing: 0.1,
              ),
            ),
            const Gap(2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 12 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.sageGreen,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({
    required int index,
    required String avatarUrl,
    required String fallbackLetter,
  }) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.sageGreen : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.warmIvory,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        fallbackLetter,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      )
                    : null,
              ),
            ),
            const Gap(4),
            Text(
              'Profil',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.deepForest
                    : AppColors.secondaryText,
                letterSpacing: 0.1,
              ),
            ),
            const Gap(2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 12 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.sageGreen,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
