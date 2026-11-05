import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/user_model.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class EditProfileView extends StatefulWidget {
  final UserModel user;

  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedAvatar;
  Uint8List? _avatarBytes;
  bool _isSaving = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedAvatar = file;
        _avatarBytes = bytes;
        _validationError = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _validationError = 'Nama lengkap tidak boleh kosong.';
      });
      return;
    }

    if (username.isEmpty) {
      setState(() {
        _validationError = 'Username tidak boleh kosong.';
      });
      return;
    }

    if (username.contains(' ')) {
      setState(() {
        _validationError = 'Username tidak boleh mengandung spasi.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _validationError = null;
    });

    final userId = int.tryParse(widget.user.id) ?? 0;
    final profileVm = context.read<ProfileViewModel>();
    final updatedUser = await profileVm.updateProfile(
      userId: userId,
      name: name,
      username: username,
      bio: bio,
      avatarPath: _selectedAvatar?.path,
      avatarBytes: _avatarBytes,
      avatarFileName: _selectedAvatar?.name,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (updatedUser != null) {
      context.read<LoginViewModel>().setUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _validationError =
            profileVm.getErrorMessage(userId) ?? 'Gagal memperbarui profil.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConstants.getImageUrl(widget.user.avatar);

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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Gap(4),
                  const Text(
                    'Edit Profil',
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
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepForest,
                        foregroundColor: AppColors.pureWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pureWhite,
                              ),
                            )
                          : const Text(
                              'Simpan',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_validationError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
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
                              _validationError!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(18),
                  ],

                  // Avatar Picker
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundColor: AppColors.warmIvory,
                                  backgroundImage: _avatarBytes != null
                                      ? MemoryImage(_avatarBytes!)
                                      : (avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                              as ImageProvider
                                          : null),
                                  child: _avatarBytes == null &&
                                          avatarUrl.isEmpty
                                      ? Text(
                                          widget.user.name.isNotEmpty
                                              ? widget.user.name[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.deepForest,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.deepForest,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.pureWhite,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 14,
                                    color: AppColors.pureWhite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(10),
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: const Text(
                            'Ubah Foto Profil',
                            style: TextStyle(
                              color: AppColors.deepForest,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(28),

                  // Full Name
                  const Text(
                    'Nama Lengkap',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Gap(6),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Masukkan nama lengkap Anda',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const Gap(16),

                  // Username
                  const Text(
                    'Nama Pengguna (Username)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Gap(6),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Masukkan username unik',
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        size: 18,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const Gap(16),

                  // Bio
                  const Text(
                    'Biografi Singkat',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Gap(6),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                    decoration: const InputDecoration(
                      hintText: 'Ceritakan sedikit tentang diri atau minat Anda...',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
