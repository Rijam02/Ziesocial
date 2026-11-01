import 'package:flutter/material.dart';
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

  void _onTabSelected(int index) async {
    if (index == 2) {
      // Tombol tambah postingan membuka CreatePostView
      final created = await Navigator.push(
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
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LoginViewModel>().user;
    final avatarUrl = ApiConstants.getImageUrl(currentUser?.avatar);

    final List<Widget> pages = [
      const HomeView(),
      const ExploreView(),
      const SizedBox.shrink(), // Placeholder untuk tombol add
      const ActivityView(),
      const ProfileView(), // Menampilkan profil user saat ini
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                size: 28,
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 1 ? Icons.search : Icons.search_outlined,
                size: 28,
              ),
              label: 'Cari',
            ),
            const BottomNavigationBarItem(
              icon: Icon(
                Icons.add_box_outlined,
                size: 28,
              ),
              label: 'Tambah',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 3 ? Icons.favorite : Icons.favorite_border,
                size: 26,
              ),
              label: 'Aktivitas',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentIndex == 4
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.surface,
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          currentUser?.username.isNotEmpty == true
                              ? currentUser!.username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : null,
                ),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
