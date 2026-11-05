import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/view/profile_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _poller;
  String _searchQuery = '';

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
                                  'Catatan Anda (Note)',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                Gap(2),
                                Text(
                                  'Bagikan pemikiran singkat selama 24 jam di menu Pesan',
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
                                        color: AppColors.pureWhite,
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

  Future<void> _openChatRoom(Map<String, dynamic> targetUser) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomView(partnerUser: targetUser),
      ),
    );
    if (mounted) {
      _loadNotesAndUsers(silent: true);
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

    final filteredChatUsers = _searchQuery.isEmpty
        ? allOtherUsers
        : allOtherUsers.where((u) {
            final q = _searchQuery.toLowerCase();
            final uname = (u['username']?.toString() ?? '').toLowerCase();
            final name = (u['name']?.toString() ?? '').toLowerCase();
            return uname.contains(q) || name.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Text(
                    'Pesan & Catatan',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Gap(10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmIvory,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '@$myUsername',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepForest,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _openCreateNoteSheet(
                      currentUserId: currentUserId,
                      currentNote: myNoteText,
                      avatarUrl: myAvatarUrl,
                      username: myUsername,
                    ),
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      size: 23,
                      color: AppColors.primaryText,
                    ),
                    tooltip: 'Tulis Catatan',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.deepForest,
        backgroundColor: AppColors.pureWhite,
        onRefresh: () => _loadNotesAndUsers(silent: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari pengguna di daftar pesan...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 19,
                        color: AppColors.secondaryText,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 17,
                                color: AppColors.secondaryText,
                              ),
                              padding: EdgeInsets.zero,
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.warmIvory,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.sageGreen,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. FITUR NOTE / CATATAN (Berjajar ke samping di bagian atas)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: const BoxDecoration(
                  color: AppColors.warmIvory,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CATATAN PENGGUNA (NOTES)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: AppColors.secondaryText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openCreateNoteSheet(
                              currentUserId: currentUserId,
                              currentNote: myNoteText,
                              avatarUrl: myAvatarUrl,
                              username: myUsername,
                            ),
                            child: Text(
                              myNoteText.isEmpty
                                  ? '+ Buat Catatan'
                                  : 'Ubah Catatan',
                              style: const TextStyle(
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
                      height: 126,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: allOtherUsers.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Item 0: Catatan Anda
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
                            onTap: () => _openChatRoom(user),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Header Bagian Daftar Chat (Di bawah fitur Note, berjajar ke bawah)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PESAN LANGSUNG (CHAT)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      '${filteredChatUsers.length} Pengguna',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Daftar Chat Berjajar ke Bawah
            if (profileVm.isLoadingNotes && filteredChatUsers.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.sageGreen,
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
                          'Belum ada pengguna ditemukan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
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
                    String subtitlePreview;
                    if (hasLastMessage) {
                      final prefix =
                          lastMsgSenderId == currentUserId ? 'Anda: ' : '';
                      if (lastMsgImage.isNotEmpty && lastMsgText.isEmpty) {
                        subtitlePreview = '${prefix}Mengirim foto';
                      } else if (lastMsgImage.isNotEmpty &&
                          lastMsgText.isNotEmpty) {
                        subtitlePreview = '$prefix[Foto] $lastMsgText';
                      } else {
                        subtitlePreview = '$prefix$lastMsgText';
                      }
                    } else if (noteText.isNotEmpty) {
                      subtitlePreview = 'Catatan: "$noteText"';
                    } else {
                      subtitlePreview =
                          'Belum ada pesan • Ketuk untuk mulai chat';
                    }

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => _openChatRoom(user),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.warmIvory,
                                      backgroundImage: uAvatar.isNotEmpty
                                          ? NetworkImage(uAvatar)
                                          : null,
                                      child: uAvatar.isEmpty
                                          ? Text(
                                              username.isNotEmpty
                                                  ? username[0].toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: AppColors.deepForest,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 11,
                                        height: 11,
                                        decoration: BoxDecoration(
                                          color: AppColors.sageGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.pureWhite,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              fullName.isNotEmpty
                                                  ? fullName
                                                  : username,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Gap(6),
                                          Text(
                                            '@$username',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                          if (lastMsgTime.isNotEmpty) ...[
                                            const Spacer(),
                                            Text(
                                              lastMsgTime,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.secondaryText,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const Gap(3),
                                      Text(
                                        subtitlePreview,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: (hasLastMessage ||
                                                  noteText.isNotEmpty)
                                              ? AppColors.deepForest
                                              : AppColors.secondaryText,
                                          fontWeight: (hasLastMessage ||
                                                  noteText.isNotEmpty)
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(10),
                                IconButton(
                                  onPressed: () => _openChatRoom(user),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 19,
                                    color: AppColors.secondaryText,
                                  ),
                                  tooltip: 'Buka Chat',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 78,
                          color: AppColors.border,
                        ),
                      ],
                    );
                  },
                  childCount: filteredChatUsers.length,
                ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Floating Note Bubble di atas Avatar (seperti Instagram Notes)
              if (showBubble)
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 80,
                    minHeight: 26,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlaceholderNote
                          ? AppColors.border
                          : AppColors.softBeige,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    noteText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.2,
                      fontWeight: isPlaceholderNote
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: isPlaceholderNote
                          ? AppColors.secondaryText
                          : AppColors.primaryText,
                    ),
                  ),
                )
              else
                const SizedBox(height: 26),

              const Gap(4),

              // Avatar + '+' badge untuk akun sendiri
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (!isPlaceholderNote && noteText.isNotEmpty)
                            ? AppColors.sageGreen
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.pureWhite,
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              fallbackLetter,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.deepForest,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (isOwn)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: AppColors.deepForest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.warmIvory,
                            width: 1.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 12,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isOwn ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
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

  Timer? _chatPoller;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

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
    });

    _chatPoller = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && !_isSending) {
        _fetchMessages(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _chatPoller?.cancel();
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
              foregroundColor: AppColors.pureWhite,
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
                              : (hasImage ? '📷 Foto Lampiran' : 'Pesan Chat'),
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

    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 21,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openPartnerProfile(partnerId, username),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.deepForest,
                                    ),
                                  )
                                : null,
                          ),
                          const Gap(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.sageGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Gap(5),
                                    Expanded(
                                      child: Text(
                                        '@$username • Aktif di ZieSocial',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openPartnerProfile(partnerId, username),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      size: 21,
                      color: AppColors.primaryText,
                    ),
                    tooltip: 'Lihat Profil Akun',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Area Percakapan (Kartu Profil Lawan Bicara + Daftar Pesan Real-Time)
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // 1. Kartu Tampilan Akun di Atas Ruang Chat
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.softBeige,
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 36,
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
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepForest,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const Gap(10),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        '@$username • ZieSocial',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const Gap(10),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () =>
                              _openPartnerProfile(partnerId, username),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: AppColors.warmIvory,
                          ),
                          child: const Text(
                            'Lihat Profil',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),

                // Jika partner memiliki Note aktif, tampilkan di atas percakapan
                if (partnerNote.isNotEmpty) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmIvory,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Catatan @$username: "$partnerNote"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const Gap(18),
                ],

                // 2. State Loading / Kosong / Daftar Bubble Chat Real-Time
                if (_isLoading && _messages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.sageGreen,
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
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.warmIvory,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.mark_chat_unread_outlined,
                              size: 22,
                              color: AppColors.sageGreen,
                            ),
                          ),
                          const Gap(12),
                          Text(
                            'Belum ada pesan dengan @$username',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const Gap(4),
                          const Text(
                            'Kirim pesan teks atau bagikan foto untuk memulai percakapan. Ketuk pesan untuk membalas atau menghapus.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._messages.map((msg) {
                    final senderId =
                        int.tryParse(msg['sender_id']?.toString() ?? '0') ?? 0;
                    final bool isMine = senderId == currentUserId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildChatMessageItem(
                        msg: msg,
                        isMine: isMine,
                        currentUserId: currentUserId,
                        partnerAvatarUrl: avatarUrl,
                        partnerUsername: username,
                      ),
                    );
                  }),
              ],
            ),
          ),

          // 3. Banner Reply Chat (Muncul saat user memilih pesan untuk dibalas)
          if (_replyingToMessage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.warmIvory,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.deepForest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(10),
                  const Icon(
                    Icons.reply_rounded,
                    size: 18,
                    color: AppColors.deepForest,
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
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepForest,
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
                              : '📷 Foto',
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
                  IconButton(
                    onPressed: _cancelReply,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.secondaryText,
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
                color: AppColors.warmIvory,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Gap(2),
                        Text(
                          'Tambahkan pesan teks (opsional) lalu tekan tombol kirim.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.secondaryText,
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

          // 5. Bilah Input Pesan & Kirim Foto di Bagian Bawah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.pureWhite,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Tombol Kamera (Kirim Foto dari Kamera)
                  InkWell(
                    onTap: _isSending
                        ? null
                        : () => _pickPhoto(ImageSource.camera),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.deepForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 18,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                  const Gap(8),

                  // Input Teks + Tombol Pilih Foto Galeri
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.warmIvory,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _inputFocusNode,
                              style: const TextStyle(fontSize: 13.5),
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: _replyingToMessage != null
                                    ? 'Tulis balasan pesan...'
                                    : 'Tulis pesan...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            onPressed: _isSending
                                ? null
                                : () => _pickPhoto(ImageSource.gallery),
                            icon: const Icon(
                              Icons.image_outlined,
                              size: 20,
                              color: AppColors.secondaryText,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Kirim Foto dari Galeri',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(8),

                  // Tombol Kirim Pesan
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepForest,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 21,
                            color: AppColors.deepForest,
                          ),
                    tooltip: 'Kirim',
                  ),
                ],
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
  }) {
    final text = msg['message_text']?.toString().trim() ?? '';
    final rawImage = msg['image']?.toString().trim() ?? '';
    final imageUrl =
        rawImage.isNotEmpty ? ApiConstants.getImageUrl(rawImage) : '';
    final timeLabel = msg['time_label']?.toString().trim() ?? '';

    final replyToId = int.tryParse(msg['reply_to_id']?.toString() ?? '0') ?? 0;
    final replyText = msg['reply_text']?.toString().trim() ?? '';
    final replyImage = msg['reply_image']?.toString().trim() ?? '';
    final replySenderId =
        int.tryParse(msg['reply_sender_id']?.toString() ?? '0') ?? 0;
    final replySenderUsername =
        msg['reply_sender_username']?.toString().trim() ?? partnerUsername;
    final bool hasReply =
        replyToId > 0 && (replyText.isNotEmpty || replyImage.isNotEmpty);

    final String replyAuthorLabel = replySenderId == currentUserId
        ? 'Anda'
        : '@$replySenderUsername';

    final Widget bubbleContent = GestureDetector(
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
        constraints: const BoxConstraints(maxWidth: 265),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isMine ? AppColors.deepForest : AppColors.warmIvory,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
          border: isMine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Kotak Kutipan Reply (jika pesan ini membalas pesan lain)
            if (hasReply) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 7),
                decoration: BoxDecoration(
                  color: isMine
                      ? AppColors.pureWhite.withValues(alpha: 0.13)
                      : AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color:
                          isMine ? AppColors.softBeige : AppColors.sageGreen,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyAuthorLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isMine
                            ? AppColors.softBeige
                            : AppColors.deepForest,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      replyText.isNotEmpty ? replyText : '📷 Foto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isMine
                            ? AppColors.pureWhite.withValues(alpha: 0.85)
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Lampiran Foto di dalam Bubble Chat
            if (imageUrl.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _openFullPhotoDialog(imageUrl, text),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 220,
                      minWidth: 160,
                    ),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 120,
                        color: AppColors.mistGray,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (text.isNotEmpty) const Gap(7),
            ],

            // Teks Pesan
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isMine ? AppColors.pureWhite : AppColors.primaryText,
                  height: 1.4,
                ),
              ),

            const Gap(4),

            // Jam Pengiriman
            Text(
              isMine ? '$timeLabel • Terkirim' : timeLabel,
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? AppColors.pureWhite.withValues(alpha: 0.72)
                    : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );

    // Tombol aksi cepat (Reply & Opsi Hapus) di samping bubble
    final Widget quickActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _selectReplyMessage(msg),
          icon: const Icon(
            Icons.reply_rounded,
            size: 16,
            color: AppColors.secondaryText,
          ),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          tooltip: 'Balas Pesan',
        ),
        IconButton(
          onPressed: () => _showMessageActionSheet(
            msg,
            isMine: isMine,
            partnerUsername: partnerUsername,
          ),
          icon: const Icon(
            Icons.more_vert_rounded,
            size: 16,
            color: AppColors.secondaryText,
          ),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          tooltip: 'Balas / Hapus Pesan',
        ),
      ],
    );

    if (isMine) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          quickActions,
          const Gap(4),
          Flexible(child: bubbleContent),
        ],
      );
    } else {
      final fallbackLetter = partnerUsername.isNotEmpty
          ? partnerUsername[0].toUpperCase()
          : 'U';
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.warmIvory,
            backgroundImage: partnerAvatarUrl.isNotEmpty
                ? NetworkImage(partnerAvatarUrl)
                : null,
            child: partnerAvatarUrl.isEmpty
                ? Text(
                    fallbackLetter,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                    ),
                  )
                : null,
          ),
          const Gap(8),
          Flexible(child: bubbleContent),
          const Gap(4),
          quickActions,
        ],
      );
    }
  }
}


