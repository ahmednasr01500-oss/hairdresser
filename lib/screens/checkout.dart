import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/models.dart';
import '../services/cart.dart';
import '../services/catalog.dart';
import '../services/db.dart';
import '../services/session.dart';
import '../widgets/common.dart';
import 'address_form.dart';
import 'login.dart';
import 'order_details.dart';

/// مراجعة الطلب وتأكيده: العنوان، وقت التوصيل، طريقة الدفع، والإجمالي.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _noteCtrl = TextEditingController();

  /// `now` أو نص الوقت المطلوب. الاتنين بيتخزنوا في نفس الحقل عشان
  /// شاشة صاحب المحل تعرض جملة واحدة من غير منطق زيادة.
  String _slot = 'now';
  bool _placing = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLaterTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now().replacing(
        hour: (TimeOfDay.now().hour + 2) % 24,
      ),
      helpText: 'اختار وقت التوصيل',
    );
    if (picked == null || !mounted) return;
    setState(() => _slot = picked.format(context));
  }

  Future<void> _placeOrder() async {
    final session = Session.i;

    if (!session.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final address = session.selectedAddress;
    if (address == null) {
      final added = await Navigator.of(context).push<Address>(
        MaterialPageRoute(builder: (_) => const AddressFormScreen()),
      );
      if (added == null) return;
    }

    final finalAddress = session.selectedAddress;
    if (finalAddress == null) return;

    setState(() => _placing = true);

    final settings = Catalog.i.settings;
    final subtotal = Cart.i.subtotal;
    final discount = Cart.i.discount;
    final delivery = settings.deliveryFor(subtotal - discount);
    final total = subtotal - discount + delivery;

    try {
      final orderId = await Db.i.placeOrder(
        uid: session.uid,
        customerKey: session.customerKey,
        items: Cart.i.items,
        address: finalAddress,
        customerName: session.name,
        customerPhone: session.phone,
        subtotal: subtotal,
        delivery: delivery,
        discount: discount,
        total: total,
        slot: _slot,
        couponCode: Cart.i.coupon?.code ?? '',
        note: _noteCtrl.text.trim(),
      );

      // بنفضّي السلة بعد ما الطلب يتسجّل بنجاح بس — لو النت قطع في النص
      // العميل يلاقي طلبه زي ما هو ويعيد المحاولة.
      Cart.i.clear();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: orderId, justPlaced: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الطلب ما اتبعتش. اتأكد من النت وجرّب تاني.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: ListenableBuilder(
        listenable: Listenable.merge([Cart.i, Catalog.i, Session.i]),
        builder: (context, _) {
          final settings = Catalog.i.settings;
          final subtotal = Cart.i.subtotal;
          final discount = Cart.i.discount;
          final delivery = settings.deliveryFor(subtotal - discount);
          final total = subtotal - discount + delivery;
          final address = Session.i.selectedAddress;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    _Card(
                      title: 'عنوان التوصيل',
                      action: address == null ? 'إضافة' : 'تغيير',
                      onAction: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddressFormScreen(existing: address),
                          ),
                        );
                      },
                      child: address == null
                          ? const Text(
                              'لسه ما ضفتش عنوان توصيل',
                              style: TextStyle(color: AppColors.muted),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address.oneLine,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.6,
                                    fontSize: 13,
                                  ),
                                ),
                                if (address.details.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    address.details,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      height: 1.6,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),

                    _Card(
                      title: 'وقت التوصيل',
                      child: Row(
                        children: [
                          Expanded(
                            child: _SlotOption(
                              title: 'الآن',
                              subtitle: settings.deliveryEtaMinutes,
                              selected: _slot == 'now',
                              onTap: () => setState(() => _slot = 'now'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SlotOption(
                              title: 'لاحقًا',
                              subtitle: _slot == 'now' ? 'اختار وقت' : _slot,
                              selected: _slot != 'now',
                              onTap: _pickLaterTime,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _Card(
                      title: 'طريقة الدفع',
                      child: Column(
                        children: [
                          _PaymentOption(
                            label: 'الدفع عند الاستلام',
                            icon: Icons.payments_outlined,
                            selected: true,
                            enabled: true,
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _PaymentOption(
                            label: 'بطاقة / محفظة إلكترونية',
                            icon: Icons.credit_card,
                            selected: false,
                            enabled: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    _Card(
                      title: 'ملاحظات للطلب (اختياري)',
                      child: TextField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'مثال: الطماطم تكون ناضجة، والموز أخضر شوية',
                        ),
                      ),
                    ),

                    _Card(
                      title: 'ملخص الطلب',
                      child: Column(
                        children: [
                          ...Cart.i.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.product.name} × '
                                      '${fmt.qtyWithUnit(item.qty, item.product.unit)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    fmt.price(item.total),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
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
                      if (discount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الخصم',
                                  style: TextStyle(color: AppColors.primary)),
                              Text('- ${fmt.price(discount)}',
                                  style: const TextStyle(
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجمالي',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                          Text(
                            fmt.price(total),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: (_placing || Cart.i.isEmpty || !settings.open)
                            ? null
                            : _placeOrder,
                        child: _placing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('تأكيد الطلب'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppShape.cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const Spacer(),
              if (action != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SlotOption extends StatelessWidget {
  const _SlotOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF3F6F3),
          borderRadius: AppShape.radiusSm,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.check_circle,
                      color: Colors.white, size: 16),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.muted,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppShape.radiusSm,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.text),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ),
              if (!enabled)
                const Pill(text: 'قريبًا', color: AppColors.muted, filled: false)
              else
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.muted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
