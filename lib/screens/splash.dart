import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/session.dart';
import '../widgets/brand.dart';
import 'login.dart';
import 'shell.dart';

/// شاشة البداية. بتستنى ثانية ونص كحد أقصى وبعدين بتوجّه العميل:
/// لو عنده رقم متسجّل يدخل على طول، لو لأ يروح لشاشة الترحيب.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), _go);
  }

  void _go() {
    if (!mounted) return;
    final next = Session.i.isLoggedIn
        ? const AppShell()
        : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandLogo(size: 160),
            const SizedBox(height: 28),
            Text(
              Shop.slogan,
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.leaf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
