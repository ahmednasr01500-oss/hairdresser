import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart' as m;
import '../services/catalog.dart';
import '../services/session.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import 'address_form.dart';
import 'category_products.dart';
import 'search.dart';
import 'shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([Catalog.i, Session.i]),
          builder: (context, _) {
            final c = Catalog.i;

            if (!c.ready) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.leaf),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  await Future.delayed(const Duration(milliseconds: 600)),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  const _Greeting(),
                  const _SearchBar(),
                  const _DeliveryTo(),

                  if (!c.settings.open)
                    InfoBar(
                      text: c.settings.closedMessage,
                      icon: Icons.storefront_outlined,
                      color: AppColors.warn,
                    ),
                  if (c.settings.announcement.isNotEmpty)
                    InfoBar(text: c.settings.announcement),

                  const SizedBox(height: 12),
                  _Banners(banners: c.banners),

                  if (c.categories.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _Categories(categories: c.categories),
                  ],

                  if (c.featured.isNotEmpty) ...[
                    SectionHeader(
                      title: 'الأكثر طلبًا',
                      emoji: '🌿',
                      onSeeAll: () => AppShell.of(context)?.goTo(3),
                    ),
                    _HorizontalProducts(products: c.featured),
                  ],

                  if (c.onSale.isNotEmpty) ...[
                    SectionHeader(
                      title: 'عروض النهاردة',
                      emoji: '🔥',
                      onSeeAll: () => AppShell.of(context)?.goTo(3),
                    ),
                    _HorizontalProducts(products: c.onSale),
                  ],

                  const SizedBox(height: 24),
                  const _DeliveryPromo(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final name = Session.i.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'مرحبًا بك 👋' : 'مرحبًا $name 👋',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '${Shop.name} — ${Shop.tagline}',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppShape.soft,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, size: 22),
              color: AppColors.text,
              onPressed: () => AppShell.of(context)?.goTo(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppShape.radiusSm,
            boxShadow: AppShape.soft,
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.muted, size: 22),
              SizedBox(width: 10),
              Text(
                'ابحث عن منتج…',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryTo extends StatelessWidget {
  const _DeliveryTo();

  @override
  Widget build(BuildContext context) {
    final address = Session.i.selectedAddress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: InkWell(
        borderRadius: AppShape.radiusSm,
        onTap: () async {
          if (address == null) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddressFormScreen()),
            );
          } else {
            AppShell.of(context)?.goTo(4);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppShape.radiusSm,
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التوصيل إلى',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address?.oneLine ?? 'أضف عنوان التوصيل',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banners extends StatefulWidget {
  const _Banners({required this.banners});
  final List<m.Banner> banners;

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const _DefaultBanner();

    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: b.categoryId.isEmpty
                      ? null
                      : () {
                          final matches = Catalog.i.categories
                              .where((c) => c.id == b.categoryId);
                          if (matches.isEmpty) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CategoryProductsScreen(category: matches.first),
                            ),
                          );
                        },
                  child: ClipRRect(
                    borderRadius: AppShape.radius,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (b.image.isNotEmpty)
                          AppImage(source: b.image, fit: BoxFit.cover)
                        else
                          Container(color: AppColors.primary),
                        if (b.title.isNotEmpty || b.subtitle.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.centerRight,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (b.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    b.subtitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// بانر افتراضي لحد ما صاحب المحل يرفع بانراته من لوحة التحكم.
class _DefaultBanner extends StatelessWidget {
  const _DefaultBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: AppShape.radius,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.leaf],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'طازج يوميًا',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'خضار وفاكهة مختارة بعناية من أفضل المزارع',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'تسوّق الآن',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.categories});
  final List<m.Category> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final c = categories[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryProductsScreen(category: c),
              ),
            ),
            child: SizedBox(
              width: 84,
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppShape.soft,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipOval(
                      child: AppImage(source: c.image, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalProducts extends StatelessWidget {
  const _HorizontalProducts({required this.products});
  final List<m.Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 152,
          child: ProductCard(product: products[i]),
        ),
      ),
    );
  }
}

class _DeliveryPromo extends StatelessWidget {
  const _DeliveryPromo();

  @override
  Widget build(BuildContext context) {
    final s = Catalog.i.settings;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: AppShape.radius,
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.leaf, AppColors.primary],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توصيل سريع',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'لحد باب بيتك خلال ${s.deliveryEtaMinutes}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.delivery_dining, color: Colors.white, size: 52),
        ],
      ),
    );
  }
}
