import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/viewmodel/create_post_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _captionController = TextEditingController();
  final _highlightTitleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isHighlight = false;

  @override
  void dispose() {
    _captionController.dispose();
    _highlightTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final fileSize = bytes.lengthInBytes;

    if (fileSize > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran gambar maksimal 5MB.')),
      );
      return;
    }

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _handleShare() async {
    if (_selectedImage == null || _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar postingan terlebih dahulu.')),
      );
      return;
    }

    final highlightTitle = _highlightTitleController.text.trim();
    if (_isHighlight && highlightTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nama sorotan terlebih dahulu.'),
        ),
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
    final profileVm = context.read<ProfileViewModel>();

    final success = await context.read<CreatePostViewModel>().createPost(
          userId: userId,
          imagePath: _selectedImage!.path,
          imageBytes: _selectedImageBytes,
          fileName: _selectedImage!.name,
          caption: _captionController.text.trim(),
          isHighlight: _isHighlight,
          highlightTitle: highlightTitle,
        );

    if (!mounted) return;

    if (success) {
      // Perbarui profil agar postingan dan sorotan terbaru langsung muncul
      if (userId > 0) {
        profileVm.fetchProfile(userId, viewerId: userId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHighlight
                ? 'Postingan & Sorotan "$highlightTitle" berhasil dibagikan!'
                : 'Postingan berhasil dibagikan!',
          ),
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
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final existingHighlights =
        context.watch<ProfileViewModel>().getProfile(currentUserId)?.highlights ?? [];
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
                        hintText: 'Tulis keterangan postingan...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Gap(8),
                  if (_selectedImageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        _selectedImageBytes!,
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
            if (_selectedImageBytes != null)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 380),
                color: Colors.black,
                child: Image.memory(
                  _selectedImageBytes!,
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

            if (_selectedImageBytes != null) ...[
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

            // Fitur Jadikan Sorotan (Highlight)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.auto_awesome_outlined,
                            color: AppColors.textPrimary,
                          ),
                          Gap(12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadikan Sorotan Profil',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Tampilkan postingan ini di menu sorotan profil Anda',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isHighlight,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isHighlight = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isHighlight) ...[
                    const Gap(12),
                    TextField(
                      controller: _highlightTitleController,
                      decoration: InputDecoration(
                        labelText: 'Nama Sorotan',
                        hintText: 'Contoh: Liburan, Kuliner, Momen...',
                        prefixIcon: const Icon(Icons.bookmark_border),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (existingHighlights.isNotEmpty) ...[
                      const Gap(8),
                      const Text(
                        'Atau pilih sorotan yang sudah ada:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: existingHighlights.map((hl) {
                          return ActionChip(
                            label: Text(hl.title),
                            onPressed: () {
                              setState(() {
                                _highlightTitleController.text = hl.title;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
