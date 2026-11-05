import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/core/constants.dart';
import 'package:ziesocial/model/user_model.dart';
import 'package:ziesocial/view/edit_profile_view.dart';
import 'package:ziesocial/view/login_view.dart';
import 'package:ziesocial/viewmodel/home_viewmodel.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class AccountSettingsView extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onProfileUpdated;

  const AccountSettingsView({
    super.key,
    required this.user,
    this.onProfileUpdated,
  });

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  Future<void> _openEditProfile(UserModel currentUser) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileView(user: currentUser),
      ),
    );
    if (updated == true && mounted) {
      widget.onProfileUpdated?.call();
      setState(() {});
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Sesi Anda akan diakhiri dan Anda akan kembali ke halaman masuk ZieSocial.',
          style: TextStyle(fontSize: 13.5, color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LoginViewModel>().logout();
              context.read<ProfileViewModel>().clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepForest,
              foregroundColor: AppColors.pureWhite,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(UserModel currentUser) {
    bool isConfirmed = false;
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                  Gap(8),
                  Expanded(
                    child: Text(
                      'Hapus Akun Permanen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tindakan ini bersifat permanen dan tidak dapat dibatalkan. Seluruh data akun Anda akan dihapus dari database ZieSocial, meliputi:',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.secondaryText,
                        height: 1.45,
                      ),
                    ),
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warmIvory,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• Semua postingan foto, cerita, dan sorotan profil',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Gap(4),
                          Text(
                            '• Daftar pengikut dan akun yang diikuti',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Gap(4),
                          Text(
                            '• Seluruh riwayat suka dan komentar',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          isConfirmed = !isConfirmed;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isConfirmed,
                              activeColor: AppColors.error,
                              onChanged: (val) {
                                setDialogState(() {
                                  isConfirmed = val ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Saya mengerti bahwa penghapusan akun ini bersifat permanen.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                ElevatedButton(
                  onPressed: (!isConfirmed || isDeleting)
                      ? null
                      : () async {
                          final userId =
                              int.tryParse(currentUser.id) ?? 0;
                          if (userId <= 0) return;

                          setDialogState(() => isDeleting = true);

                          final profileVm = context.read<ProfileViewModel>();
                          final loginVm = context.read<LoginViewModel>();
                          final homeVm = context.read<HomeViewModel>();
                          final messenger = ScaffoldMessenger.of(this.context);
                          final navigator = Navigator.of(this.context);

                          final deleted =
                              await profileVm.deleteAccount(userId);
                          if (!mounted) return;

                          Navigator.pop(ctx);

                          if (deleted) {
                            loginVm.logout();
                            homeVm.fetchPosts();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Akun Anda beserta seluruh datanya telah dihapus.',
                                ),
                              ),
                            );
                            navigator.pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginView(),
                              ),
                              (route) => false,
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  profileVm.getErrorMessage(userId) ??
                                      'Gagal menghapus akun.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.pureWhite,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.pureWhite,
                          ),
                        )
                      : const Text('Hapus Akun Permanen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        context.watch<LoginViewModel>().user ?? widget.user;
    final avatarUrl = ApiConstants.getImageUrl(currentUser.avatar);

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const Gap(4),
                  const Text(
                    'Pengaturan Akun',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Account Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.warmIvory,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                currentUser.username.isNotEmpty
                                    ? currentUser.username[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepForest,
                                ),
                              )
                            : null,
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.name.isNotEmpty
                                  ? currentUser.name
                                  : currentUser.username,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              '@${currentUser.username}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            if (currentUser.email.isNotEmpty) ...[
                              const Gap(2),
                              Text(
                                currentUser.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // Section 1: Manajemen Akun
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'MANAJEMEN AKUN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profil & Identitas',
                        subtitle:
                            'Ubah foto profil, nama lengkap, username, dan bio',
                        onTap: () => _openEditProfile(currentUser),
                      ),
                      const Divider(height: 1, indent: 52),
                      _buildSettingsTile(
                        icon: Icons.photo_camera_outlined,
                        title: 'Perbarui Foto Profil',
                        subtitle: 'Pilih foto potret baru dari perangkat Anda',
                        onTap: () => _openEditProfile(currentUser),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // Section 2: Tindakan Akun
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'TINDAKAN AKUN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Keluar dari Aplikasi',
                        subtitle:
                            'Akhiri sesi saat ini dan kembali ke halaman masuk',
                        onTap: _confirmLogout,
                      ),
                      const Divider(height: 1, indent: 52),
                      _buildSettingsTile(
                        icon: Icons.delete_forever_outlined,
                        title: 'Hapus Akun Permanen',
                        subtitle:
                            'Hapus akun, postingan, pengikut, suka, dan komentar dari database',
                        isDestructive: true,
                        onTap: () => _confirmDeleteAccount(currentUser),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.primaryText;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.08)
              : AppColors.warmIvory,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: Icon(icon, size: 19, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDestructive ? AppColors.error : AppColors.secondaryText,
      ),
    );
  }
}

