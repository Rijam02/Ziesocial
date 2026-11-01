import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/user_model.dart';

class StoryTray extends StatelessWidget {
  final UserModel? currentUser;

  const StoryTray({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConstants.getImageUrl(currentUser?.avatar);

    final mockStories = [
      {'name': 'Agis', 'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150', 'hasStory': true},
      {'name': 'Rijam', 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', 'hasStory': true},
      {'name': 'sarah_k', 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', 'hasStory': true},
      {'name': 'alex_dev', 'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', 'hasStory': true},
      {'name': 'nina_art', 'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150', 'hasStory': true},
    ];

    return Container(
      height: 104,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.8),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: mockStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Your story
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.surface,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  currentUser?.username.isNotEmpty == true
                                      ? currentUser!.username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  const Text(
                    'Cerita Anda',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }

          final story = mockStories[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka cerita dari ${story['name']}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.storyGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.surface,
                        backgroundImage: NetworkImage(story['avatar'] as String),
                      ),
                    ),
                  ),
                  const Gap(4),
                  SizedBox(
                    width: 68,
                    child: Text(
                      story['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
