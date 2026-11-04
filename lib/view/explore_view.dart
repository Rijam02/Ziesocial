import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/model/user_model.dart';
import 'package:ziesocial/view/profile_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';
import 'package:ziesocial/widget/post_card.dart';

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });

    _debounce?.cancel();
    if (_searchQuery.isEmpty) {
      context.read<ProfileViewModel>().searchUsers('');
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        context.read<ProfileViewModel>().searchUsers(_searchQuery);
      }
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    context.read<ProfileViewModel>().searchUsers('');
    FocusScope.of(context).unfocus();
  }

  void _openUserProfile(UserModel user) {
    final userId = int.tryParse(user.id);
    if (userId == null || userId <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          userId: userId,
          username: user.username,
        ),
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
                        'Jelajahi',
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
                      PostCard(post: post),
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

  List<UserModel> _getCombinedUsers(
    List<UserModel> apiUsers,
    List<PostModel> posts,
    String query,
  ) {
    final q = query.toLowerCase();
    final Map<String, UserModel> userMap = {};

    // 1. Masukkan hasil dari API search
    for (final user in apiUsers) {
      userMap[user.id] = user;
    }

    // 2. Gabungkan juga dari daftar author postingan yang cocok dengan query
    for (final post in posts) {
      final author = post.author;
      if (author != null) {
        final matchUsername = author.username.toLowerCase().contains(q);
        final matchName = author.name.toLowerCase().contains(q);
        if (matchUsername || matchName) {
          final idStr = author.id.toString();
          if (!userMap.containsKey(idStr)) {
            userMap[idStr] = UserModel(
              id: idStr,
              username: author.username,
              email: '',
              name: author.name,
              avatar: author.avatar ?? '',
              bio: '',
            );
          }
        }
      }
    }

    return userMap.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<HomeViewModel>().posts;
    final profileVm = context.watch<ProfileViewModel>();

    final bool isSearchingMode = _searchQuery.isNotEmpty;
    final List<UserModel> matchedUsers = isSearchingMode
        ? _getCombinedUsers(profileVm.searchedUsers, posts, _searchQuery)
        : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: SizedBox(
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari pengguna dengan username...',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
              suffixIcon: isSearchingMode
                  ? IconButton(
                      icon: const Icon(Icons.cancel, size: 18, color: AppColors.textSecondary),
                      onPressed: _clearSearch,
                      padding: EdgeInsets.zero,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFEFEFEF),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: isSearchingMode
          ? _buildSearchResults(matchedUsers, profileVm.isSearching)
          : _buildExploreGrid(posts),
    );
  }

  Widget _buildSearchResults(List<UserModel> users, bool isLoading) {
    if (isLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const Gap(12),
            Text(
              'Pengguna "$_searchQuery" tidak ditemukan.',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 76,
        color: AppColors.borderLight,
      ),
      itemBuilder: (context, index) {
        final user = users[index];
        final avatarUrl = ApiConstants.getImageUrl(user.avatar);

        return ListTile(
          onTap: () => _openUserProfile(user),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.storyGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          title: Text(
            user.username,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: user.name.isNotEmpty
              ? Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildExploreGrid(List<PostModel> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada konten untuk dijelajahi.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final imageUrl = ApiConstants.getImageUrl(post.image);

        return GestureDetector(
          onTap: () => _openPostDetail(post),
          child: Container(
            color: AppColors.surface,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Center(
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
    );
  }
}
