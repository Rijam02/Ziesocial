import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/view/login_view.dart';
import 'package:ziesocial/viewmodel/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localValidationError;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _localValidationError = 'Semua kolom pendaftaran wajib diisi.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _localValidationError = 'Masukkan format alamat email yang valid.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _localValidationError = 'Kata sandi harus terdiri dari minimal 6 karakter.';
      });
      return;
    }

    setState(() => _localValidationError = null);

    final success = await context.read<RegisterViewModel>().register(
          username: username,
          name: name,
          email: email,
          password: password,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<RegisterViewModel>().successMessage ??
                'Akun berhasil dibuat. Silakan masuk.',
          ),
          backgroundColor: AppColors.deepForest,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    } else {
      final error = context.read<RegisterViewModel>().errorMessage;
      setState(() {
        _localValidationError = error ?? 'Registrasi gagal. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RegisterViewModel>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Header
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.deepForest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Z.',
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                            const Gap(10),
                            const Text(
                              'ZIESOCIAL',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                                color: AppColors.deepForest,
                              ),
                            ),
                          ],
                        ),
                        const Gap(20),
                        const Text(
                          'Mulai jurnal visual Anda.',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                            color: AppColors.primaryText,
                            height: 1.2,
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          'Daftar untuk berbagi karya fotografi, cerita harian, dan terhubung dengan komunitas.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.secondaryText,
                            height: 1.45,
                          ),
                        ),
                        const Gap(24),

                        // Form Container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_localValidationError != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.error.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: Text(
                                          _localValidationError!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(16),
                              ],

                              // Full Name
                              const Text(
                                'Nama Lengkap',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const Gap(6),
                              TextField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: Nadia Pramesti',
                                  prefixIcon: Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              const Gap(14),

                              // Username
                              const Text(
                                'Nama Pengguna (Username)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const Gap(6),
                              TextField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: nadiapramesti',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              const Gap(14),

                              // Email
                              const Text(
                                'Alamat Email',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const Gap(6),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'nama@email.com',
                                  prefixIcon: Icon(
                                    Icons.mail_outline_rounded,
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              const Gap(14),

                              // Password
                              const Text(
                                'Kata Sandi',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const Gap(6),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleRegister(),
                                decoration: InputDecoration(
                                  hintText: 'Minimal 6 karakter',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: AppColors.secondaryText,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const Gap(22),

                              // Register Button
                              SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.deepForest,
                                    foregroundColor: AppColors.pureWhite,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: AppColors.pureWhite,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Daftar Sekarang',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer to Login
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah memiliki akun? ',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginView(),
                        ),
                      );
                    },
                    child: const Text(
                      'Masuk di sini',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepForest,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.sageGreen,
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
  }
}
