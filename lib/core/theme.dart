import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان الهوية مأخوذة من اللوجو والتصميم:
/// أخضر غامق للأزرار، أخضر اللوجو الفاتح للتمييز، وخلفية خضراء باهتة جدًا.
class AppColors {
  static const primary = Color(0xFF1F7A3B);
  static const primaryDark = Color(0xFF145C2B);
  static const leaf = Color(0xFF8CC63F);
  static const bg = Color(0xFFF4FAF3);
  static const card = Colors.white;
  static const text = Color(0xFF1B2B22);
  static const muted = Color(0xFF7B8C81);
  static const line = Color(0xFFE6EFE7);
  static const danger = Color(0xFFD1493F);
  static const warn = Color(0xFFE0A02A);
}

/// حواف وظلال موحّدة عشان كل الشاشات تبان من نفس العائلة.
class AppShape {
  static const r = 18.0;
  static BorderRadius get radius => BorderRadius.circular(r);
  static BorderRadius get radiusSm => BorderRadius.circular(12);

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration get cardDeco => BoxDecoration(
        color: AppColors.card,
        borderRadius: radius,
        boxShadow: soft,
      );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.card,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.text,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: AppShape.radiusSm),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: AppShape.radiusSm),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F6F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.cairo(color: AppColors.muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: AppShape.radiusSm,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppShape.radiusSm,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppShape.radiusSm,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primaryDark,
      contentTextStyle: GoogleFonts.cairo(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppShape.radiusSm),
    ),
  );
}
