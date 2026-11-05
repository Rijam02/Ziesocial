import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/view/main_navigation_view.dart';
import 'package:ziesocial/view/register_view.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';
import 'package:ziesocial/viewmodel/profile_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localValidationError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _localValidationError = 'Mohon masukkan email dan kata sandi Anda.';
      });
      return;
    }

    setState(() => _localValidationError = null);

    final success = await context.read<LoginViewModel>().login(
          email: email,
          password: password,
        );

    if (!mounted) return;

    if (success) {
      context.read<ProfileViewModel>().clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationView()),
        (route) => false,
      );
    } else {
      final error = context.read<LoginViewModel>().errorMessage;
      setState(() {
        _localValidationError =
            error ?? 'Gagal masuk. Periksa kembali email dan kata sandi Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<LoginViewModel>().isLoading;

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
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Editorial Eyebrow & Brand Header
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
                        const Gap(24),
                        const Text(
                          'Selamat datang kembali.',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                            color: AppColors.primaryText,
                            height: 1.2,
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          'Masuk ke akun ZieSocial Anda untuk melihat cerita dan jurnal visual terbaru.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText,
                            height: 1.45,
                          ),
                        ),
                        const Gap(28),

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

                              // Email Label & Input
                              const Text(
                                'Email',
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryText,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'nama@email.com',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                              const Gap(16),

                              // Password Label & Input
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
                                onSubmitted: (_) => _handleLogin(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryText,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan kata sandi',
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

                              // Submit Button
                              SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
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
                                          'Masuk ke Akun',
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

            // Bottom Bar to Register
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
                    'Belum memiliki akun ZieSocial? ',
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
                          builder: (context) => const RegisterView(),
                        ),
                      );
                    },
                    child: const Text(
                      'Buat Akun',
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
