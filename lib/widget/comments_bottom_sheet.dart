import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/comment_model.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/viewmodel/comments_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';

class CommentsBottomSheet extends StatefulWidget {
  final PostModel post;
  final Function(int newCount) onCommentCountChanged;

  const CommentsBottomSheet({
    super.key,
    required this.post,
    required this.onCommentCountChanged,
  });

  static void show(
    BuildContext context, {
    required PostModel post,
    required Function(int newCount) onCommentCountChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        post: post,
        onCommentCountChanged: onCommentCountChanged,
      ),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentsViewModel>().fetchComments(widget.post.id);
    });

    _commentController.addListener(() {
      final canSubmit = _commentController.text.trim().isNotEmpty;
      if (canSubmit != _canSubmit) {
        setState(() => _canSubmit = canSubmit);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = context.read<LoginViewModel>().user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masuk terlebih dahulu.')),
      );
      return;
    }

    _commentController.clear();
    FocusScope.of(context).unfocus();

    final newCount = await context.read<CommentsViewModel>().addComment(
          postId: widget.post.id,
          userId: int.parse(currentUser.id),
          text: text,
        );

    if (newCount != null) {
      widget.onCommentCountChanged(newCount);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _confirmDeleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Komentar?',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus komentar ini?',
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

      final updatedCount = await context.read<CommentsViewModel>().deleteComment(
            commentId: comment.id,
            userId: int.parse(currentUser.id),
            postId: widget.post.id,
          );

      if (updatedCount != null) {
        widget.onCommentCountChanged(updatedCount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Komentar dihapus.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsVm = context.watch<CommentsViewModel>();
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final postAuthorId = widget.post.author?.id ?? 0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.76,
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 3.5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diskusi & Komentar (${commentsVm.comments.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.secondaryText,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          Expanded(
            child: commentsVm.isLoading && commentsVm.comments.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sageGreen,
                      strokeWidth: 2,
                    ),
                  )
                : commentsVm.comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.warmIvory,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 22,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const Gap(12),
                            const Text(
                              'Belum ada tanggapan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const Gap(4),
                            const Text(
                              'Jadilah yang pertama menulis komentar pada postingan ini.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        itemCount: commentsVm.comments.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 22,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final comment = commentsVm.comments[index];
                          final isMyComment = comment.userId == currentUserId;
                          final isMyPost = postAuthorId == currentUserId;
                          final canDelete = isMyComment || isMyPost;

                          final avatarUrl =
                              ApiConstants.getImageUrl(comment.avatar);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: AppColors.warmIvory,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl.isEmpty
                                    ? Text(
                                        comment.username.isNotEmpty
                                            ? comment.username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
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
                                    Row(
                                      children: [
                                        Text(
                                          comment.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Gap(8),
                                        if (comment.createDate.isNotEmpty)
                                          Text(
                                            comment.createDate.split(' ')[0],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const Gap(4),
                                    Text(
                                      comment.text,
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 13.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (canDelete)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteComment(comment),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Hapus Komentar',
                                ),
                            ],
                          );
                        },
                      ),
          ),

          const Divider(height: 1),

          // Bottom Input Field
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
            color: AppColors.pureWhite,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.warmIvory,
                    backgroundImage: currentUser?.avatar != null &&
                            currentUser!.avatar.isNotEmpty
                        ? NetworkImage(
                            ApiConstants.getImageUrl(currentUser.avatar),
                          )
                        : null,
                    child: currentUser?.avatar == null ||
                            currentUser!.avatar.isEmpty
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
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Tulis tanggapan Anda...',
                        filled: true,
                        fillColor: AppColors.warmIvory,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.sageGreen),
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _canSubmit && !commentsVm.isSubmitting
                          ? _submitComment
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepForest,
                        foregroundColor: AppColors.pureWhite,
                        disabledBackgroundColor: AppColors.mistGray,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: commentsVm.isSubmitting
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pureWhite,
                              ),
                            )
                          : const Text(
                              'Kirim',
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
        ],
      ),
    );
  }
}
