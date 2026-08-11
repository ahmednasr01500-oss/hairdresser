import 'package:flutter/material.dart';

import '../core/format.dart' as fmt;
import '../core/theme.dart';
import '../models/models.dart';
import '../services/cart.dart';
import '../screens/product_details.dart';
import 'app_image.dart';
import 'common.dart';

/// كارت الصنف في الشبكة.
///
/// الزرار الأخضر بيتحوّل لعداد كمية بمجرد ما العميل يضيف الصنف — كده
/// يقدر يزوّد ويقلّل من مكانه من غير ما يفتح صفحة الصنف أو السلة.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Cart.i,
      builder: (context, _) {
        final qty = Cart.i.qtyOf(product.id);
        final disabled = !product.available;

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          ),
          child: Opacity(
            opacity: disabled ? 0.55 : 1,
            child: Container(
              decoration: AppShape.cardDeco,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AppImage(
                            source: product.image,
                            fit: BoxFit.contain,
                            radius: BorderRadius.circular(12),
                          ),
                        ),
                        if (product.onSale)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Pill(
                              text: 'خصم ${product.discountPercent}%',
                              color: AppColors.danger,
                            ),
                          ),
                        if (disabled)
                          const Positioned(
                            top: 0,
                            left: 0,
                            child: Pill(
                              text: 'خلص',
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.qtyWithUnit(product.step, product.unit),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.onSale)
                              Text(
                                fmt.priceNoCurrency(product.oldPrice),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              fmt.price(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!disabled)
                        qty > 0
                            ? QtyStepper(
                                qty: qty,
                                compact: true,
                                onIncrement: () => Cart.i.increment(product),
                                onDecrement: () => Cart.i.decrement(product),
                              )
                            : _AddButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Cart.i.add(product),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// نفس الكارت بس أفقي — بيتستخدم في نتايج البحث وفي "الأكثر طلبًا"
/// لما يكون العرض ضيق.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Cart.i,
      builder: (context, _) {
        final qty = Cart.i.qtyOf(product.id);
        return InkWell(
          borderRadius: AppShape.radius,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            padding: const EdgeInsets.all(10),
            decoration: AppShape.cardDeco,
            child: Row(
              children: [
                AppImage(
                  source: product.image,
                  size: 68,
                  fit: BoxFit.contain,
                  radius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.qtyWithUnit(product.step, product.unit),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fmt.price(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!product.available)
                  const Pill(text: 'خلص', color: AppColors.muted)
                else if (qty > 0)
                  QtyStepper(
                    qty: qty,
                    compact: true,
                    onIncrement: () => Cart.i.increment(product),
                    onDecrement: () => Cart.i.decrement(product),
                  )
                else
                  _AddButton(product: product),
              ],
            ),
          ),
        );
      },
    );
  }
}
