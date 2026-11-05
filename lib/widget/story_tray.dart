import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/profile_model.dart';
import 'package:ziesocial/model/user_model.dart';
import 'package:ziesocial/view/profile_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class StoryTray extends StatelessWidget {
  final UserModel? currentUser;

  const StoryTray({super.key, this.currentUser});

  void _openUploadStorySheet(BuildContext context, int currentUserId) {
    if (currentUserId <= 0) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CreateStorySheet(userId: currentUserId),
    );
  }

  void _openStoryViewer(
    BuildContext context, {
    required StoryGroupModel group,
    required int viewerId,
  }) {
    if (group.stories.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => _StoryViewerDialog(
        group: group,
        viewerId: viewerId,
        onAddNewStory: group.isOwn
            ? () {
                Navigator.pop(ctx);
                _openUploadStorySheet(context, viewerId);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final profileVm = context.watch<ProfileViewModel>();
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;

    final ownProfile = profileVm.getProfile(currentUserId);
    final myStory = homeVm.myStoryGroup;
    final avatarUrl = ApiConstants.getImageUrl(
      myStory?.avatar.isNotEmpty == true
          ? myStory!.avatar
          : (ownProfile?.user.avatar ?? currentUser?.avatar),
    );

    final bool myHasStory = myStory?.hasStory == true;
    final bool myHasUnseen = myStory?.hasUnseenStory == true;

    final otherGroups = homeVm.storyGroups;

    return Container(
      height: 108,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.8),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: otherGroups.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Item 0: Cerita Anda (foto profil + tombol +)
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () {
                  if (myHasStory && myStory != null) {
                    _openStoryViewer(
                      context,
                      group: myStory,
                      viewerId: currentUserId,
                    );
                  } else {
                    _openUploadStorySheet(context, currentUserId);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Hanya tampilkan border gradient jika user mengupload story dan belum dilihat
                            gradient: (myHasStory && myHasUnseen)
                                ? AppColors.storyGradient
                                : null,
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
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      currentUser?.username.isNotEmpty == true
                                          ? currentUser!.username[0]
                                              .toUpperCase()
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
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                _openUploadStorySheet(context, currentUserId),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.add,
                                size: 14,
                                color: Colors.white,
                              ),
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
              ),
            );
          }

          final group = otherGroups[index - 1];
          final groupAvatarUrl = ApiConstants.getImageUrl(group.avatar);
          final bool showBorder = group.hasStory && group.hasUnseenStory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (group.hasStory) {
                  _openStoryViewer(
                    context,
                    group: group,
                    viewerId: currentUserId,
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileView(
                        userId: group.userId,
                        username: group.username,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Border hanya muncul jika user mengupload story dan belum dilihat oleh kita
                      gradient: showBorder ? AppColors.storyGradient : null,
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
                        backgroundImage: groupAvatarUrl.isNotEmpty
                            ? NetworkImage(groupAvatarUrl)
                            : null,
                        child: groupAvatarUrl.isEmpty
                            ? Text(
                                group.username.isNotEmpty
                                    ? group.username[0].toUpperCase()
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
                  ),
                  const Gap(4),
                  SizedBox(
                    width: 68,
                    child: Text(
                      group.username,
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

class _CreateStorySheet extends StatefulWidget {
  final int userId;

  const _CreateStorySheet({required this.userId});

  @override
  State<_CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<_CreateStorySheet> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  XFile? _selectedFile;
  Uint8List? _imageBytes;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran gambar maksimal 5MB.')),
      );
      return;
    }

    setState(() {
      _selectedFile = picked;
      _imageBytes = bytes;
    });
  }

  Future<void> _uploadStory() async {
    if (_selectedFile == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto untuk story terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final homeVm = context.read<HomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await homeVm.createStory(
      userId: widget.userId,
      imagePath: _selectedFile!.path,
      imageBytes: _imageBytes,
      fileName: _selectedFile!.name,
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cerita berhasil diunggah (berlaku 24 jam)!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(homeVm.errorMessage ?? 'Gagal mengunggah cerita.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah ke Cerita (24 Jam)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const Divider(height: 1),
              const Gap(14),
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    width: double.infinity,
                    color: Colors.black,
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.amp_stories_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const Gap(8),
                      const Text(
                        'Pilih foto untuk dibagikan ke Cerita Anda',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Galeri'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const Gap(10),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Kamera'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const Gap(12),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: 'Tulis keterangan cerita (opsional)...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Gap(14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Bagikan Cerita',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryViewerDialog extends StatefulWidget {
  final StoryGroupModel group;
  final int viewerId;
  final VoidCallback? onAddNewStory;

  const _StoryViewerDialog({
    required this.group,
    required this.viewerId,
    this.onAddNewStory,
  });

  @override
  State<_StoryViewerDialog> createState() => _StoryViewerDialogState();
}

class _StoryViewerDialogState extends State<_StoryViewerDialog> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markCurrentAsViewed();
    });
  }

  void _markCurrentAsViewed() {
    if (widget.group.stories.isEmpty) return;
    final currentStory = widget.group.stories[_currentIndex];
    context.read<HomeViewModel>().markStoryViewed(
          viewerId: widget.viewerId,
          storyId: currentStory.id,
          targetUserId: widget.group.userId,
        );
  }

  void _nextStory() {
    if (_currentIndex < widget.group.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markCurrentAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _markCurrentAsViewed();
    }
  }

  void _showViewersSheet(StoryItemModel story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewers = story.viewers;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 20),
                    const Gap(8),
                    Text(
                      'Riwayat Penonton (${viewers.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (viewers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    'Belum ada pengguna lain yang menonton cerita ini.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: viewers.length,
                    itemBuilder: (context, i) {
                      final v = viewers[i];
                      final vAvatar = ApiConstants.getImageUrl(v.avatar);
                      return ListTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pop(this.context);
                          Navigator.push(
                            this.context,
                            MaterialPageRoute(
                              builder: (_) => ProfileView(
                                userId: v.userId,
                                username: v.username,
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surface,
                          backgroundImage: vAvatar.isNotEmpty
                              ? NetworkImage(vAvatar)
                              : null,
                          child: vAvatar.isEmpty
                              ? Text(
                                  v.username.isNotEmpty
                                      ? v.username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          v.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: v.name.isNotEmpty ? Text(v.name) : null,
                      );
                    },
                  ),
                ),
              const Gap(12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan data terbaru dari HomeViewModel agar daftar penonton selalu ter-update
    final latestGroup = context
            .watch<HomeViewModel>()
            .getStoryGroupForUser(widget.group.userId) ??
        widget.group;
    final stories = latestGroup.stories.isNotEmpty
        ? latestGroup.stories
        : widget.group.stories;
    final safeIndex =
        _currentIndex < stories.length ? _currentIndex : stories.length - 1;
    final story = stories[safeIndex];

    final storyImageUrl = ApiConstants.getImageUrl(story.image);
    final authorAvatarUrl = ApiConstants.getImageUrl(latestGroup.avatar);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Gambar Story
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < screenWidth * 0.35) {
                    _prevStory();
                  } else {
                    _nextStory();
                  }
                },
                child: Center(
                  child: storyImageUrl.isNotEmpty
                      ? Image.network(
                          storyImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                ),
              ),
            ),

            // Progress Bar Indikator di Atas + Header Profil
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Row(
                    children: List.generate(stories.length, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= safeIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileView(
                                userId: latestGroup.userId,
                                username: latestGroup.username,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.surface,
                              backgroundImage: authorAvatarUrl.isNotEmpty
                                  ? NetworkImage(authorAvatarUrl)
                                  : null,
                              child: authorAvatarUrl.isEmpty
                                  ? Text(
                                      latestGroup.username.isNotEmpty
                                          ? latestGroup.username[0]
                                              .toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                            const Gap(10),
                            Text(
                              latestGroup.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (widget.onAddNewStory != null)
                        IconButton(
                          onPressed: widget.onAddNewStory,
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                          ),
                          tooltip: 'Tambah Story Baru',
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Caption & Riwayat Penonton di Bagian Bawah
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (story.caption.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        story.caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  if (latestGroup.isOwn) ...[
                    const Gap(12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => _showViewersSheet(story),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const Gap(6),
                              Text(
                                '${story.viewers.length} penonton',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
