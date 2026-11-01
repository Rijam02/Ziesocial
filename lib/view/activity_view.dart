import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ziesocial/core/app_theme.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'user': 'Agis',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        'action': 'menyukai postingan Anda.',
        'time': '3 j',
        'type': 'like'
      },
      {
        'user': 'Rijam',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'action': 'mulai mengikuti Anda.',
        'time': '1 h',
        'type': 'follow'
      },
      {
        'user': 'sarah_k',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        'action': 'mengomentari: "Keren sekali fotonya!"',
        'time': '2 h',
        'type': 'comment'
      },
      {
        'user': 'alex_dev',
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        'action': 'menyukai postingan Anda.',
        'time': '1 m',
        'type': 'like'
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surface,
                  backgroundImage: NetworkImage(item['avatar']!),
                ),
                const Gap(12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${item['user']} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                        TextSpan(
                          text: item['action'],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                        TextSpan(
                          text: ' ${item['time']}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (item['type'] == 'follow')
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Ikuti Balik',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
