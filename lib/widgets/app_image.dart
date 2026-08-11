import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// صورة صنف أو قسم.
///
/// لوحة التحكم بتحفظ الصورة إما كرابط عادي أو كـ data URL مضغوطة جوه
/// قاعدة البيانات (عشان Firebase Storage مش متاح في الباقة المجانية).
/// الويدجت دي بتتعامل مع الحالتين، وبتعرض أيقونة بديلة لو مفيش صورة.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.size,
    this.fit = BoxFit.cover,
    this.radius,
  });

  final String source;
  final double? size;
  final BoxFit fit;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final child = _build();
    if (radius == null) return child;
    return ClipRRect(borderRadius: radius!, child: child);
  }

  Widget _build() {
    final src = source.trim();

    if (src.isEmpty) return _placeholder();

    if (src.startsWith('data:image')) {
      final bytes = _decodeDataUrl(src);
      if (bytes == null) return _placeholder();
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    if (src.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: src,
        width: size,
        height: size,
        fit: fit,
        placeholder: (_, _) => _skeleton(),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }

    return _placeholder();
  }

  static Uint8List? _decodeDataUrl(String src) {
    try {
      final comma = src.indexOf(',');
      if (comma < 0) return null;
      return base64Decode(src.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _skeleton() => Container(
        width: size,
        height: size,
        color: const Color(0xFFEFF4EF),
      );

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: const Color(0xFFEFF4EF),
        alignment: Alignment.center,
        child: Icon(
          Icons.eco_outlined,
          color: AppColors.leaf.withValues(alpha: 0.7),
          size: (size ?? 48) * 0.4,
        ),
      );
}
