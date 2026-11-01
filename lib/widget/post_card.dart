import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/view/profile_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/widget/comments_bottom_sheet.dart';
import 'package:ziesocial/widget/edit_post_dialog.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onPostUpdated;

  const PostCard({
    super.key,
    required this.post,
    this.onPostDeleted,
    this.onPostUpdated,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _showHeartAnimation = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartAnimController);

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _triggerDoubleTapLike() {
    final currentUser = context.read<LoginViewModel>().user;
    if (currentUser == null) return;

    final currentUserId = int.tryParse(currentUser.id) ?? 0;
    if (!widget.post.isLiked) {
      context.read<HomeViewModel>().toggleLike(widget.post.id, currentUserId);
    }

    setState(() => _showHeartAnimation = true);
    _heartAnimController.forward(from: 0.0);
  }

  void _toggleLike() {
    final currentUser = context.read<LoginViewModel>().user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      return;
    }
    final currentUserId = int.tryParse(currentUser.id) ?? 0;
    context.read<HomeViewModel>().toggleLike(widget.post.id, currentUserId);
  }

  void _openComments() {
    CommentsBottomSheet.show(
      context,
      post: widget.post,
      onCommentCountChanged: (newCount) {
        context.read<HomeViewModel>().updateCommentCount(widget.post.id, newCount);
      },
    );
  }

  void _openAuthorProfile() {
    final authorId = widget.post.author?.id;
    if (authorId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          userId: authorId,
          username: widget.post.author?.username,
        ),
      ),
    );
  }

  void _showPostOptions() {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final isAuthor = widget.post.author?.id == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
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
              if (isAuthor) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                  title: const Text('Edit Postingan', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Hapus Postingan',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeletePost();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppColors.textPrimary),
                  title: const Text('Lihat Profil', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAuthorProfile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link, color: AppColors.textPrimary),
                  title: const Text('Salin Tautan', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tautan postingan disalin.')),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog() {
    final currentUser = context.read<LoginViewModel>().user;
    if (currentUser == null) return;
    final currentUserId = int.tryParse(currentUser.id) ?? 0;
    final homeVm = context.read<HomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => EditPostDialog(
        initialCaption: widget.post.caption,
        onSave: (newCaption) async {
          final success = await homeVm.updatePost(
            postId: widget.post.id,
            userId: currentUserId,
            caption: newCaption,
          );
          if (success && mounted) {
            widget.onPostUpdated?.call();
            messenger.showSnackBar(
              const SnackBar(content: Text('Postingan berhasil diperbarui.')),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Hapus Postingan?'),
        content: const Text('Apakah Anda yakin ingin menghapus postingan ini secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final currentUser = context.read<LoginViewModel>().user;
      if (currentUser == null) return;
      final currentUserId = int.tryParse(currentUser.id) ?? 0;

      final success = await context.read<HomeViewModel>().deletePost(
            postId: widget.post.id,
            userId: currentUserId,
          );

      if (success && mounted) {
        widget.onPostDeleted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil dihapus.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.post.author;
    final avatarUrl = ApiConstants.getImageUrl(author?.avatar);
    final postImageUrl = ApiConstants.getImageUrl(widget.post.image);

    return Container(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header: Avatar, Username, More Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openAuthorProfile,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.storyGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surface,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                (author?.username.isNotEmpty ?? false)
                                    ? author!.username[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: GestureDetector(
                    onTap: _openAuthorProfile,
                    child: Text(
                      author?.username.isNotEmpty ?? false ? author!.username : 'pengguna',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showPostOptions,
                  icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Opsi Postingan',
                ),
              ],
            ),
          ),

          // 2. Post Image with Double-Tap Like
          GestureDetector(
            onDoubleTap: _triggerDoubleTapLike,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (postImageUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      postImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surface,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textSecondary),
                              Gap(8),
                              Text(
                                'Gambar tidak dapat dimuat',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: const Text('Tidak ada gambar', style: TextStyle(color: AppColors.textSecondary)),
                  ),

                // Popping Heart Animation on double tap
                if (_showHeartAnimation)
                  ScaleTransition(
                    scale: _heartScaleAnim,
                    child: const Icon(
                      Icons.favorite,
                      size: 96,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 20),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 3. Action Icons Bar (Like, Comment, Share, Bookmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: widget.post.isLiked
                        ? const Icon(
                            Icons.favorite,
                            key: ValueKey('liked'),
                            size: 26,
                            color: AppColors.likeRed,
                          )
                        : const Icon(
                            Icons.favorite_border,
                            key: ValueKey('unliked'),
                            size: 26,
                            color: AppColors.textPrimary,
                          ),
                  ),
                ),
                const Gap(16),
                GestureDetector(
                  onTap: _openComments,
                  child: const Icon(
                    CupertinoIcons.chat_bubble,
                    size: 25,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(16),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bagikan postingan...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    CupertinoIcons.paperplane,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Disimpan ke koleksi.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.bookmark_border,
                    size: 26,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 4. Like Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              widget.post.likeCount == 1 ? '1 suka' : '${widget.post.likeCount} suka',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // 5. Caption
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${author?.username ?? "pengguna"} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                    TextSpan(
                      text: widget.post.caption,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 6. Comments Link
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: GestureDetector(
              onTap: _openComments,
              child: Text(
                widget.post.commentCount > 0
                    ? 'Lihat semua ${widget.post.commentCount} komentar'
                    : 'Tambahkan komentar...',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // 7. Time Ago
          if (widget.post.createDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Text(
                _formatTimeAgo(widget.post.createDate),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String dateStr) {
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;
      final diff = DateTime.now().difference(parsed);

      if (diff.inSeconds < 60) return 'BARU SAJA';
      if (diff.inMinutes < 60) return '${diff.inMinutes} MENIT YANG LALU';
      if (diff.inHours < 24) return '${diff.inHours} JAM YANG LALU';
      if (diff.inDays < 7) return '${diff.inDays} HARI YANG LALU';
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
