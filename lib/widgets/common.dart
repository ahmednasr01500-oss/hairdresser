import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/format.dart' as fmt;
import '../core/theme.dart';

/// عنوان قسم في الشاشة الرئيسية، مع رابط "عرض الكل" اختياري.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.emoji = '',
    this.onSeeAll,
  });

  final String title;
  final String emoji;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Text(
            emoji.isEmpty ? title : '$title $emoji',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Row(
                children: [
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_left, size: 18, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// أزرار الزيادة والنقصان. بتشتغل بوحدة الصنف (كيلو كامل، نص كيلو، حزمة…)
/// مش بواحد ثابت، لأن الخضار مش كله بيتباع بالعدد.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  final double qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 4.0 : 8.0;
    final iconSize = compact ? 18.0 : 22.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F3),
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
      ),
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onDecrement, iconSize),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
            child: Text(
              fmt.qty(qty),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 14 : 17,
              ),
            ),
          ),
          _btn(Icons.add, onIncrement, iconSize),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, double size) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: size, color: AppColors.primary),
        ),
      );
}

/// شاشة فاضية: أيقونة + سطرين + زرار اختياري. بتتستخدم في السلة والطلبات
/// ونتايج البحث عشان الفراغ يبقى مفهوم مش مقلق.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.leaf.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.6),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// شريط أخضر صغير للعروض والملاحظات.
class InfoBar extends StatelessWidget {
  const InfoBar({
    super.key,
    required this.text,
    this.icon = Icons.campaign_outlined,
    this.color = AppColors.primary,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppShape.radiusSm,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة حالة الطلب بلون معبّر: أخضر للمُسلَّم، رمادي للملغي، أزرق وهو في
/// الطريق، وأصفر لأي حالة لسه شغّالة.
Widget statusPill(OrderStatus status) {
  final color = switch (status) {
    OrderStatus.delivered => AppColors.primary,
    OrderStatus.cancelled => AppColors.muted,
    OrderStatus.onWay => const Color(0xFF2D8CD8),
    _ => AppColors.warn,
  };
  return Pill(text: status.label, color: color, filled: false);
}

/// شارة صغيرة (خصم، غير متاح…).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.color = AppColors.primary,
    this.filled = true,
  });

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
