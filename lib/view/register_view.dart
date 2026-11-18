import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/view/login_view.dart';
import 'package:ziesocial/viewmodel/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Palet Warna Sesuai Konfigurasi Tailwind Referensi
  static const Color _surface = Color(0xFFF9F9FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color _surfaceContainerHigh = Color(0xFFE1E8FD);
  static const Color _onSurface = Color(0xFF141B2B);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _primary = Color(0xFF3525CD);
  static const Color _primaryContainer = Color(0xFF4F46E5);
  static const Color _secondary = Color(0xFFB90538);
  static const Color _tertiary = Color(0xFF571AC0);
  static const Color _error = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _agreedToTerms = true;
  String? _localValidationError;

  @override
  void initState() {
    super.initState();
    for (final node in [
      _nameFocus,
      _usernameFocus,
      _emailFocus,
      _passwordFocus,
    ]) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
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
        _localValidationError =
            'Kata sandi harus terdiri dari minimal 6 karakter.';
      });
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _localValidationError =
            'Kamu harus menyetujui Ketentuan Layanan & Kebijakan Privasi.';
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
                'Berhasil Bergabung! Silakan masuk.',
          ),
          backgroundColor: _primary,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    } else {
      final error = context.read<RegisterViewModel>().errorMessage;
      setState(() {
        _localValidationError =
            error ?? 'Registrasi gagal. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RegisterViewModel>().isLoading;

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Brand Presentation Header
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
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
                  const Gap(4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: const Text(
                      'Daftar dan bagikan visual terbaikmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        height: 20 / 14,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Gap(20),

                  // 2. Main Signup Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _onSurface.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                          const Gap(14),
                        ],

                        // Field 1: Nama Lengkap
                        _buildFieldLabel(
                          icon: Icons.person_outline_rounded,
                          label: 'Nama Lengkap',
                        ),
                        const Gap(6),
                        _buildInputContainer(
                          isFocused: _nameFocus.hasFocus,
                          child: TextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: _onSurface,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'misal: Alex Wijaya',
                            ),
                          ),
                        ),
                        const Gap(14),

                        // Field 2: Nama Pengguna (Username)
                        _buildFieldLabel(
                          icon: Icons.alternate_email_rounded,
                          label: 'Username',
                        ),
                        const Gap(6),
                        _buildInputContainer(
                          isFocused: _usernameFocus.hasFocus,
                          child: TextField(
                            controller: _usernameController,
                            focusNode: _usernameFocus,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: _onSurface,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'misal: alex.visuals',
                            ),
                          ),
                        ),
                        const Gap(14),

                        // Field 3: Alamat Email
                        _buildFieldLabel(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                        ),
                        const Gap(6),
                        _buildInputContainer(
                          isFocused: _emailFocus.hasFocus,
                          child: TextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: _onSurface,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'nama@email.com',
                            ),
                          ),
                        ),
                        const Gap(14),

                        // Field 4: Kata Sandi
                        _buildFieldLabel(
                          icon: Icons.lock_outline_rounded,
                          label: 'Password',
                        ),
                        const Gap(6),
                        _buildInputContainer(
                          isFocused: _passwordFocus.hasFocus,
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleRegister(),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: _onSurface,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'Minimal 8 karakter',
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
                            ),
                          ),
                        ),
                        const Gap(16),

                        // Terms Consent Checkbox
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreedToTerms = !_agreedToTerms;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _agreedToTerms
                                        ? _primary
                                        : _surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _agreedToTerms
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              const Gap(10),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      height: 1.5,
                                      color: _onSurfaceVariant,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'Dengan mendaftar, kamu menyetujui ',
                                      ),
                                      TextSpan(
                                        text: 'Ketentuan Layanan',
                                        style: TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Kebijakan Privasi',
                                        style: TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' Ziesocial.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(20),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? _primary.withValues(alpha: 0.85)
                                  : _primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.22),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isLoading ? null : _handleRegister,
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: isLoading
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 17,
                                              height: 17,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Gap(10),
                                            Text(
                                              'Mendaftarkan...',
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
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
                                              'Daftar Sekarang',
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                fontSize: 14,
                                                height: 20 / 14,
                                                letterSpacing: 0.14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Gap(8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),

                  // 3. Already Have Account Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
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
                                builder: (context) => const LoginView(),
                              ),
                            );
                          },
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: _primary,
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
    );
  }

  Widget _buildFieldLabel({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: _outline,
        ),
        const Gap(6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.24,
            fontWeight: FontWeight.w600,
            color: _onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInputContainer({
    required bool isFocused,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: isFocused ? _surfaceContainerLowest : _surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 14,
        color: _outline.withValues(alpha: 0.7),
      ),
      suffixIcon: suffixIcon,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const Gap(6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 10,
            height: 14 / 10,
            fontWeight: FontWeight.w700,
            color: _onSurfaceVariant.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
