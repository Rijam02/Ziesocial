import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/widget/post_card.dart';

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<HomeViewModel>().posts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: SizedBox(
          height: 38,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pengguna atau tagar...',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
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
      body: posts.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada konten untuk dijelajahi.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : GridView.builder(
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
                              child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
