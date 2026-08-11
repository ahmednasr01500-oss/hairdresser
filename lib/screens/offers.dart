import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/catalog.dart';
import '../services/session.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'shell.dart';

/// تبويب العروض: الأصناف اللي عليها خصم، وتحته المفضّلة بتاعة العميل.
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العروض والمفضّلة')),
      body: ListenableBuilder(
        listenable: Listenable.merge([Catalog.i, Session.i]),
        builder: (context, _) {
          final onSale = Catalog.i.onSale;
          final favorites = Catalog.i.products
              .where((p) => Session.i.isFavorite(p.id))
              .toList();

          if (onSale.isEmpty && favorites.isEmpty) {
            return EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'مفيش عروض دلوقتي',
              message:
                  'تابعنا — بننزّل عروض جديدة كل فترة على الخضار والفاكهة',
              actionLabel: 'تصفّح المنتجات',
              onAction: () => AppShell.of(context)?.goHome(),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (onSale.isNotEmpty) ...[
                const SectionHeader(title: 'عروض النهاردة', emoji: '🔥'),
                _Grid(products: onSale),
              ],
              if (favorites.isNotEmpty) ...[
                const SectionHeader(title: 'المفضّلة', emoji: '❤️'),
                _Grid(products: favorites),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => ProductCard(product: products[i]),
    );
  }
}
