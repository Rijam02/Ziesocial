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
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
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
      // Scroll to bottom
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
        backgroundColor: AppColors.background,
        title: const Text('Hapus Komentar?'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
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
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text(
                  'Komentar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
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
                ? const Center(child: CircularProgressIndicator())
                : commentsVm.comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.chat_bubble_outline,
                                size: 48, color: AppColors.textSecondary),
                            Gap(12),
                            Text(
                              'Belum ada komentar.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Gap(4),
                            Text(
                              'Mulai percakapan.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: commentsVm.comments.length,
                        itemBuilder: (context, index) {
                          final comment = commentsVm.comments[index];
                          final isMyComment = comment.userId == currentUserId;
                          final isMyPost = postAuthorId == currentUserId;
                          final canDelete = isMyComment || isMyPost;

                          final avatarUrl =
                              ApiConstants.getImageUrl(comment.avatar);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? Text(
                                          comment.username.isNotEmpty
                                              ? comment.username[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        )
                                      : null,
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '${comment.username} ',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            TextSpan(
                                              text: comment.text,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        comment.createDate.isNotEmpty
                                            ? comment.createDate.split(' ')[0]
                                            : '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (canDelete)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () =>
                                        _confirmDeleteComment(comment),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Hapus Komentar',
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          const Divider(height: 1),

          // Bottom Input Field
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
            color: AppColors.background,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surface,
                  backgroundImage: currentUser?.avatar != null &&
                          currentUser!.avatar.isNotEmpty
                      ? NetworkImage(
                          ApiConstants.getImageUrl(currentUser.avatar))
                      : null,
                  child: currentUser?.avatar == null ||
                          currentUser!.avatar.isEmpty
                      ? Text(
                          currentUser?.username.isNotEmpty == true
                              ? currentUser!.username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : null,
                ),
                const Gap(12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan komentar...',
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                TextButton(
                  onPressed: _canSubmit && !commentsVm.isSubmitting
                      ? _submitComment
                      : null,
                  child: commentsVm.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Kirim',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _canSubmit
                                ? AppColors.primary
                                : AppColors.buttonDisabled,
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
}
