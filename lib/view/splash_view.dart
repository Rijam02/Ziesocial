import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:ziesocial/core/app_theme.dart';
import 'package:ziesocial/view/login_view.dart';
import 'package:ziesocial/view/main_navigation_view.dart';
import 'package:ziesocial/viewmodel/login_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();

    _navigationTimer = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      final isLoggedIn = context.read<LoginViewModel>().isLoggedIn;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) =>
              isLoggedIn ? const MainNavigationView() : const LoginView(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              children: [
                // Top Editorial Index Mark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ZIESOCIAL JOURNAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                        color: AppColors.secondaryText.withValues(alpha: 0.9),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 1,
                      color: AppColors.sageGreen,
                    ),
                  ],
                ),
                const Spacer(),

                // Center Editorial Brand Identity
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Gap(20),
                    const Text(
                      'ZieSocial',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const Gap(8),
                    const Text(
                      'Ruang berbagi cerita & perspektif visual',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.secondaryText,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Subtle Minimal Loading Bar
                Column(
                  children: [
                    SizedBox(
                      width: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: AppColors.mistGray,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.sageGreen,
                          ),
                        ),
                      ),
                    ),
                    const Gap(14),
                    const Text(
                      'EDISI DIGITAL • MODERN SOCIAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

