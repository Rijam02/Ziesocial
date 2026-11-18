import 'dart:convert';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/view/messages_view.dart';
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

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
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
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
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
        const SnackBar(content: Text('Silakan masuk terlebih dahulu.')),
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
        context
            .read<HomeViewModel>()
            .updateCommentCount(widget.post.id, newCount);
      },
    );
  }

  void _openShareToFriendsSheet() {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk terlebih dahulu.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SharePostToFriendsBottomSheet(
        post: widget.post,
        currentUserId: currentUserId,
        parentContext: context,
      ),
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
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 10),
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (isAuthor) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    title: const Text(
                      'Edit Keterangan Postingan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditDialog();
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Hapus Postingan',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeletePost();
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    title: const Text(
                      'Kunjungi Profil Kreator',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openAuthorProfile();
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                    title: const Text(
                      'Lihat Diskusi & Komentar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openComments();
                    },
                  ),
                ],
              ],
            ),
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
        title: const Text(
          'Hapus Postingan?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Postingan ini akan dihapus secara permanen dari profil dan beranda ZieSocial.',
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
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
    final authorId = author?.id ?? 0;
    final hasUnseenStory =
        context.watch<HomeViewModel>().hasUnseenStoryForUser(authorId);
    final displayUsername =
        (author?.username.isNotEmpty ?? false) ? author!.username : 'pengguna';
    final displayFullName =
        (author?.name.isNotEmpty ?? false) ? author!.name : displayUsername;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.surfaceContainer,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Postingan (px-4 py-3.5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openAuthorProfile,
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          hasUnseenStory ? AppColors.storyGradient : null,
                      color: hasUnseenStory
                          ? null
                          : AppColors.surfaceContainerHighest,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainerLowest,
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.surfaceContainerLow,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                displayUsername[0].toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: GestureDetector(
                    onTap: _openAuthorProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayUsername,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.onSurface,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Text(
                          displayFullName != displayUsername
                              ? displayFullName
                              : 'ZieSocial Visual',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _showPostOptions,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Foto Postingan (aspect-[4/5] bg-surface-container + Pinch-to-Zoom keluar kotak)
          _ZoomablePostImage(
            imageUrl: postImageUrl,
            onDoubleTap: _triggerDoubleTapLike,
            overlayBadge: _showHeartAnimation
                ? ScaleTransition(
                    scale: _heartScaleAnim,
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 90,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppColors.secondaryContainer
                              .withValues(alpha: 0.8),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

          // 3. Footer Postingan (px-4 pt-3 pb-4)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Like Button + Count
                        GestureDetector(
                          onTap: _toggleLike,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.post.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 26,
                                color: widget.post.isLiked
                                    ? AppColors.secondaryContainer
                                    : AppColors.onSurface,
                              ),
                              const Gap(6),
                              Text(
                                '${widget.post.likeCount}',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),

                        // Comment Button
                        GestureDetector(
                          onTap: _openComments,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 24,
                                color: AppColors.onSurface,
                              ),
                              if (widget.post.commentCount > 0) ...[
                                const Gap(5),
                                Text(
                                  '${widget.post.commentCount}',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Gap(16),

                        // Send / Share Button
                        GestureDetector(
                          onTap: _openShareToFriendsSheet,
                          behavior: HitTestBehavior.opaque,
                          child: const Icon(
                            Icons.send_outlined,
                            size: 24,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),

                    if (widget.post.createDate.isNotEmpty)
                      Text(
                        _formatTimeAgo(widget.post.createDate),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                const Gap(10),

                // Disukai oleh X orang
                Text(
                  'Disukai oleh ${widget.post.likeCount} orang',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),

                // Username + Caption
                if (widget.post.caption.isNotEmpty) ...[
                  const Gap(4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        color: AppColors.onSurface,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: '$displayUsername  ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: widget.post.caption,
                        ),
                      ],
                    ),
                  ),
                ],

                // Lihat semua komentar
                if (widget.post.commentCount > 0) ...[
                  const Gap(8),
                  GestureDetector(
                    onTap: _openComments,
                    child: Text(
                      'Lihat semua ${widget.post.commentCount} komentar',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
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

      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      if (diff.inDays < 7) return '${diff.inDays}h lalu';
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// Widget Foto Postingan yang mendukung Pinch-to-Zoom keluar dari batas kotak postingan
/// (melayang di atas elemen layar lainnya melalui OverlayEntry) dan kembali mulus ke
/// posisi semula saat jari dilepaskan.
class _ZoomablePostImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onDoubleTap;
  final Widget? overlayBadge;

  const _ZoomablePostImage({
    required this.imageUrl,
    required this.onDoubleTap,
    this.overlayBadge,
  });

  @override
  State<_ZoomablePostImage> createState() => _ZoomablePostImageState();
}

class _ZoomablePostImageState extends State<_ZoomablePostImage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boxKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _resetController;

  bool _isZooming = false;
  Rect? _originRect;

  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;

  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  double _initialDistance = 1.0;
  Offset _referenceMidpoint = Offset.zero;
  Offset _focalVectorFromCenter = Offset.zero;

  double _animStartScale = 1.0;
  Offset _animStartOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )
      ..addListener(() {
        final t = Curves.easeOutCubic.transform(_resetController.value);
        _currentScale = lerpDouble(_animStartScale, 1.0, t) ?? 1.0;
        _currentOffset = Offset.lerp(_animStartOffset, Offset.zero, t) ?? Offset.zero;
        _overlayEntry?.markNeedsBuild();
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _removeOverlay();
        }
      });
  }

  @override
  void dispose() {
    _removeOverlay(notifyState: false);
    _resetController.dispose();
    super.dispose();
  }

  void _removeOverlay({bool notifyState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isZooming) {
      _isZooming = false;
      if (notifyState && mounted) {
        setState(() {});
      }
    }
  }

  void _handlePinchStart(Map<int, Offset> pointers) {
    if (widget.imageUrl.isEmpty || pointers.length < 2) return;

    if (_resetController.isAnimating) {
      _resetController.stop();
    }

    final renderObj = _boxKey.currentContext?.findRenderObject();
    if (renderObj is! RenderBox || !renderObj.hasSize) return;

    final topLeft = renderObj.localToGlobal(Offset.zero);
    _originRect = topLeft & renderObj.size;

    final pts = pointers.values.toList();
    final p1 = pts[0];
    final p2 = pts[1];

    _referenceMidpoint = (p1 + p2) / 2.0;
    final dist = (p1 - p2).distance;
    _initialDistance = dist < 10.0 ? 10.0 : dist;
    _focalVectorFromCenter = _referenceMidpoint - _originRect!.center;

    _baseScale = 1.0;
    _baseOffset = Offset.zero;
    _currentScale = 1.0;
    _currentOffset = Offset.zero;

    if (_overlayEntry == null) {
      _overlayEntry = _buildZoomOverlayEntry();
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    }

    setState(() {
      _isZooming = true;
    });
  }

  void _handlePinchUpdate(Map<int, Offset> pointers) {
    if (!_isZooming || _originRect == null || pointers.isEmpty) return;

    if (pointers.length >= 2) {
      final pts = pointers.values.toList();
      final p1 = pts[0];
      final p2 = pts[1];

      final midpoint = (p1 + p2) / 2.0;
      final dist = (p1 - p2).distance;
      final rawScale = _baseScale * (dist / _initialDistance);
      final newScale = rawScale.clamp(1.0, 4.5);

      final panDelta = midpoint - _referenceMidpoint;
      _currentOffset =
          _baseOffset + panDelta - (_focalVectorFromCenter * (newScale - _baseScale));
      _currentScale = newScale;
    } else if (pointers.length == 1) {
      final p1 = pointers.values.first;
      final panDelta = p1 - _referenceMidpoint;
      _currentOffset = _baseOffset + panDelta;
    }

    _overlayEntry?.markNeedsBuild();
  }

  void _handlePointerCountChanged(Map<int, Offset> pointers) {
    if (!_isZooming || _originRect == null || pointers.isEmpty) return;

    _baseScale = _currentScale;
    _baseOffset = _currentOffset;

    if (pointers.length >= 2) {
      final pts = pointers.values.toList();
      final p1 = pts[0];
      final p2 = pts[1];
      _referenceMidpoint = (p1 + p2) / 2.0;
      final dist = (p1 - p2).distance;
      _initialDistance = dist < 10.0 ? 10.0 : dist;
      final currentCenter = _originRect!.center + _currentOffset;
      _focalVectorFromCenter =
          (_referenceMidpoint - currentCenter) / (_currentScale == 0 ? 1.0 : _currentScale);
    } else if (pointers.length == 1) {
      _referenceMidpoint = pointers.values.first;
    }
  }

  void _handlePinchEnd() {
    if (!_isZooming) return;

    _animStartScale = _currentScale;
    _animStartOffset = _currentOffset;
    _resetController.forward(from: 0.0);
  }

  OverlayEntry _buildZoomOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final rect = _originRect;
        if (rect == null) return const SizedBox.shrink();

        final backdropOpacity =
            ((_currentScale - 1.0) / 2.8 * 0.58).clamp(0.0, 0.58);

        return IgnorePointer(
          ignoring: true,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Latar redup halus di belakang foto saat di-zoom keluar kotak
                ColoredBox(
                  color: Colors.black.withValues(alpha: backdropOpacity),
                ),
                Positioned.fromRect(
                  rect: rect,
                  child: Transform.translate(
                    offset: _currentOffset,
                    child: Transform.scale(
                      scale: _currentScale,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.warmIvory,
                          borderRadius: BorderRadius.circular(
                            _currentScale > 1.08 ? 2 : 8,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          widget.imageUrl,
                          width: rect.width,
                          height: rect.height,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _MultiTouchPinchRecognizer:
            GestureRecognizerFactoryWithHandlers<_MultiTouchPinchRecognizer>(
          () => _MultiTouchPinchRecognizer(),
          (_MultiTouchPinchRecognizer instance) {
            instance
              ..onPinchStart = _handlePinchStart
              ..onPinchUpdate = _handlePinchUpdate
              ..onPointerCountChanged = _handlePointerCountChanged
              ..onPinchEnd = _handlePinchEnd;
          },
        ),
      },
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          key: _boxKey,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.warmIvory,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.7),
              bottom: BorderSide(color: AppColors.border, width: 0.7),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.imageUrl.isNotEmpty)
                Opacity(
                  opacity: _isZooming ? 0.0 : 1.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 280,
                      maxHeight: 520,
                    ),
                    child: Image.network(
                      widget.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Container(
                            color: AppColors.warmIvory,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.sageGreen,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Container(
                            color: AppColors.warmIvory,
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 32,
                                  color: AppColors.secondaryText,
                                ),
                                Gap(6),
                                Text(
                                  'Gambar tidak tersedia',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  height: 220,
                  width: double.infinity,
                  color: AppColors.warmIvory,
                  alignment: Alignment.center,
                  child: const Text(
                    'Tanpa gambar',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),

              if (widget.overlayBadge != null) widget.overlayBadge!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom GestureRecognizer yang hanya mengambil alih GestureArena ketika >= 2 jari
/// menyentuh foto, sehingga scroll 1 jari dan double-tap tetap berjalan mulus.
class _MultiTouchPinchRecognizer extends OneSequenceGestureRecognizer {
  final Map<int, Offset> _pointers = {};
  bool _isPinching = false;

  void Function(Map<int, Offset> pointers)? onPinchStart;
  void Function(Map<int, Offset> pointers)? onPinchUpdate;
  void Function(Map<int, Offset> pointers)? onPointerCountChanged;
  VoidCallback? onPinchEnd;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    _pointers[event.pointer] = event.position;

    if (_pointers.length >= 2 && !_isPinching) {
      _isPinching = true;
      resolve(GestureDisposition.accepted);
      onPinchStart?.call(Map<int, Offset>.from(_pointers));
    } else if (_isPinching) {
      onPointerCountChanged?.call(Map<int, Offset>.from(_pointers));
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (_pointers.containsKey(event.pointer)) {
        _pointers[event.pointer] = event.position;
        if (_isPinching) {
          onPinchUpdate?.call(Map<int, Offset>.from(_pointers));
        }
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers.remove(event.pointer);
      stopTrackingPointer(event.pointer);

      if (_isPinching) {
        if (_pointers.isEmpty) {
          _isPinching = false;
          onPinchEnd?.call();
        } else {
          onPointerCountChanged?.call(Map<int, Offset>.from(_pointers));
        }
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointers.clear();
    if (_isPinching) {
      _isPinching = false;
      onPinchEnd?.call();
    }
  }

  @override
  String get debugDescription => 'multi_touch_pinch_zoom';
}

/// Bottom Sheet untuk mengirim/membagikan postingan ke teman yang mengikuti (followers/following)
/// langsung ke ruang chat masing-masing teman.
class _SharePostToFriendsBottomSheet extends StatefulWidget {
  final PostModel post;
  final int currentUserId;
  final BuildContext parentContext;

  const _SharePostToFriendsBottomSheet({
    required this.post,
    required this.currentUserId,
    required this.parentContext,
  });

  @override
  State<_SharePostToFriendsBottomSheet> createState() =>
      _SharePostToFriendsBottomSheetState();
}

class _SharePostToFriendsBottomSheetState
    extends State<_SharePostToFriendsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _friends = [];
  final Set<int> _sendingUserIds = {};
  final Set<int> _sentUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadFollowerFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowerFriends() async {
    setState(() => _isLoading = true);

    final Map<int, Map<String, dynamic>> combined = {};

    try {
      // 1. Ambil daftar teman yang mengikuti akun kita (followers)
      final followersUrl =
          '${ApiConstants.followList}?user_id=${widget.currentUserId}&viewer_id=${widget.currentUserId}&type=followers';
      final followersRes = await http.get(Uri.parse(followersUrl));
      if (followersRes.statusCode == 200) {
        final decoded = jsonDecode(followersRes.body);
        final List<dynamic> list = decoded['data'] ?? [];
        for (final item in list) {
          final uid = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
          if (uid > 0 && uid != widget.currentUserId) {
            final bool isMutual = item['is_following'] == true;
            combined[uid] = {
              'user_id': uid,
              'username': item['username']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'avatar': item['avatar']?.toString() ?? '',
              'bio': item['bio']?.toString() ?? '',
              'relation_label':
                  isMutual ? 'Saling Mengikuti' : 'Mengikuti Anda',
            };
          }
        }
      }

      // 2. Ambil juga daftar teman yang kita ikuti (following) jika belum masuk
      final followingUrl =
          '${ApiConstants.followList}?user_id=${widget.currentUserId}&viewer_id=${widget.currentUserId}&type=following';
      final followingRes = await http.get(Uri.parse(followingUrl));
      if (followingRes.statusCode == 200) {
        final decoded = jsonDecode(followingRes.body);
        final List<dynamic> list = decoded['data'] ?? [];
        for (final item in list) {
          final uid = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
          if (uid > 0 &&
              uid != widget.currentUserId &&
              !combined.containsKey(uid)) {
            combined[uid] = {
              'user_id': uid,
              'username': item['username']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'avatar': item['avatar']?.toString() ?? '',
              'bio': item['bio']?.toString() ?? '',
              'relation_label': 'Teman yang Diikuti',
            };
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _friends = combined.values.toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPostToFriend(Map<String, dynamic> friend) async {
    final targetUserId =
        int.tryParse(friend['user_id']?.toString() ?? '0') ?? 0;
    if (targetUserId <= 0 || _sendingUserIds.contains(targetUserId)) return;

    setState(() {
      _sendingUserIds.add(targetUserId);
    });

    final authorUsername = widget.post.author?.username ?? 'pengguna';
    final authorAvatar = widget.post.author?.avatar ?? '';
    final extraNote = _noteController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sendMessage),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': widget.currentUserId,
          'receiver_id': targetUserId,
          'message_text': '',
          'shared_image_path': widget.post.image,
          'shared_author_username': authorUsername,
          'shared_author_avatar': authorAvatar,
        }),
      );

      // Jika user juga mengetik pesan tambahan saat kirim postingan, kirim sebagai pesan teks terpisah tanpa emoji
      if (extraNote.isNotEmpty &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        await http.post(
          Uri.parse(ApiConstants.sendMessage),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_id': widget.currentUserId,
            'receiver_id': targetUserId,
            'message_text': extraNote,
          }),
        );
      }

      if (mounted) {
        setState(() {
          _sendingUserIds.remove(targetUserId);
          if (response.statusCode == 201 || response.statusCode == 200) {
            _sentUserIds.add(targetUserId);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sendingUserIds.remove(targetUserId);
        });
      }
    }
  }

  void _openFriendChat(Map<String, dynamic> friend) {
    Navigator.pop(context);
    Navigator.push(
      widget.parentContext,
      MaterialPageRoute(
        builder: (_) => ChatRoomView(partnerUser: friend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postImageUrl = ApiConstants.getImageUrl(widget.post.image);
    final authorUsername = widget.post.author?.username ?? 'pengguna';

    final filtered = _searchQuery.isEmpty
        ? _friends
        : _friends.where((f) {
            final q = _searchQuery.toLowerCase();
            final uname = (f['username']?.toString() ?? '').toLowerCase();
            final name = (f['name']?.toString() ?? '').toLowerCase();
            return uname.contains(q) || name.contains(q);
          }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kirim Postingan ke Teman',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Gap(2),
                          Text(
                            'Bagikan postingan ini ke ruang chat teman yang mengikuti Anda',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 14),

              // Pratinjau Postingan + Input Pesan Tambahan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warmIvory,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: postImageUrl.isNotEmpty
                            ? Image.network(
                                postImageUrl,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 46,
                                height: 46,
                                color: AppColors.mistGray,
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 20,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText:
                                'Tulis pesan untuk postingan @$authorUsername...',
                            hintStyle: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.secondaryText,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(10),

              // Kolom Pencarian Teman
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari teman yang mengikuti...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.secondaryText,
                      ),
                      filled: true,
                      fillColor: AppColors.warmIvory,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.sageGreen),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(10),

              // Daftar Teman yang Mengikuti
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sageGreen,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 32,
                          color: AppColors.secondaryText,
                        ),
                        const Gap(8),
                        Text(
                          _friends.isEmpty
                              ? 'Belum ada teman yang mengikuti akun Anda.'
                              : 'Teman tidak ditemukan.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final friend = filtered[index];
                      final uid = int.tryParse(
                            friend['user_id']?.toString() ?? '0',
                          ) ??
                          0;
                      final uname =
                          friend['username']?.toString() ?? 'pengguna';
                      final fullName = friend['name']?.toString() ?? '';
                      final relation =
                          friend['relation_label']?.toString() ?? 'Pengikut';
                      final fAvatar = ApiConstants.getImageUrl(
                        friend['avatar']?.toString(),
                      );

                      final isSending = _sendingUserIds.contains(uid);
                      final isSent = _sentUserIds.contains(uid);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 21,
                              backgroundColor: AppColors.warmIvory,
                              backgroundImage: fAvatar.isNotEmpty
                                  ? NetworkImage(fAvatar)
                                  : null,
                              child: fAvatar.isEmpty
                                  ? Text(
                                      uname.isNotEmpty
                                          ? uname[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepForest,
                                      ),
                                    )
                                  : null,
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName.isNotEmpty ? fullName : uname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  const Gap(2),
                                  Text(
                                    '@$uname • $relation',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(8),
                            if (isSent)
                              SizedBox(
                                height: 32,
                                child: OutlinedButton.icon(
                                  onPressed: () => _openFriendChat(friend),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.sageGreen,
                                    ),
                                    foregroundColor: AppColors.deepForest,
                                  ),
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: AppColors.sageGreen,
                                  ),
                                  label: const Text(
                                    'Buka Chat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: isSending
                                      ? null
                                      : () => _sendPostToFriend(friend),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.deepForest,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  child: isSending
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Kirim',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const Gap(12),
            ],
          ),
        ),
      ),
    );
  }
}


