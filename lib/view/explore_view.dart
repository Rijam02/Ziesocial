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
                        'Sorotan Karya',
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

    for (final user in apiUsers) {
      userMap[user.id] = user;
    }

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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Eksplorasi',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Text(
                        isSearchingMode
                            ? '${matchedUsers.length} Akun'
                            : '${posts.length} Karya',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari kreator berdasarkan username atau nama...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 19,
                          color: AppColors.secondaryText,
                        ),
                        suffixIcon: isSearchingMode
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 17,
                                  color: AppColors.secondaryText,
                                ),
                                onPressed: _clearSearch,
                                padding: EdgeInsets.zero,
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.warmIvory,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.sageGreen,
                            width: 1.2,
                          ),
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
      body: isSearchingMode
          ? _buildSearchResults(matchedUsers, profileVm.isSearching)
          : _buildExploreGallery(posts),
    );
  }

  Widget _buildSearchResults(List<UserModel> users, bool isLoading) {
    if (isLoading && users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.sageGreen,
          strokeWidth: 2,
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warmIvory,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.person_search_outlined,
                  size: 22,
                  color: AppColors.secondaryText,
                ),
              ),
              const Gap(12),
              Text(
                'Kreator "$_searchQuery" tidak ditemukan',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(4),
              const Text(
                'Coba gunakan kata kunci atau username lainnya.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final homeVm = context.watch<HomeViewModel>();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      itemCount: users.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        color: AppColors.border,
      ),
      itemBuilder: (context, index) {
        final user = users[index];
        final avatarUrl = ApiConstants.getImageUrl(user.avatar);
        final uid = int.tryParse(user.id) ?? 0;
        final hasUnseen = homeVm.hasUnseenStoryForUser(uid);

        return InkWell(
          onTap: () => _openUserProfile(user),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(hasUnseen ? 2 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasUnseen ? AppColors.storyGradient : null,
                    border: hasUnseen
                        ? null
                        : Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(hasUnseen ? 1.5 : 0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pureWhite,
                    ),
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: AppColors.warmIvory,
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.deepForest,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmIvory,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Kunjungi',
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
        );
      },
    );
  }

  Widget _buildExploreGallery(List<PostModel> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada karya visual untuk dijelajahi.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13.5),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.border,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1.5,
          mainAxisSpacing: 1.5,
          childAspectRatio: 0.78,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final imageUrl = ApiConstants.getImageUrl(post.image);
          final authorUsername = post.author?.username ?? '';

          return GestureDetector(
            onTap: () => _openPostDetail(post),
            child: Container(
              color: AppColors.warmIvory,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  if (authorUsername.isNotEmpty)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '@$authorUsername',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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
    );
  }
}
