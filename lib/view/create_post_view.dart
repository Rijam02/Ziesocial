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
  final bool initialHighlightMode;

  const CreatePostView({
    super.key,
    this.initialHighlightMode = false,
  });

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _captionController = TextEditingController();
  final _highlightTitleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  late bool _isHighlight;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _isHighlight = widget.initialHighlightMode;
  }

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
      setState(() {
        _localError = 'Ukuran gambar maksimal 5MB.';
      });
      return;
    }

    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
      _localError = null;
    });
  }

  Future<void> _handleShare() async {
    if (_selectedImage == null || _selectedImageBytes == null) {
      setState(() {
        _localError = 'Pilih foto terlebih dahulu sebelum menerbitkan postingan.';
      });
      return;
    }

    final highlightTitle = _highlightTitleController.text.trim();
    if (_isHighlight && highlightTitle.isEmpty) {
      setState(() {
        _localError = 'Masukkan judul sorotan profil terlebih dahulu.';
      });
      return;
    }

    final currentUser = context.read<LoginViewModel>().user;
    if (currentUser == null) {
      setState(() {
        _localError = 'Sesi akun tidak ditemukan. Silakan masuk kembali.';
      });
      return;
    }

    setState(() => _localError = null);

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
      if (userId > 0) {
        profileVm.fetchProfile(userId, viewerId: userId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isHighlight
                ? 'Postingan & Sorotan "$highlightTitle" berhasil diterbitkan.'
                : 'Postingan baru berhasil diterbitkan.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final error = context.read<CreatePostViewModel>().errorMessage;
      setState(() {
        _localError = error ?? 'Gagal menerbitkan postingan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CreatePostViewModel>().isLoading;
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final existingHighlights = context
            .watch<ProfileViewModel>()
            .getProfile(currentUserId)
            ?.highlights ??
        [];
    final avatarUrl = ApiConstants.getImageUrl(currentUser?.avatar);

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: AppColors.primaryText,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Gap(4),
                  const Text(
                    'Unggah Karya Baru',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleShare,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepForest,
                        foregroundColor: AppColors.pureWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pureWhite,
                              ),
                            )
                          : const Text(
                              'Terbitkan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_localError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            _localError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                ],

                // 1. Image Picker & Preview Frame
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (_selectedImageBytes != null)
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 380),
                              color: const Color(0xFF181B18),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                  onTap: () => _pickImage(ImageSource.gallery),
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        Gap(6),
                                        Text(
                                          'Ganti Foto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          height: 250,
                          width: double.infinity,
                          color: AppColors.pureWhite,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.warmIvory,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 26,
                                  color: AppColors.deepForest,
                                ),
                              ),
                              const Gap(14),
                              const Text(
                                'Pilih Foto Postingan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const Gap(4),
                              const Text(
                                'Format JPG, PNG, atau WEBP (maksimal 5MB)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const Gap(18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.gallery),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 17,
                                    ),
                                    label: const Text('Pilih dari Galeri'),
                                  ),
                                  const Gap(10),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickImage(ImageSource.camera),
                                    icon: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 17,
                                    ),
                                    label: const Text('Kamera'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Gap(16),

                // 2. Editorial Caption Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.warmIvory,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? Text(
                                    currentUser?.username.isNotEmpty == true
                                        ? currentUser!.username[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepForest,
                                    ),
                                  )
                                : null,
                          ),
                          const Gap(10),
                          Text(
                            '@${currentUser?.username ?? "pengguna"}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      TextField(
                        controller: _captionController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryText,
                          height: 1.45,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Ceritakan kisah atau konteks di balik foto ini...',
                          fillColor: AppColors.warmIvory,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),

                // 3. Highlight (Sorotan Profil) Option
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.warmIvory,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.bookmarks_outlined,
                              size: 18,
                              color: AppColors.deepForest,
                            ),
                          ),
                          const Gap(12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jadikan Sorotan Profil',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                Gap(2),
                                Text(
                                  'Simpan postingan ini pada koleksi Sorotan di halaman profil Anda',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isHighlight,
                            activeTrackColor: AppColors.sageGreen,
                            activeThumbColor: AppColors.pureWhite,
                            onChanged: (val) {
                              setState(() {
                                _isHighlight = val;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_isHighlight) ...[
                        const Gap(16),
                        const Text(
                          'Judul Sorotan',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const Gap(6),
                        TextField(
                          controller: _highlightTitleController,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: const InputDecoration(
                            hintText:
                                'Contoh: Arsitektur, Perjalanan, Jurnal...',
                            prefixIcon: Icon(
                              Icons.label_outline_rounded,
                              size: 18,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                        if (existingHighlights.isNotEmpty) ...[
                          const Gap(12),
                          const Text(
                            'Atau tambahkan ke sorotan yang sudah ada:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const Gap(8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: existingHighlights.map((hl) {
                              final isSelected =
                                  _highlightTitleController.text.trim() ==
                                      hl.title;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _highlightTitleController.text = hl.title;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.softBeige
                                            .withValues(alpha: 0.45)
                                        : AppColors.warmIvory,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.sageGreen
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    hl.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
