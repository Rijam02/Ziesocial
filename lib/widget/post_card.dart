import 'dart:ui';
import 'package:flutter/gestures.dart';
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
              foregroundColor: AppColors.pureWhite,
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
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Editorial Header: Author Identity + Timestamp + Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openAuthorProfile,
                  child: Container(
                    padding: EdgeInsets.all(hasUnseenStory ? 2.2 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasUnseenStory ? AppColors.storyGradient : null,
                      border: hasUnseenStory
                          ? null
                          : Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(hasUnseenStory ? 1.5 : 0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pureWhite,
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.warmIvory,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                displayUsername[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepForest,
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
                          displayFullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.primaryText,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(1),
                        Row(
                          children: [
                            Text(
                              '@$displayUsername',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            if (widget.post.createDate.isNotEmpty) ...[
                              const Text(
                                '  •  ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(widget.post.createDate),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showPostOptions,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: 'Opsi Postingan',
                ),
              ],
            ),
          ),
          const Gap(12),

          // 2. Framed Editorial Photograph (Mendukung Pinch-to-Zoom keluar kotak postingan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _ZoomablePostImage(
              imageUrl: postImageUrl,
              onDoubleTap: _triggerDoubleTapLike,
              overlayBadge: _showHeartAnimation
                  ? ScaleTransition(
                      scale: _heartScaleAnim,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          // 3. Editorial Caption
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Text(
                widget.post.caption,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14,
                  height: 1.48,
                  letterSpacing: -0.1,
                ),
              ),
            ),

          const Gap(12),

          // 4. Minimalist Editorial Interaction Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                // Like Pill Button
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.post.isLiked
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.warmIvory,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.post.isLiked
                            ? AppColors.error.withValues(alpha: 0.3)
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.post.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                          color: widget.post.isLiked
                              ? AppColors.error
                              : AppColors.primaryText,
                        ),
                        const Gap(6),
                        Text(
                          '${widget.post.likeCount}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: widget.post.isLiked
                                ? AppColors.error
                                : AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(8),

                // Comment Pill Button
                InkWell(
                  onTap: _openComments,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmIvory,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppColors.primaryText,
                        ),
                        const Gap(6),
                        Text(
                          widget.post.commentCount > 0
                              ? '${widget.post.commentCount} Komentar'
                              : 'Komentar',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Subtle Discussion Link
                if (widget.post.commentCount > 0)
                  GestureDetector(
                    onTap: _openComments,
                    child: const Text(
                      'Lihat diskusi →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sageGreen,
                      ),
                    ),
                  ),
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
          decoration: BoxDecoration(
            color: AppColors.warmIvory,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
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
                      minHeight: 220,
                      maxHeight: 460,
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

