import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/post_model.dart';
import 'package:ziesocial/view/profile_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';
import 'package:ziesocial/widget/post_card.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _poller;
  String _searchQuery = '';
  String _filterMode = 'all'; // 'all', 'notes', 'chatted'
  final Map<int, String> _seenLastMessageSignatures = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotesAndUsers(silent: false);
    });

    _poller = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadNotesAndUsers(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotesAndUsers({bool silent = false}) async {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    await context
        .read<ProfileViewModel>()
        .fetchNotesAndUsers(currentUserId, silent: silent);
  }

  List<Map<String, dynamic>> _buildCombinedUsersList(
    List<Map<String, dynamic>> apiNoteUsers,
    HomeViewModel homeVm,
    int currentUserId,
  ) {
    final Map<int, Map<String, dynamic>> merged = {};

    // 1. Dari endpoint notes/read.php (seluruh user di database)
    for (final item in apiNoteUsers) {
      final uid = int.tryParse(item['user_id']?.toString() ?? '0') ?? 0;
      if (uid > 0 && uid != currentUserId) {
        merged[uid] = Map<String, dynamic>.from(item);
      }
    }

    // 2. Fallback tambahan dari daftar story dan postingan jika ada user yang belum terambil
    for (final group in homeVm.storyGroups) {
      if (group.userId > 0 &&
          group.userId != currentUserId &&
          !merged.containsKey(group.userId)) {
        merged[group.userId] = {
          'user_id': group.userId,
          'username': group.username,
          'name': group.name,
          'avatar': group.avatar,
          'bio': '',
          'note_text': '',
        };
      }
    }

    for (final post in homeVm.posts) {
      final author = post.author;
      if (author != null &&
          author.id > 0 &&
          author.id != currentUserId &&
          !merged.containsKey(author.id)) {
        merged[author.id] = {
          'user_id': author.id,
          'username': author.username,
          'name': author.name,
          'avatar': author.avatar ?? '',
          'bio': '',
          'note_text': '',
        };
      }
    }

    return merged.values.toList();
  }

  void _openCreateNoteSheet({
    required int currentUserId,
    required String currentNote,
    required String avatarUrl,
    required String username,
  }) {
    if (currentUserId <= 0) return;

    final controller = TextEditingController(text: currentNote);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catatan Anda',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                Gap(2),
                                Text(
                                  'Bagikan Catatan anda untuk orang lain',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetCtx),
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
                      const Divider(height: 22),

                      // Preview Avatar + Bubble Note
                      Center(
                        child: Column(
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warmIvory,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.softBeige,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                controller.text.trim().isEmpty
                                    ? 'Tulis catatan singkat...'
                                    : controller.text.trim(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: controller.text.trim().isEmpty
                                      ? AppColors.secondaryText
                                      : AppColors.primaryText,
                                ),
                              ),
                            ),
                            const Gap(4),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.warmIvory,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.softBeige),
                              ),
                            ),
                            const Gap(4),
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.warmIvory,
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      username.isNotEmpty
                                          ? username[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepForest,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const Gap(18),

                      TextField(
                        controller: controller,
                        maxLength: 60,
                        autofocus: true,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: const InputDecoration(
                          hintText:
                              'Apa yang sedang Anda pikirkan? (maks. 60)',
                          prefixIcon: Icon(
                            Icons.edit_note_rounded,
                            size: 20,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          if (currentNote.isNotEmpty) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setSheetState(() => isSaving = true);
                                        final profileVm =
                                            context.read<ProfileViewModel>();
                                        final messenger =
                                            ScaffoldMessenger.of(this.context);
                                        await profileVm.saveUserNote(
                                          userId: currentUserId,
                                          noteText: '',
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(sheetCtx);
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Catatan dihapus.'),
                                          ),
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                ),
                                child: const Text('Hapus Catatan'),
                              ),
                            ),
                            const Gap(10),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final text = controller.text.trim();
                                      if (text.isEmpty) return;
                                      setSheetState(() => isSaving = true);
                                      final profileVm =
                                          context.read<ProfileViewModel>();
                                      final messenger =
                                          ScaffoldMessenger.of(this.context);
                                      final ok = await profileVm.saveUserNote(
                                        userId: currentUserId,
                                        noteText: text,
                                      );
                                      if (!mounted) return;
                                      Navigator.pop(sheetCtx);
                                      if (ok) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Catatan berhasil dibagikan!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Bagikan Catatan'),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openUserNoteDetailSheet(Map<String, dynamic> user) {
    final String uname = user['username']?.toString().trim() ?? 'pengguna';
    final String fullName = user['name']?.toString().trim() ?? '';
    final String displayName = fullName.isNotEmpty ? fullName : uname;
    final String avatarUrl = ApiConstants.getImageUrl(
      user['avatar']?.toString(),
    );
    final String noteText = user['note_text']?.toString().trim() ?? '';
    final int minutesAgo =
        int.tryParse(user['minutes_ago']?.toString() ?? '0') ?? 0;

    String timeSubtitle = 'Catatan aktif 24 jam';
    if (minutesAgo > 0) {
      if (minutesAgo < 60) {
        timeSubtitle = '$minutesAgo menit lalu';
      } else {
        final hours = (minutesAgo / 60).floor();
        timeSubtitle = '$hours jam lalu';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Gap(14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Catatan @$uname',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),
                const Gap(6),

                // Seluruh Teks Note User (Tanpa Terpotong)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      bottom: -6,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: 14,
                          height: 14,
                          color: AppColors.surfaceContainerLow,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        maxWidth: 320,
                        minHeight: 68,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        noteText.isNotEmpty
                            ? noteText
                            : 'Belum ada catatan aktif yang ditulis @$uname.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: noteText.isNotEmpty ? 15.5 : 13.5,
                          height: 1.45,
                          fontWeight: noteText.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: noteText.isNotEmpty
                              ? AppColors.onSurface
                              : AppColors.outline,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(14),

                // Avatar & Identitas Penulis Note
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              uname.isNotEmpty ? uname[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            uname.isNotEmpty ? uname[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
                const Gap(10),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const Gap(2),
                Text(
                  noteText.isNotEmpty
                      ? '@$uname • $timeSubtitle'
                      : '@$uname',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildMessageSignature(Map<String, dynamic> user) {
    final sender = user['last_message_sender_id']?.toString() ?? '';
    final date = user['last_message_date']?.toString() ?? '';
    final text = user['last_message_text']?.toString() ?? '';
    final image = user['last_message_image']?.toString() ?? '';
    return '$sender|$date|$text|$image';
  }

  Future<void> _openChatRoom(Map<String, dynamic> targetUser) async {
    final partnerId = int.tryParse(targetUser['user_id']?.toString() ?? '0') ?? 0;
    if (partnerId > 0) {
      setState(() {
        _seenLastMessageSignatures[partnerId] =
            _buildMessageSignature(targetUser);
      });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomView(partnerUser: targetUser),
      ),
    );
    if (mounted) {
      await _loadNotesAndUsers(silent: true);
      if (partnerId > 0 && mounted) {
        final refreshed = context.read<ProfileViewModel>().noteUsers.where(
              (u) =>
                  (int.tryParse(u['user_id']?.toString() ?? '0') ?? 0) ==
                  partnerId,
            );
        if (refreshed.isNotEmpty) {
          setState(() {
            _seenLastMessageSignatures[partnerId] =
                _buildMessageSignature(refreshed.first);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final profileVm = context.watch<ProfileViewModel>();
    final homeVm = context.watch<HomeViewModel>();

    final ownProfile = profileVm.getProfile(currentUserId);
    final myAvatarUrl = ApiConstants.getImageUrl(
      profileVm.myNoteData?['avatar']?.toString() ??
          ownProfile?.user.avatar ??
          currentUser?.avatar,
    );
    final myUsername = currentUser?.username ?? 'Anda';
    final myNoteText =
        profileVm.myNoteData?['note_text']?.toString().trim() ?? '';

    final allOtherUsers = _buildCombinedUsersList(
      profileVm.noteUsers,
      homeVm,
      currentUserId,
    );

    final filteredChatUsers = allOtherUsers.where((u) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final uname = (u['username']?.toString() ?? '').toLowerCase();
        final name = (u['name']?.toString() ?? '').toLowerCase();
        if (!uname.contains(q) && !name.contains(q)) {
          return false;
        }
      }

      if (_filterMode == 'notes') {
        final note = u['note_text']?.toString().trim() ?? '';
        return note.isNotEmpty;
      } else if (_filterMode == 'chatted') {
        final lastText = u['last_message_text']?.toString().trim() ?? '';
        final lastImg = u['last_message_image']?.toString().trim() ?? '';
        return lastText.isNotEmpty || lastImg.isNotEmpty;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.80),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        '@$myUsername',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          height: 28 / 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerLowest,
        onRefresh: () => _loadNotesAndUsers(silent: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Pill Search Bar with Filter Action
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Cari atau mulai percakapan baru...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        color: AppColors.outline,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 42,
                        minHeight: 40,
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.outline,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          PopupMenuButton<String>(
                            tooltip: 'Saring percakapan',
                            initialValue: _filterMode,
                            onSelected: (value) {
                              setState(() {
                                _filterMode = value;
                              });
                            },
                            color: AppColors.surfaceContainerLowest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: _filterMode == 'all'
                                  ? AppColors.outline
                                  : AppColors.primary,
                            ),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'all',
                                child: Text(
                                  'Semua Percakapan',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'notes',
                                child: Text(
                                  'Punya Catatan Aktif',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'chatted',
                                child: Text(
                                  'Sudah Pernah Chat',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                        ],
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Catatan Pengguna (Horizontal Notes Carousel)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: Text(
                        'Catatan Pengguna',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          height: 24 / 16,
                          letterSpacing: -0.16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 192,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allOtherUsers.length + 1,
                        separatorBuilder: (_, _) => const Gap(16),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildNoteItem(
                              avatarUrl: myAvatarUrl,
                              label: 'Catatan Anda',
                              fallbackLetter: myUsername.isNotEmpty
                                  ? myUsername[0].toUpperCase()
                                  : 'U',
                              noteText: myNoteText.isNotEmpty
                                  ? myNoteText
                                  : 'Catatan...',
                              isPlaceholderNote: myNoteText.isEmpty,
                              isOwn: true,
                              onTap: () => _openCreateNoteSheet(
                                currentUserId: currentUserId,
                                currentNote: myNoteText,
                                avatarUrl: myAvatarUrl,
                                username: myUsername,
                              ),
                            );
                          }

                          final user = allOtherUsers[index - 1];
                          final uAvatar = ApiConstants.getImageUrl(
                            user['avatar']?.toString(),
                          );
                          final uname =
                              user['username']?.toString() ?? 'pengguna';
                          final note =
                              user['note_text']?.toString().trim() ?? '';

                          return _buildNoteItem(
                            avatarUrl: uAvatar,
                            label: uname,
                            fallbackLetter: uname.isNotEmpty
                                ? uname[0].toUpperCase()
                                : 'U',
                            noteText: note,
                            isPlaceholderNote: note.isEmpty,
                            isOwn: false,
                            onTap: () => _openUserNoteDetailSheet(user),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Header Daftar Pesan
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Pesan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    height: 24 / 16,
                    letterSpacing: -0.16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),

            // 4. Daftar Percakapan Vertikal (Tanpa Garis Pembatas & Tanpa Ikon Chat)
            if (profileVm.isLoadingNotes && filteredChatUsers.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (filteredChatUsers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 22,
                            color: AppColors.outline,
                          ),
                        ),
                        const Gap(12),
                        const Text(
                          'Belum ada pengguna ditemukan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = filteredChatUsers[index];
                    final partnerId =
                        int.tryParse(user['user_id']?.toString() ?? '0') ?? 0;
                    final uAvatar = ApiConstants.getImageUrl(
                      user['avatar']?.toString(),
                    );
                    final username =
                        user['username']?.toString() ?? 'pengguna';
                    final fullName = user['name']?.toString() ?? '';
                    final noteText =
                        user['note_text']?.toString().trim() ?? '';
                    final lastMsgText =
                        user['last_message_text']?.toString().trim() ?? '';
                    final lastMsgImage =
                        user['last_message_image']?.toString().trim() ?? '';
                    final lastMsgSenderId = int.tryParse(
                          user['last_message_sender_id']?.toString() ?? '0',
                        ) ??
                        0;
                    final lastMsgTime =
                        user['last_message_time']?.toString().trim() ?? '';

                    final bool hasLastMessage =
                        lastMsgText.isNotEmpty || lastMsgImage.isNotEmpty;
                    final String signature = _buildMessageSignature(user);
                    final bool isUnreadIncoming = hasLastMessage &&
                        lastMsgSenderId > 0 &&
                        lastMsgSenderId != currentUserId &&
                        _seenLastMessageSignatures[partnerId] != signature;
                    final bool isOnlineActive =
                        isUnreadIncoming || noteText.isNotEmpty;

                    String basePreview;
                    if (hasLastMessage) {
                      final prefix =
                          lastMsgSenderId == currentUserId ? 'Anda: ' : '';
                      if (lastMsgImage.isNotEmpty && lastMsgText.isEmpty) {
                        basePreview = '${prefix}Mengirim foto';
                      } else if (lastMsgImage.isNotEmpty &&
                          lastMsgText.isNotEmpty) {
                        basePreview = '$prefix[Foto] $lastMsgText';
                      } else {
                        basePreview = '$prefix$lastMsgText';
                      }
                    } else if (noteText.isNotEmpty) {
                      basePreview = 'Catatan: "$noteText"';
                    } else {
                      basePreview = 'Ketuk untuk mulai percakapan';
                    }

                    final String subtitlePreview =
                        (hasLastMessage && lastMsgTime.isNotEmpty)
                            ? '$basePreview • $lastMsgTime'
                            : basePreview;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openChatRoom(user),
                        hoverColor: AppColors.surfaceContainerLow,
                        splashColor: AppColors.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surfaceContainerHigh,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: uAvatar.isNotEmpty
                                        ? Image.network(
                                            uAvatar,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Center(
                                              child: Text(
                                                username.isNotEmpty
                                                    ? username[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              username.isNotEmpty
                                                  ? username[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Plus Jakarta Sans',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (isOnlineActive)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.surface,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Gap(14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            fullName.isNotEmpty
                                                ? fullName
                                                : username,
                                            style: const TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 16,
                                              height: 24 / 16,
                                              letterSpacing: -0.16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Gap(6),
                                        Text(
                                          '@$username',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            color: AppColors.outline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    const Gap(2),
                                    Text(
                                      subtitlePreview,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: isUnreadIncoming ? 12.5 : 14,
                                        height: 1.35,
                                        color: isUnreadIncoming
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                        fontWeight: isUnreadIncoming
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isUnreadIncoming) ...[
                                const Gap(10),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filteredChatUsers.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem({
    required String avatarUrl,
    required String label,
    required String fallbackLetter,
    required String noteText,
    required bool isPlaceholderNote,
    required bool isOwn,
    required VoidCallback onTap,
  }) {
    final bool showBubble = isOwn || noteText.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating Note Bubble Slot (diperbesar ke atas, tinggi seragam agar semua avatar sejajar)
            SizedBox(
              height: 70,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: showBubble
                    ? Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: -4,
                            child: Transform.rotate(
                              angle: math.pi / 4,
                              child: Container(
                                width: 11,
                                height: 11,
                                color: AppColors.surfaceContainerLowest,
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(
                              maxWidth: 96,
                              minWidth: 72,
                              minHeight: 44,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.onSurface
                                      .withValues(alpha: 0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              noteText,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                                color: isPlaceholderNote
                                    ? AppColors.outline
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const Gap(6),

            // Avatar 80x80 + Badge '+' untuk akun sendiri
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                    border: isOwn
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            width: 2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                fallbackLetter,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              fallbackLetter,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                if (isOwn)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withValues(alpha: 0.14),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: isOwn ? FontWeight.w600 : FontWeight.w500,
                color: isOwn ? AppColors.onSurface : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ruang Obrolan (Chat Room) Real-Time antar 2 User
/// Mendukung:
/// - Pengiriman pesan teks secara real-time
/// - Pengiriman foto (Kamera & Galeri) beserta keterangan teks
/// - Balas pesan (Reply chat sesuai chat yang dipilih)
/// - Hapus pesan (Delete chat sesuai chat yang dipilih)
class ChatRoomView extends StatefulWidget {
  final Map<String, dynamic> partnerUser;

  const ChatRoomView({super.key, required this.partnerUser});

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final PusherChannelsFlutter _pusher =
      PusherChannelsFlutter.getInstance();
  String? _chatChannelName;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showQuickSymbols = false;

  // BMP 3-byte aman untuk charset utf8 database MySQL
  static const List<String> _quickSymbols = [
    '☺',
    '♥',
    '★',
    '✨',
    '☕',
    '♪',
    '✓',
    '!',
  ];

  // State untuk Reply Chat yang dipilih
  Map<String, dynamic>? _replyingToMessage;

  // State untuk Foto yang dipilih sebelum dikirim
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  int get _partnerId =>
      int.tryParse(widget.partnerUser['user_id']?.toString() ?? '0') ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages(silent: false, scrollToBottom: true);
      _setupPusher();

      final currentUser = context.read<LoginViewModel>().user;
      final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
      final profileVm = context.read<ProfileViewModel>();
      if (_partnerId > 0 && profileVm.getProfile(_partnerId) == null) {
        profileVm.fetchProfile(_partnerId, viewerId: currentUserId);
      }
    });
  }

  Future<void> _setupPusher() async {
    try {
      final loginVm = context.read<LoginViewModel>();
      final currentUserId = int.tryParse(loginVm.user?.id ?? '0') ?? 0;
      final token = loginVm.token;

      if (currentUserId <= 0 || _partnerId <= 0) {
        debugPrint('Pusher: ID pengguna tidak valid.');
        return;
      }
      if (token == null || token.isEmpty) {
        debugPrint('Pusher: Token login tidak ditemukan.');
        return;
      }

      final ids = [currentUserId, _partnerId]..sort();
      _chatChannelName = 'private-chat-${ids[0]}-${ids[1]}';

      await _pusher.init(
        // Isi dengan App Key Pusher (bukan App Secret).
        apiKey: 'ISI_APP_KEY_PUBLIK_KAMU',
        cluster: 'ap1',
        onAuthorizer: (channelName, socketId, options) async {
          final response = await http.post(
            Uri.parse('${ApiConstants.baseUrl}/messages/auth.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'socket_id': socketId,
              'channel_name': channelName,
            }),
          );

          if (response.statusCode != 200) {
            throw Exception(
              'Autentikasi Pusher gagal (${response.statusCode}): ${response.body}',
            );
          }

          return Map<String, dynamic>.from(jsonDecode(response.body));
        },
        onError: (message, code, error) {
          debugPrint('Pusher error: $message ($code) $error');
        },
      );

      await _pusher.subscribe(
        channelName: _chatChannelName!,
        onEvent: (event) {
          if (event.eventName == 'new-message' && mounted) {
            debugPrint('Pusher: Pesan baru diterima.');
            _fetchMessages(silent: true);
          }
        },
      );

      await _pusher.connect();
      debugPrint('Pusher: Menghubungkan ke $_chatChannelName');
    } catch (e) {
      debugPrint('Pusher setup gagal: $e');
    }
  }

  @override
  void dispose() {
    final channelName = _chatChannelName;
    if (channelName != null) {
      _pusher.unsubscribe(channelName: channelName);
      _pusher.disconnect();
    }
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({
    bool silent = false,
    bool scrollToBottom = false,
  }) async {
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId <= 0 || _partnerId <= 0) {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final url =
          '${ApiConstants.readMessages}?user_id=$currentUserId&partner_id=$_partnerId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rawList = decoded['data'] ?? [];
        final newList =
            rawList.map((e) => Map<String, dynamic>.from(e)).toList();

        final bool hadNewMessage = newList.length > _messages.length;

        if (mounted) {
          setState(() {
            _messages = newList;
            _isLoading = false;
          });

          if (scrollToBottom || hadNewMessage) {
            _scrollToBottom();
          }
        }
      } else if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImageFile = picked;
            _selectedImageBytes = bytes;
          });
          _inputFocusNode.requestFocus();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto.')),
        );
      }
    }
  }

  void _clearSelectedPhoto() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  void _selectReplyMessage(Map<String, dynamic> msg) {
    setState(() {
      _replyingToMessage = msg;
    });
    _inputFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (currentUserId <= 0 || _partnerId <= 0) return;

    final text = _messageController.text.trim();
    final hasPhoto = _selectedImageFile != null && _selectedImageBytes != null;

    if (text.isEmpty && !hasPhoto) return;

    final replyId = _replyingToMessage != null
        ? (int.tryParse(_replyingToMessage!['id']?.toString() ?? '0') ?? 0)
        : 0;

    setState(() => _isSending = true);

    try {
      bool success = false;

      if (hasPhoto) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConstants.sendMessage),
        );
        request.fields['sender_id'] = currentUserId.toString();
        request.fields['receiver_id'] = _partnerId.toString();
        request.fields['message_text'] = text;
        if (replyId > 0) {
          request.fields['reply_to_id'] = replyId.toString();
        }

        final fileName = _selectedImageFile!.name.isNotEmpty
            ? _selectedImageFile!.name
            : 'chat_photo.jpg';
        final ext = fileName.split('.').last.toLowerCase();
        final subType = (ext == 'png' || ext == 'webp') ? ext : 'jpeg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _selectedImageBytes!,
            filename: fileName,
            contentType: MediaType('image', subType),
          ),
        );

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        success = response.statusCode == 201 || response.statusCode == 200;
      } else {
        final response = await http.post(
          Uri.parse(ApiConstants.sendMessage),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_id': currentUserId,
            'receiver_id': _partnerId,
            'message_text': text,
            'reply_to_id': replyId > 0 ? replyId : null,
          }),
        );
        success = response.statusCode == 201 || response.statusCode == 200;
      }

      if (success && mounted) {
        _messageController.clear();
        setState(() {
          _replyingToMessage = null;
          _selectedImageFile = null;
          _selectedImageBytes = null;
          _isSending = false;
        });
        await _fetchMessages(silent: true, scrollToBottom: true);
      } else if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pesan.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan jaringan saat mengirim pesan.'),
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> msg) async {
    final msgId = int.tryParse(msg['id']?.toString() ?? '0') ?? 0;
    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    if (msgId <= 0 || currentUserId <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Pesan?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Pesan yang dipilih akan dihapus secara permanen dari ruang obrolan ini.',
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

    if (confirmed != true || !mounted) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.deleteMessage),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message_id': msgId,
          'user_id': currentUserId,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _messages.removeWhere(
            (m) => (int.tryParse(m['id']?.toString() ?? '0') ?? 0) == msgId,
          );
          if (_replyingToMessage != null &&
              (int.tryParse(_replyingToMessage!['id']?.toString() ?? '0') ??
                      0) ==
                  msgId) {
            _replyingToMessage = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan berhasil dihapus.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus pesan.')),
        );
      }
    }
  }

  void _showMessageActionSheet(
    Map<String, dynamic> msg, {
    required bool isMine,
    required String partnerUsername,
  }) {
    final msgText = msg['message_text']?.toString().trim() ?? '';
    final hasImage =
        (msg['image']?.toString().trim().isNotEmpty ?? false);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetCtx) {
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          msgText.isNotEmpty
                              ? '"$msgText"'
                              : (hasImage ? 'Foto / Postingan' : 'Pesan Chat'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 14),
                ListTile(
                  leading: const Icon(
                    Icons.reply_rounded,
                    size: 20,
                    color: AppColors.deepForest,
                  ),
                  title: Text(
                    isMine
                        ? 'Balas Pesan Anda Sendiri'
                        : 'Balas Pesan @$partnerUsername',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _selectReplyMessage(msg);
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
                    'Hapus Pesan Ini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _deleteMessage(msg);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _insertSymbol(String sym) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;
    final updated = text.replaceRange(start, end, sym);
    _messageController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + sym.length),
    );
    _inputFocusNode.requestFocus();
  }

  String _normalizeImagePath(String? path) {
    if (path == null) return '';
    return path.trim().replaceFirst(RegExp(r'^/'), '');
  }

  String _formatDateDividerLabel(String rawCreateDate) {
    final trimmed = rawCreateDate.trim();
    if (trimmed.isEmpty) return 'HARI INI';
    final parsed = DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
    if (parsed == null) return 'HARI INI';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(msgDay).inDays;

    if (diff == 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _extractTimeLabel(Map<String, dynamic> msg) {
    final label = msg['time_label']?.toString().trim() ?? '';
    if (label.isNotEmpty) return label;
    final raw = msg['create_date']?.toString().trim() ?? '';
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return '';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _openSharedPostDetail(Map<String, dynamic> msg) async {
    final int sharedPostId =
        int.tryParse(msg['shared_post_id']?.toString() ?? '0') ?? 0;
    final String rawImage = msg['image']?.toString().trim() ?? '';
    final String normalizedTargetImg = _normalizeImagePath(rawImage);
    final String imageUrl = ApiConstants.getImageUrl(rawImage);

    final currentUser = context.read<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final homeVm = context.read<HomeViewModel>();

    PostModel? matchedPost;
    for (final post in homeVm.posts) {
      if ((sharedPostId > 0 && post.id == sharedPostId) ||
          (normalizedTargetImg.isNotEmpty &&
              _normalizeImagePath(post.image) == normalizedTargetImg)) {
        matchedPost = post;
        break;
      }
    }

    if (matchedPost == null) {
      try {
        final url = '${ApiConstants.readPosts}?viewer_id=$currentUserId';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final List<dynamic> list = decoded['data'] ?? [];
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final candidate = PostModel.fromJson(item);
              if ((sharedPostId > 0 && candidate.id == sharedPostId) ||
                  (normalizedTargetImg.isNotEmpty &&
                      _normalizeImagePath(candidate.image) ==
                          normalizedTargetImg)) {
                matchedPost = candidate;
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (matchedPost == null) {
      _openFullPhotoDialog(imageUrl, '');
      return;
    }

    final PostModel postToShow = matchedPost;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Postingan',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      PostCard(
                        post: postToShow,
                        onPostDeleted: () {
                          Navigator.pop(sheetCtx);
                          homeVm.fetchPosts(viewerId: currentUserId);
                        },
                        onPostUpdated: () {
                          homeVm.fetchPosts(viewerId: currentUserId);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openFullPhotoDialog(String imageUrl, String caption) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              if (caption.isNotEmpty)
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openPartnerProfile(int userId, String username) {
    if (userId <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileView(
          userId: userId,
          username: username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final partnerProfile = context.watch<ProfileViewModel>().getProfile(_partnerId);

    final partnerId = _partnerId;
    final username =
        widget.partnerUser['username']?.toString() ?? 'pengguna';
    final fullName = widget.partnerUser['name']?.toString() ?? '';
    final displayName = fullName.isNotEmpty ? fullName : username;
    final avatarUrl = ApiConstants.getImageUrl(
      widget.partnerUser['avatar']?.toString(),
    );
    final partnerNote =
        widget.partnerUser['note_text']?.toString().trim() ?? '';

    final String profileMetaText = partnerProfile != null
        ? '@$username • ${partnerProfile.followersCount} pengikut • ${partnerProfile.posts.length} postingan'
        : '@$username • ZieSocial';

    // Susun daftar widget pesan dengan pemisah tanggal (Date Chip Divider)
    final List<Widget> messageStreamWidgets = [];
    String? lastDayLabel;
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final senderId = int.tryParse(msg['sender_id']?.toString() ?? '0') ?? 0;
      final bool isMine = senderId == currentUserId;
      final String dayLabel = _formatDateDividerLabel(
        msg['create_date']?.toString() ?? '',
      );

      if (dayLabel != lastDayLabel) {
        lastDayLabel = dayLabel;
        messageStreamWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  dayLabel,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Cek apakah pesan sebelumnya juga dari partner & masih dalam kelompok sama
      bool showPartnerAvatar = !isMine;
      if (!isMine && i > 0) {
        final prev = _messages[i - 1];
        final prevSender =
            int.tryParse(prev['sender_id']?.toString() ?? '0') ?? 0;
        final prevDay = _formatDateDividerLabel(
          prev['create_date']?.toString() ?? '',
        );
        final bool prevHasImg =
            (prev['image']?.toString().trim().isNotEmpty ?? false);
        if (prevSender == senderId && prevDay == dayLabel && prevHasImg) {
          showPartnerAvatar = false;
        }
      }

      messageStreamWidgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: 12,
            top: (!showPartnerAvatar && !isMine) ? 0 : 2,
          ),
          child: _buildChatMessageItem(
            msg: msg,
            isMine: isMine,
            currentUserId: currentUserId,
            partnerAvatarUrl: avatarUrl,
            partnerUsername: username,
            partnerDisplayName: displayName,
            showPartnerAvatar: showPartnerAvatar,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.80),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 24,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const Gap(4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _openPartnerProfile(partnerId, username),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.surfaceContainerHigh,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: avatarUrl.isNotEmpty
                                          ? Image.network(
                                              avatarUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => Center(
                                                child: Text(
                                                  username.isNotEmpty
                                                      ? username[0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                username.isNotEmpty
                                                    ? username[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.surface,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 16,
                                          height: 22 / 16,
                                          letterSpacing: -0.16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '@$username • Active now',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          height: 16 / 12,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Area Percakapan (Profile Splash + Daftar Pesan Real-Time)
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                // 1. Profile Header Splash
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceContainerHigh,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.onSurface
                                      .withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: avatarUrl.isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: Text(
                                        username.isNotEmpty
                                            ? username[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      username.isNotEmpty
                                          ? username[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          height: 28 / 20,
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        profileMetaText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          height: 16 / 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const Gap(12),
                      Material(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                        elevation: 0.5,
                        shadowColor:
                            AppColors.onSurface.withValues(alpha: 0.08),
                        child: InkWell(
                          onTap: () => _openPartnerProfile(partnerId, username),
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Profil',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Gap(6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),

                // Catatan aktif partner jika ada
                if (partnerNote.isNotEmpty) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Catatan @$username: "$partnerNote"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                ],

                // 2. State Loading / Kosong / Daftar Pesan
                if (_isLoading && _messages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (_messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 20,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.mark_chat_unread_outlined,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const Gap(12),
                          Text(
                            'Belum ada pesan dengan @$username',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const Gap(4),
                          const Text(
                            'Kirim pesan teks atau bagikan foto untuk memulai percakapan. Ketuk pesan untuk membalas atau menghapus.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...messageStreamWidgets,
              ],
            ),
          ),

          // 3. Banner Reply Chat (Muncul saat user memilih pesan untuk dibalas)
          if (_replyingToMessage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                border: Border(
                  top: BorderSide(
                    color: AppColors.surfaceContainerHighest,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(10),
                  const Icon(
                    Icons.reply_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (int.tryParse(_replyingToMessage!['sender_id']
                                          ?.toString() ??
                                      '0') ??
                                  0) ==
                              currentUserId
                              ? 'Membalas pesan Anda sendiri'
                              : 'Membalas @$username',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          (_replyingToMessage!['message_text']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ??
                                  false)
                              ? _replyingToMessage!['message_text'].toString()
                              : 'Foto / Postingan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _cancelReply,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Batal Balas',
                  ),
                ],
              ),
            ),

          // 4. Pratinjau Foto yang Dipilih Sebelum Dikirim
          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                border: Border(
                  top: BorderSide(
                    color: AppColors.surfaceContainerHighest,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto Siap Dikirim',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Gap(2),
                        Text(
                          'Tambahkan pesan teks (opsional) lalu tekan kirim.',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearSelectedPhoto,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: AppColors.error,
                    ),
                    tooltip: 'Hapus Foto Pilihan',
                  ),
                ],
              ),
            ),

          // Panel Simbol Cepat (saat ikon senyum ditekan)
          if (_showQuickSymbols)
            Container(
              width: double.infinity,
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _quickSymbols.map((sym) {
                  return InkWell(
                    onTap: () => _insertSymbol(sym),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(sym, style: const TextStyle(fontSize: 15)),
                    ),
                  );
                }).toList(),
              ),
            ),

          // 5. Bottom Floating Chat Bar
          ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.90),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _isSending
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 22,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _isSending
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.image_outlined,
                              size: 22,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const Gap(4),

                      // Modern Capsule Input Field
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  focusNode: _inputFocusNode,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    color: AppColors.onSurface,
                                  ),
                                  textInputAction: TextInputAction.send,
                                  decoration: InputDecoration(
                                    hintText: _replyingToMessage != null
                                        ? 'Tulis balasan pesan...'
                                        : 'Kirim pesan...',
                                    hintStyle: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 14,
                                      color: AppColors.outline,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showQuickSymbols = !_showQuickSymbols;
                                  });
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.sentiment_satisfied_outlined,
                                    size: 20,
                                    color: _showQuickSymbols
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(8),

                      // Tombol Kirim Bulat Indigo
                      Material(
                        color: AppColors.primaryContainer,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.30),
                        child: InkWell(
                          onTap: _isSending ? null : _sendMessage,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildChatMessageItem({
    required Map<String, dynamic> msg,
    required bool isMine,
    required int currentUserId,
    required String partnerAvatarUrl,
    required String partnerUsername,
    required String partnerDisplayName,
    required bool showPartnerAvatar,
  }) {
    final rawText = msg['message_text']?.toString().trim() ?? '';
    final text = rawText
        .replaceAll(RegExp(r'\?{3,}\s*'), '')
        .replaceAll(RegExp(r'Postingan\s+@[^:]+:\s*".*"', caseSensitive: false), '')
        .replaceAll(RegExp(r'Membagikan postingan\s+@\S+', caseSensitive: false), '')
        .trim();

    final rawImage = msg['image']?.toString().trim() ?? '';
    final imageUrl =
        rawImage.isNotEmpty ? ApiConstants.getImageUrl(rawImage) : '';
    final timeLabel = _extractTimeLabel(msg);

    // Pastikan foto chat langsung di uploads/messages/ TIDAK dianggap shared post
    final bool isDirectChatPhoto =
        rawImage.isNotEmpty && _normalizeImagePath(rawImage).startsWith('uploads/messages/');
    final bool isSharedPost = !isDirectChatPhoto &&
        rawImage.isNotEmpty &&
        (msg['is_shared_post'] == true || !rawImage.startsWith('uploads/messages/'));

    final String sharedAuthorUsername =
        (msg['shared_author_username']?.toString().trim().isNotEmpty ?? false)
            ? msg['shared_author_username'].toString().trim()
            : partnerUsername;
    final String sharedAuthorAvatarUrl = ApiConstants.getImageUrl(
      msg['shared_author_avatar']?.toString(),
    );

    final replyToId = int.tryParse(msg['reply_to_id']?.toString() ?? '0') ?? 0;
    final replyText = (msg['reply_text']?.toString().trim() ?? '')
        .replaceAll(RegExp(r'\?{3,}\s*'), '')
        .trim();
    final replyImage = msg['reply_image']?.toString().trim() ?? '';
    final replyImageUrl =
        replyImage.isNotEmpty ? ApiConstants.getImageUrl(replyImage) : '';
    final replySenderId =
        int.tryParse(msg['reply_sender_id']?.toString() ?? '0') ?? 0;
    final replySenderUsername =
        msg['reply_sender_username']?.toString().trim() ?? partnerUsername;
    final bool hasReply =
        replyToId > 0 && (replyText.isNotEmpty || replyImage.isNotEmpty);

    final String replyAuthorLabel = replySenderId == currentUserId
        ? 'Anda'
        : (replySenderUsername == partnerUsername
            ? partnerDisplayName
            : '@$replySenderUsername');

    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxBubbleWidth = math.min(screenWidth * 0.78, 300);

    // Footer waktu (+ centang biru untuk outgoing)
    Widget buildTimestampFooter({bool useSentLabel = false}) {
      if (isMine) {
        final String label =
            useSentLabel ? 'Terkirim' : (timeLabel.isNotEmpty ? timeLabel : 'Baru saja');
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Gap(4),
            const Icon(
              Icons.done_all_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        );
      }

      if (timeLabel.isEmpty) return const SizedBox.shrink();
      return Text(
        timeLabel,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }

    // Helper Avatar kecil 28x28 partner
    Widget buildPartnerMiniAvatar() {
      final fallbackLetter = partnerUsername.isNotEmpty
          ? partnerUsername[0].toUpperCase()
          : 'U';
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerHigh,
        ),
        clipBehavior: Clip.antiAlias,
        child: partnerAvatarUrl.isNotEmpty
            ? Image.network(
                partnerAvatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    fallbackLetter,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  fallbackLetter,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
      );
    }

    // ----------------------------------------------------------------------
    // KASUS 1: CHAT KIRIM POSTINGAN (Shared Post) -> Sesuai Gambar Referensi
    // & Bisa Diklik Untuk Melihat Postingan Aslinya
    // ----------------------------------------------------------------------
    if (imageUrl.isNotEmpty && isSharedPost) {
      final authorInitial = sharedAuthorUsername.isNotEmpty
          ? sharedAuthorUsername[0].toUpperCase()
          : 'U';
      final double cardWidth = math.min(252.0, screenWidth * 0.65);

      final Widget sharedPostCard = GestureDetector(
        onTap: () => _openSharedPostDetail(msg),
        onLongPress: () => _showMessageActionSheet(
          msg,
          isMine: isMine,
          partnerUsername: partnerUsername,
        ),
        child: Container(
          width: cardWidth,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceContainerHigh,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.outline,
                    size: 32,
                  ),
                ),
              ),

              // Gradasi atas halus untuk keterbacaan avatar & username penulis
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.60),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Gradasi bawah halus untuk badge 'Lihat Postingan' & jam
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Minimalist Post Author Badge Overlay + Open Icon
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryContainer,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.60),
                                      width: 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: sharedAuthorAvatarUrl.isNotEmpty
                                      ? Image.network(
                                          sharedAuthorAvatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Center(
                                            child: Text(
                                              authorInitial,
                                              style: const TextStyle(
                                                fontFamily:
                                                    'Plus Jakarta Sans',
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            authorInitial,
                                            style: const TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                                const Gap(7),
                                Flexible(
                                  child: Text(
                                    sharedAuthorUsername,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Overlay Tags ('Lihat Postingan' kiri + waktu kanan)
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Lihat Postingan',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (timeLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      final Widget verticalSideActions = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _selectReplyMessage(msg),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.reply_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const Gap(4),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _showMessageActionSheet(
                msg,
                isMine: isMine,
                partnerUsername: partnerUsername,
              ),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );

      if (isMine) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              verticalSideActions,
              const Gap(6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  sharedPostCard,
                  const Gap(4),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: buildTimestampFooter(useSentLabel: true),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: buildPartnerMiniAvatar(),
              ),
              const Gap(8),
              sharedPostCard,
              const Gap(6),
              Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: verticalSideActions,
              ),
            ],
          ),
        );
      }
    }

    // ----------------------------------------------------------------------
    // KASUS 2: CHAT FOTO BIASA (Pure photo TANPA foto profil & username di atas)
    // ----------------------------------------------------------------------
    if (imageUrl.isNotEmpty) {
      final Widget photoWidget = GestureDetector(
        onTap: () => _openFullPhotoDialog(imageUrl, text),
        onLongPress: () => _showMessageActionSheet(
          msg,
          isMine: isMine,
          partnerUsername: partnerUsername,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: math.min(256.0, screenWidth * 0.72),
            maxHeight: 288,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surfaceContainerHigh,
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: math.min(256.0, screenWidth * 0.72),
                errorBuilder: (_, _, _) => Container(
                  width: 200,
                  height: 150,
                  color: AppColors.surfaceContainerLow,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.outline,
                  ),
                ),
              ),
              if (timeLabel.isNotEmpty)
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        color: AppColors.inverseSurface.withValues(alpha: 0.65),
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inverseOnSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      final Widget? captionBubble = text.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () => _showMessageActionSheet(
                  msg,
                  isMine: isMine,
                  partnerUsername: partnerUsername,
                ),
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerLowest,
                    borderRadius: isMine
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                            bottomLeft: Radius.circular(22),
                            bottomRight: Radius.circular(6),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(22),
                            bottomLeft: Radius.circular(22),
                            bottomRight: Radius.circular(22),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      height: 1.45,
                      color: isMine ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            )
          : null;

      if (isMine) {
        return Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              photoWidget,
              if (captionBubble != null) captionBubble,
              const Gap(4),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: buildTimestampFooter(),
              ),
            ],
          ),
        );
      } else {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showPartnerAvatar)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: buildPartnerMiniAvatar(),
              )
            else
              const SizedBox(width: 28),
            const Gap(8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  photoWidget,
                  if (captionBubble != null) captionBubble,
                ],
              ),
            ),
          ],
        );
      }
    }

    // ----------------------------------------------------------------------
    // KASUS 3: PESAN TEKS & QUOTE REPLY (Modern Indigo / White Surface Bubbles)
    // ----------------------------------------------------------------------
    if (text.isEmpty && !hasReply) {
      return const SizedBox.shrink();
    }

    Widget? quoteSnippetInsideBubble;
    if (hasReply) {
      final String quotedBody =
          replyText.isNotEmpty ? replyText : 'Foto / Postingan';
      quoteSnippetInsideBubble = Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.primary.withValues(alpha: 0.38)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyImageUrl.isNotEmpty && replyText.isEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  replyImageUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const Gap(8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    replyAuthorLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isMine
                          ? const Color(0xFFDAD7FF)
                          : AppColors.primary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    quotedBody,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.90)
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final Widget textBubbleCard = GestureDetector(
      onTap: () => _showMessageActionSheet(
        msg,
        isMine: isMine,
        partnerUsername: partnerUsername,
      ),
      onLongPress: () => _showMessageActionSheet(
        msg,
        isMine: isMine,
        partnerUsername: partnerUsername,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: hasReply
            ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: isMine
              ? const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(6),
                )
              : BorderRadius.only(
                  topLeft: Radius.circular(showPartnerAvatar ? 22 : 6),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(showPartnerAvatar ? 6 : 22),
                  bottomRight: const Radius.circular(22),
                ),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quoteSnippetInsideBubble != null) quoteSnippetInsideBubble,
              if (text.isNotEmpty)
                Padding(
                  padding: hasReply
                      ? const EdgeInsets.fromLTRB(10, 2, 10, 2)
                      : EdgeInsets.zero,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      height: 1.45,
                      color: isMine ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (isMine) {
      return Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            textBubbleCard,
            const Gap(4),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: buildTimestampFooter(),
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showPartnerAvatar)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: buildPartnerMiniAvatar(),
            )
          else
            const SizedBox(width: 28),
          const Gap(8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBubbleCard,
                const Gap(4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: buildTimestampFooter(),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}


