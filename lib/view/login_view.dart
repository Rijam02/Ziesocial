import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
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
  // Palet Warna Sesuai Konfigurasi Tailwind Referensi
  static const Color _surface = Color(0xFFF9F9FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color _surfaceContainerHighest = Color(0xFFDCE2F7);
  static const Color _onSurface = Color(0xFF141B2B);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _primary = Color(0xFF3525CD);
  static const Color _primaryContainer = Color(0xFF4F46E5);
  static const Color _primaryFixed = Color(0xFFE2DFFF);
  static const Color _secondary = Color(0xFFB90538);
  static const Color _tertiary = Color(0xFF571AC0);
  static const Color _tertiaryFixedDim = Color(0xFFD0BCFF);
  static const Color _error = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);

  static const String _logoUrl =
      'https://lh3.googleusercontent.com/aida/ALJJyrAGz0ngow3as-1-re5ci2YrUi5fcQVaSwLyJuphJXXcEeZCsLYn1KWDiOWWi8n8QFxhfWPHifPhM973z39xjzRvUFc70o1PmKvKzdcfe7O0PHkczjocI9iCpf5giaF2_R9nULtM_F0XtZQmX9kjfBpU_QXPK2uhne2dmPzIiMv-LnTDmjV4H3WlH44_P8wQGggIjaqhrgY7_R4h43bMywuhZCS1eY1I9TgCpjXZi7BayQ';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  String? _localValidationError;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
      }
    });
    _passwordFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
      backgroundColor: _surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Dynamic Micro-Ambient Background Glow (Top-Left)
            Positioned(
              top: -48,
              left: -64,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                  child: Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryFixed.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),

            // Dynamic Micro-Ambient Background Glow (Top-Right)
            Positioned(
              top: -40,
              right: -64,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                  child: Container(
                    width: 208,
                    height: 208,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tertiaryFixedDim.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
            ),

            // Main Scrollable Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Centered Brand Presentation
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft pulsing subtle aura ring
                          ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _primary.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _onSurface.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.network(
                              _logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_primary, _primaryContainer],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Z',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      const Text(
                        'Ziesocial',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 28,
                          height: 36 / 28,
                          letterSpacing: -0.7,
                          fontWeight: FontWeight.w700,
                          color: _onSurface,
                        ),
                      ),
                      const Gap(6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Share your visual world',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: _onSurfaceVariant,
                            ),
                          ),
                          const Gap(6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const Gap(30),

                      // Editorial Gallery Mood Teaser Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),

                          const Gap(8),
                        
                        ],
                      ),
                      const Gap(28),

                      // Error Validation Banner (jika ada error login)
                      if (_localValidationError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: _errorContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _error.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: _error,
                              ),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  _localValidationError!,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    color: _error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(16),
                      ],

                      // 2. Form Section
                      // Email Address Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Email',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                height: 16 / 12,
                                letterSpacing: 0.24,
                                fontWeight: FontWeight.w600,
                                color: _onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Gap(6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isEmailFocused
                                  ? _surfaceContainerLow
                                  : _surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _onSurface.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                color: _onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'nama@email.com',
                                hintStyle: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  color: _outline.withValues(alpha: 0.7),
                                ),
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 20,
                                  color: _outline,
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                height: 16 / 12,
                                letterSpacing: 0.24,
                                fontWeight: FontWeight.w600,
                                color: _onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Gap(6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isPasswordFocused
                                  ? _surfaceContainerLow
                                  : _surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _onSurface.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                color: _onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  color: _outline.withValues(alpha: 0.7),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: _outline,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: _outline,
                                  ),
                                  tooltip:
                                      'Tampilkan atau sembunyikan kata sandi',
                                ),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Silakan hubungi administrator untuk mengatur ulang kata sandi.',
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Lupa kata sandi?',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                height: 16 / 12,
                                letterSpacing: 0.24,
                                fontWeight: FontWeight.w600,
                                color: _primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Gap(20),

                      // 3. Primary Login Button (Gradient from primary to primary-container)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLoading
                                  ? [
                                      _primary.withValues(alpha: 0.85),
                                      _primaryContainer.withValues(alpha: 0.85),
                                    ]
                                  : const [_primary, _primaryContainer],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isLoading ? null : _handleLogin,
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: isLoading
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Gap(10),
                                          Text(
                                            'Memverifikasi...',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Masuk',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 14,
                                              height: 20 / 14,
                                              letterSpacing: 0.3,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Gap(8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Gap(32),

                      // 5. Footer Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              height: 20 / 14,
                              color: _onSurfaceVariant,
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
                              'Daftar sekarang',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                height: 16 / 12,
                                letterSpacing: 0.24,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(24),

                      // Gallery Community Micro-Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: _onSurface.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: _tertiary,
                            ),
                            Gap(6),
                            Text(
                              'Bergabung dengan 120k+ fotografer',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10,
                                height: 14 / 10,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w600,
                                color: _onSurfaceVariant,
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
          ],
        ),
      ),
    );
  }
}
