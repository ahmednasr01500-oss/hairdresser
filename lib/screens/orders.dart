import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/models.dart';
import '../services/db.dart';
import '../services/session.dart';
import '../widgets/common.dart';
import 'login.dart';
import 'order_details.dart';
import 'shell.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: ListenableBuilder(
        listenable: Session.i,
        builder: (context, _) {
          if (!Session.i.isLoggedIn) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'سجّل الدخول عشان تشوف طلباتك',
              message: 'دقيقة واحدة بس — اسمك ورقمك وخلاص',
              actionLabel: 'تسجيل الدخول',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            );
          }

          return StreamBuilder<List<ShopOrder>>(
            stream: Db.i.myOrders(Session.i.customerKey),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.leaf),
                );
              }

              final orders = snap.data ?? const <ShopOrder>[];
              if (orders.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'لسه ما طلبتش حاجة',
                  message: 'أول طلب ليك على بُعد كام ضغطة',
                  actionLabel: 'تسوّق دلوقتي',
                  onAction: () => AppShell.of(context)?.goHome(),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: orders.length,
                itemBuilder: (context, i) => _OrderCard(order: orders[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppShape.radius,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: order.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppShape.cardDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'طلب #${order.number}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                statusPill(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fmt.orderDate(order.createdAt),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              order.lines.map((l) => l.name).take(3).join('، ') +
                  (order.lines.length > 3
                      ? ' و${order.lines.length - 3} أصناف تانية'
                      : ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Text(
                  '${order.lines.length} صنف',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  fmt.price(order.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
