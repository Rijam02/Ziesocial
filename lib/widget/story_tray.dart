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
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
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
      decoration: const BoxDecoration(
        color: AppColors.warmIvory,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CERITA HARIAN',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppColors.secondaryText,
                  ),
                ),
                GestureDetector(
                  onTap: () => _openUploadStorySheet(context, currentUserId),
                  child: const Text(
                    '+ Cerita Baru',
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
          const Gap(10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                padding: EdgeInsets.all(
                                  (myHasStory && myHasUnseen) ? 2.5 : 0,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: (myHasStory && myHasUnseen)
                                      ? AppColors.storyGradient
                                      : null,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    (myHasStory && myHasUnseen) ? 2 : 0,
                                  ),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.warmIvory,
                                  ),
                                  child: CircleAvatar(
                                    radius: 27,
                                    backgroundColor: AppColors.pureWhite,
                                    backgroundImage: avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl.isEmpty
                                        ? Text(
                                            currentUser?.username.isNotEmpty ==
                                                    true
                                                ? currentUser!.username[0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                              color: AppColors.deepForest,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _openUploadStorySheet(
                                    context,
                                    currentUserId,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.deepForest,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.warmIvory,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 13,
                                      color: AppColors.pureWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          const Text(
                            'Cerita Anda',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryText,
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
                          padding: EdgeInsets.all(showBorder ? 2.5 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                showBorder ? AppColors.storyGradient : null,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(showBorder ? 2 : 0),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warmIvory,
                            ),
                            child: CircleAvatar(
                              radius: 27,
                              backgroundColor: AppColors.pureWhite,
                              backgroundImage: groupAvatarUrl.isNotEmpty
                                  ? NetworkImage(groupAvatarUrl)
                                  : null,
                              child: groupAvatarUrl.isEmpty
                                  ? Text(
                                      group.username.isNotEmpty
                                          ? group.username[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        color: AppColors.deepForest,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const Gap(6),
                        SizedBox(
                          width: 68,
                          child: Text(
                            group.username,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: showBorder
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: showBorder
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
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
          ),
        ],
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
  String? _errorText;

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
      setState(() {
        _errorText = 'Ukuran foto maksimal 5MB.';
      });
      return;
    }

    setState(() {
      _selectedFile = picked;
      _imageBytes = bytes;
      _errorText = null;
    });
  }

  Future<void> _uploadStory() async {
    if (_selectedFile == null || _imageBytes == null) {
      setState(() {
        _errorText = 'Pilih foto terlebih dahulu untuk dibagikan ke cerita.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorText = null;
    });

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
          content: Text('Cerita berhasil diterbitkan (berlaku 24 jam).'),
        ),
      );
    } else {
      setState(() {
        _errorText = homeVm.errorMessage ?? 'Gagal mengunggah cerita.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cerita Baru',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Gap(2),
                      Text(
                        'Tayang selama 24 jam di beranda pengikut Anda',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_errorText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const Gap(12),
              ],
              if (_imageBytes != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        width: double.infinity,
                        color: const Color(0xFF181B18),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        child: InkWell(
                          onTap: () => _pickImage(ImageSource.gallery),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              'Ganti Foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.warmIvory,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 38,
                        color: AppColors.sageGreen,
                      ),
                      const Gap(10),
                      const Text(
                        'Pilih foto untuk dibagikan ke Cerita',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const Gap(14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 17,
                            ),
                            label: const Text('Galeri'),
                          ),
                          const Gap(10),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
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
              const Gap(14),
              TextField(
                controller: _captionController,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Tambahkan keterangan singkat (opsional)...',
                ),
              ),
              const Gap(16),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadStory,
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                color: AppColors.pureWhite,
                                strokeWidth: 2,
                              ),
                            ),
                            Gap(10),
                            Text('Mengunggah cerita...'),
                          ],
                        )
                      : const Text('Terbitkan Cerita'),
                ),
              ),
              const Gap(18),
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
    final safeIdx = _currentIndex < widget.group.stories.length
        ? _currentIndex
        : widget.group.stories.length - 1;
    final currentStory = widget.group.stories[safeIdx];
    context.read<HomeViewModel>().markStoryViewed(
          viewerId: widget.viewerId,
          storyId: currentStory.id,
          targetUserId: widget.group.userId,
        );
  }

  void _nextStory(int totalCount) {
    if (_currentIndex < totalCount - 1) {
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

  Future<void> _confirmDeleteStory(StoryItemModel story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Cerita Ini?',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Cerita ini akan dihapus secara permanen sebelum masa tayang 24 jam berakhir.',
          style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final homeVm = context.read<HomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final deleted = await homeVm.deleteStory(
      storyId: story.id,
      userId: widget.viewerId,
    );

    if (!mounted) return;
    if (deleted) {
      final updatedGroup = homeVm.getStoryGroupForUser(widget.group.userId);
      if (updatedGroup == null || updatedGroup.stories.isEmpty) {
        navigator.pop();
      } else if (_currentIndex >= updatedGroup.stories.length) {
        setState(() {
          _currentIndex = updatedGroup.stories.length - 1;
        });
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Cerita berhasil dihapus.')),
      );
    }
  }

  void _showViewersSheet(StoryItemModel story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        final viewers = story.viewers;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 19,
                      color: AppColors.deepForest,
                    ),
                    const Gap(8),
                    Text(
                      'Riwayat Penonton (${viewers.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
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
                    'Belum ada pengguna lain yang melihat cerita ini.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: viewers.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 68,
                    ),
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
                          backgroundColor: AppColors.warmIvory,
                          backgroundImage: vAvatar.isNotEmpty
                              ? NetworkImage(vAvatar)
                              : null,
                          child: vAvatar.isEmpty
                              ? Text(
                                  v.username.isNotEmpty
                                      ? v.username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepForest,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          v.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: AppColors.primaryText,
                          ),
                        ),
                        subtitle: v.name.isNotEmpty
                            ? Text(
                                v.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              )
                            : null,
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

  String _formatStoryTimestamp(String dateStr) {
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return '';
      final diff = DateTime.now().difference(parsed);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      return '${parsed.day}/${parsed.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestGroup = context
            .watch<HomeViewModel>()
            .getStoryGroupForUser(widget.group.userId) ??
        widget.group;
    final stories = latestGroup.stories.isNotEmpty
        ? latestGroup.stories
        : widget.group.stories;

    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIndex =
        _currentIndex < stories.length ? _currentIndex : stories.length - 1;
    final story = stories[safeIndex];

    final storyImageUrl = ApiConstants.getImageUrl(story.image);
    final authorAvatarUrl = ApiConstants.getImageUrl(latestGroup.avatar);
    final timestampText = _formatStoryTimestamp(story.createDate);

    return Scaffold(
      backgroundColor: const Color(0xFF161916),
      body: SafeArea(
        child: Stack(
          children: [
            // Fullscreen Story Image with Tap Left/Right Navigation
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < screenWidth * 0.35) {
                    _prevStory();
                  } else {
                    _nextStory(stories.length);
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
                            size: 56,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          color: Colors.white54,
                          size: 56,
                        ),
                ),
              ),
            ),

            // Top Progress Indicator + Author Header + Actions
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: List.generate(stories.length, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: i <= safeIndex
                                ? AppColors.softBeige
                                : Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Gap(14),
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
                              radius: 17,
                              backgroundColor: AppColors.warmIvory,
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
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepForest,
                                      ),
                                    )
                                  : null,
                            ),
                            const Gap(10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latestGroup.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (timestampText.isNotEmpty)
                                  Text(
                                    timestampText,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (widget.onAddNewStory != null)
                        IconButton(
                          onPressed: widget.onAddNewStory,
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Tambah Cerita',
                        ),
                      if (latestGroup.isOwn)
                        IconButton(
                          onPressed: () => _confirmDeleteStory(story),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFF29B9B),
                            size: 22,
                          ),
                          tooltip: 'Hapus Cerita Ini',
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Caption & Viewers History
            Positioned(
              bottom: 22,
              left: 18,
              right: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (story.caption.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        story.caption,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (latestGroup.isOwn) ...[
                    const Gap(14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => _showViewersSheet(story),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: Colors.white,
                                size: 17,
                              ),
                              const Gap(6),
                              Text(
                                '${story.viewers.length} Penonton',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
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
