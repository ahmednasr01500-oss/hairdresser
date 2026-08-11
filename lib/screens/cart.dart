import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/models.dart';
import '../services/cart.dart';
import '../services/catalog.dart';
import '../services/db.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'checkout.dart';
import 'shell.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();
  bool _checkingCoupon = false;
  String _couponError = '';

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _checkingCoupon = true;
      _couponError = '';
    });

    final coupon = await Db.i.findCoupon(code);
    if (!mounted) return;

    setState(() {
      _checkingCoupon = false;
      if (coupon == null || !coupon.active) {
        _couponError = 'الكود ده مش موجود أو انتهى';
        Cart.i.applyCoupon(null);
      } else if (Cart.i.subtotal < coupon.minOrder) {
        _couponError =
            'الكود ده شغّال على طلب من ${fmt.price(coupon.minOrder)} وفوق';
        Cart.i.applyCoupon(null);
      } else {
        Cart.i.applyCoupon(coupon);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
        actions: [
          ListenableBuilder(
            listenable: Cart.i,
            builder: (context, _) => Cart.i.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _confirmClear(context),
                    child: const Text(
                      'تفريغ',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([Cart.i, Catalog.i]),
        builder: (context, _) {
          if (Cart.i.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'سلتك لسه فاضية',
              message: 'اختار اللي نفسك فيه من الخضار والفاكهة الطازجة',
              actionLabel: 'تسوّق دلوقتي',
              onAction: () => AppShell.of(context)?.goHome(),
            );
          }

          final settings = Catalog.i.settings;
          final subtotal = Cart.i.subtotal;
          final discount = Cart.i.discount;
          final delivery = settings.deliveryFor(subtotal - discount);
          final total = subtotal - discount + delivery;
          final belowMin = settings.minOrder > 0 && subtotal < settings.minOrder;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  children: [
                    ...Cart.i.items.map((item) => _CartRow(item: item)),
                    const SizedBox(height: 12),
                    _CouponField(
                      controller: _couponCtrl,
                      busy: _checkingCoupon,
                      error: _couponError,
                      applied: Cart.i.coupon?.code ?? '',
                      onApply: _applyCoupon,
                      onClear: () {
                        _couponCtrl.clear();
                        Cart.i.applyCoupon(null);
                        setState(() => _couponError = '');
                      },
                    ),
                  ],
                ),
              ),

              _Summary(
                subtotal: subtotal,
                discount: discount,
                delivery: delivery,
                total: total,
                belowMin: belowMin,
                minOrder: settings.minOrder,
                shopOpen: settings.open,
                closedMessage: settings.closedMessage,
                onCheckout: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفريغ السلة؟'),
        content: const Text('هيتشال كل اللي فيها.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تفريغ',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) Cart.i.clear();
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: AppShape.cardDeco,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.muted, size: 22),
            onPressed: () => Cart.i.remove(p.id),
          ),
          QtyStepper(
            qty: item.qty,
            compact: true,
            onIncrement: () => Cart.i.increment(p),
            onDecrement: () => Cart.i.decrement(p),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fmt.qtyWithUnit(item.qty, p.unit),
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  fmt.price(item.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AppImage(
            source: p.image,
            size: 58,
            fit: BoxFit.contain,
            radius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}

class _CouponField extends StatelessWidget {
  const _CouponField({
    required this.controller,
    required this.busy,
    required this.error,
    required this.applied,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool busy;
  final String error;
  final String applied;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (applied.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppShape.radiusSm,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'كود الخصم "$applied" اتفعّل',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('إلغاء')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'أدخل كود الخصم',
            prefixIcon: const Icon(Icons.local_offer_outlined),
            suffixIcon: TextButton(
              onPressed: busy ? null : onApply,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('تفعيل'),
            ),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: Text(
              error,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.total,
    required this.belowMin,
    required this.minOrder,
    required this.shopOpen,
    required this.closedMessage,
    required this.onCheckout,
  });

  final double subtotal;
  final double discount;
  final double delivery;
  final double total;
  final bool belowMin;
  final double minOrder;
  final bool shopOpen;
  final String closedMessage;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final blocked = belowMin || !shopOpen;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppShape.r),
        ),
        boxShadow: AppShape.soft,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('المجموع الفرعي', subtotal),
            if (discount > 0) _row('الخصم', -discount, color: AppColors.primary),
            _row(
              'التوصيل',
              delivery,
              trailingText: delivery == 0 ? 'مجاني' : null,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            _row('الإجمالي', total, bold: true),
            const SizedBox(height: 14),

            if (!shopOpen)
              InfoBar(
                text: closedMessage,
                icon: Icons.storefront_outlined,
                color: AppColors.warn,
              )
            else if (belowMin)
              InfoBar(
                text: 'الحد الأدنى للطلب ${fmt.price(minOrder)} — '
                    'ضيف بـ ${fmt.price(minOrder - subtotal)} كمان',
                icon: Icons.info_outline,
                color: AppColors.warn,
              ),
            if (blocked) const SizedBox(height: 4),

            ElevatedButton(
              onPressed: blocked ? null : onCheckout,
              child: const Text('إتمام الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    double value, {
    bool bold = false,
    Color? color,
    String? trailingText,
  }) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 17 : 14,
      color: color ?? (bold ? AppColors.text : AppColors.muted),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(trailingText ?? fmt.price(value), style: style),
        ],
      ),
    );
  }
}
