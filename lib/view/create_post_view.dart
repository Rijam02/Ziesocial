import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/viewmodel/create_post_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image == null) return;

    final file = File(image.path);
    final fileSize = await file.length();

    if (fileSize > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran gambar maksimal 5MB.')),
      );
      return;
    }

    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _handleShare() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar postingan terlebih dahulu.')),
      );
      return;
    }

    final currentUser = context.read<LoginViewModel>().user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      return;
    }

    final userId = int.tryParse(currentUser.id) ?? 0;
    final success = await context.read<CreatePostViewModel>().createPost(
          userId: userId,
          imagePath: _selectedImage!.path,
          caption: _captionController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Postingan berhasil dibagikan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      final error = context.read<CreatePostViewModel>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal membuat postingan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CreatePostViewModel>().isLoading;
    final currentUser = context.watch<LoginViewModel>().user;
    final avatarUrl = ApiConstants.getImageUrl(currentUser?.avatar);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Postingan Baru',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _handleShare,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Bagikan',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section: Avatar + Caption Textarea + Image Thumbnail
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surface,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            currentUser?.username.isNotEmpty == true
                                ? currentUser!.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : null,
                  ),
                  const Gap(12),
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Tulis keterangan atau tambahkan polling...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Gap(8),
                  if (_selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(_selectedImage!.path),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Large Image Preview or Picker
            if (_selectedImage != null)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 380),
                color: Colors.black,
                child: Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                height: 280,
                width: double.infinity,
                color: AppColors.surface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(12),
                    const Text(
                      'Pilih foto dari Galeri atau Kamera',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeri'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                        const Gap(12),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Kamera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (_selectedImage != null) ...[
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Ganti Gambar'),
                  ),
                ],
              ),
            ],

            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_pin_outlined),
              title: const Text('Tandai Orang'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Tambahkan Lokasi'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: const Text('Tambahkan Musik'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {},
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}