import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// تتبّع الطلب. بيسمع على الطلب لحظيًا، فأول ما صاحب المحل يغيّر الحالة
/// من لوحة التحكم العميل يشوفها من غير ما يعمل حاجة.
class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.justPlaced = false,
  });

  final String orderId;

  /// لما ييجي من شاشة التأكيد بنعرض رسالة نجاح فوق.
  final bool justPlaced;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            if (justPlaced) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppShell(initialIndex: 1)),
                (_) => false,
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: StreamBuilder<ShopOrder?>(
        stream: Db.i.watchOrder(orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.leaf),
            );
          }

          final order = snap.data;
          if (order == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'الطلب ده مش موجود',
              message: 'يمكن يكون اتشال. كلّمنا لو محتاج مساعدة.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              if (justPlaced) ...[
                const _SuccessBanner(),
                const SizedBox(height: 16),
              ],

              _Block(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'طلب #${order.number}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                        const Spacer(),
                        statusPill(order.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fmt.orderDate(order.createdAt),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              if (order.status == OrderStatus.cancelled)
                InfoBar(
                  text: order.cancelReason.isEmpty
                      ? 'الطلب ده اتلغى'
                      : 'الطلب اتلغى: ${order.cancelReason}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.danger,
                )
              else
                _Block(
                  title: 'حالة الطلب',
                  child: _Timeline(order: order),
                ),

              _Block(
                title: 'الأصناف',
                child: Column(
                  children: order.lines
                      .map((line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                AppImage(
                                  source: line.image,
                                  size: 44,
                                  fit: BoxFit.contain,
                                  radius: BorderRadius.circular(8),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        fmt.qtyWithUnit(line.qty, line.unit),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  fmt.price(line.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

              _Block(
                title: 'الحساب',
                child: Column(
                  children: [
                    _row('المجموع الفرعي', fmt.price(order.subtotal)),
                    if (order.discount > 0)
                      _row('الخصم', '- ${fmt.price(order.discount)}',
                          color: AppColors.primary),
                    _row(
                      'التوصيل',
                      order.delivery == 0 ? 'مجاني' : fmt.price(order.delivery),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _row('الإجمالي', fmt.price(order.total), bold: true),
                    const SizedBox(height: 8),
                    _row('طريقة الدفع', 'الدفع عند الاستلام'),
                  ],
                ),
              ),

              _Block(
                title: 'التوصيل',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.addressText,
                      style: const TextStyle(height: 1.7, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.slot == 'now'
                          ? 'التوصيل: في أقرب وقت'
                          : 'التوصيل: الساعة ${order.slot}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    if (order.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ملاحظة: ${order.note}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _callShop(context),
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: const Text('اتصل بالمحل'),
              ),

              if (order.canCancel) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _confirmCancel(context, order),
                  child: const Text(
                    'إلغاء الطلب',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 16 : 13.5,
      color: color ?? (bold ? AppColors.text : AppColors.muted),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  Future<void> _callShop(BuildContext context) async {
    final uri = Uri.parse('tel:${Shop.phoneOrders}');
    if (!await launchUrl(uri) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مقدرناش نفتح التليفون')),
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context, ShopOrder order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('إلغاء الطلب؟'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ممكن تقولنا السبب عشان نتحسّن؟'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: 'السبب (اختياري)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('رجوع'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('تأكيد الإلغاء',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );

    if (reason == null) return;
    await Db.i.cancelOrder(order.id, reason);
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: AppShape.radius,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.leaf, AppColors.primary],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 40),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلبك وصلنا 🌿',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'هنجهّزه حالًا ونكلّمك لو احتجنا أي حاجة',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppShape.cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final steps = OrderStatus.timeline;
    final currentIndex = steps.indexOf(order.status);

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final done = currentIndex >= i;
        final isLast = i == steps.length - 1;
        final at = order.statusHistory[step.key];

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: done ? AppColors.primary : const Color(0xFFEFF4EF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle,
                      size: done ? 15 : 8,
                      color: done ? Colors.white : AppColors.muted,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: currentIndex > i
                            ? AppColors.primary
                            : const Color(0xFFEFF4EF),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontWeight:
                              done ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14,
                          color: done ? AppColors.text : AppColors.muted,
                        ),
                      ),
                      if (at != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          fmt.clockOnly(at),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
