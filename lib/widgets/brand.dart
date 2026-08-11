import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// لوجو المحل.
///
/// بيدوّر على `assets/images/logo.png` الأول. لو الملف لسه مش موجود
/// بيرسم بديل بنفس ألوان الهوية عشان التطبيق يفضل شغّال — بس البديل
/// ده مش المفروض يوصل للعميل، راجع SETUP.md خطوة (٣).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 120, this.showTagline = true});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _Fallback(size: size, tagline: showTagline),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size, required this.tagline});

  final double size;
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: size * 0.55, color: AppColors.leaf),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              Shop.name,
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.w900,
                color: AppColors.leaf,
              ),
            ),
          ),
          if (tagline)
            FittedBox(
              child: Text(
                Shop.tagline,
                style: TextStyle(
                  fontSize: size * 0.11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.leaf.withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
