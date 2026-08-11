import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/models.dart';
import '../services/cart.dart';
import '../services/catalog.dart';
import '../services/session.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// صفحة الصنف: صورة كبيرة، السعر، وصف، واختيار الكمية قبل الإضافة.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late double _qty = widget.product.step;

  /// بنقرأ الصنف من الكتالوج كل مرة مش من الـ widget، عشان لو صاحب المحل
  /// غيّر السعر أو وقّف الصنف والعميل فاتح الصفحة، يشوف التغيير فورًا.
  Product get _product => Catalog.i.byId(widget.product.id) ?? widget.product;

  void _addToCart() {
    // بنمسك الـ navigator والـ messenger والهيكل قبل ما نقفل الصفحة —
    // بعد الـ pop الـ context بتاعها بيبقى ميت وأي بحث فيه بيفشل.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final shell = AppShell.of(context);

    Cart.i.setQty(_product, _qty);
    final name = _product.name;
    navigator.pop();

    messenger.showSnackBar(
      SnackBar(
        content: Text('$name اتضاف للسلة'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'شوف السلة',
          textColor: AppColors.leaf,
          onPressed: () {
            navigator.popUntil((r) => r.isFirst);
            shell?.goCart();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Catalog.i, Session.i]),
      builder: (context, _) {
        final p = _product;
        final fav = Session.i.isFavorite(p.id);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  color: fav ? AppColors.danger : AppColors.text,
                ),
                onPressed: () => Session.i.toggleFavorite(p.id),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              SizedBox(
                height: 260,
                child: AppImage(
                  source: p.image,
                  fit: BoxFit.contain,
                  radius: AppShape.radius,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fmt.qtyWithUnit(p.step, p.unit)} تقريبًا',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.rating > 0)
                    Row(
                      children: [
                        Text(
                          fmt.qty(p.rating),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star,
                            color: Color(0xFFF5A623), size: 20),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.price(p.price),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  if (p.onSale) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        fmt.price(p.oldPrice),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Pill(
                        text: 'وفّر ${p.discountPercent}%',
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),

              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  p.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.9,
                    fontSize: 14,
                  ),
                ),
              ],

              if (p.tags.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.tags
                      .map((t) => Pill(text: t, filled: false))
                      .toList(),
                ),
              ],

              const SizedBox(height: 28),

              if (!p.available)
                const InfoBar(
                  text: 'الصنف ده خلص دلوقتي — هيرجع تاني قريب',
                  icon: Icons.info_outline,
                  color: AppColors.warn,
                )
              else
                Row(
                  children: [
                    const Text(
                      'الكمية',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    QtyStepper(
                      qty: _qty,
                      onIncrement: () => setState(() => _qty += p.step),
                      onDecrement: () => setState(() {
                        final next = _qty - p.step;
                        _qty = next < p.step ? p.step : next;
                      }),
                    ),
                  ],
                ),
            ],
          ),
          bottomNavigationBar: p.available
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    label: Text(
                      'إضافة للسلة  •  ${fmt.price(p.price * _qty)}',
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
