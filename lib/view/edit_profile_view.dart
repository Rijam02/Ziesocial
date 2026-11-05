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
  late final TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedAvatar;
  Uint8List? _avatarBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final userId = int.tryParse(widget.user.id) ?? 0;
    final updatedUser = await context.read<ProfileViewModel>().updateProfile(
          userId: userId,
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui profil.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConstants.getImageUrl(widget.user.avatar);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
        ),
        leadingWidth: 70,
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Selesai',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Avatar picker
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : (avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) as ImageProvider : null),
                      child: _avatarBytes == null && avatarUrl.isEmpty
                          ? Text(
                              widget.user.name.isNotEmpty
                                  ? widget.user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: const Text(
                      'Ubah foto profil',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(32),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Nama lengkap Anda',
              ),
            ),
            const Gap(16),

            // Bio
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tulis bio profil Anda...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
