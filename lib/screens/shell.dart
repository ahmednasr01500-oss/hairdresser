import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/cart.dart';
import 'cart.dart';
import 'home.dart';
import 'more.dart';
import 'offers.dart';
import 'orders.dart';

/// الهيكل الرئيسي بعد الدخول: خمس شاشات وشريط سفلي.
///
/// السلة في النص وبارزة عن الشريط لأنها أكتر زرار العميل هيدوس عليه،
/// وعليها عدّاد بيتحدّث لحظيًا.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => AppShellState();

  /// عشان أي شاشة تقدر تنقّل التبويب (زي "تسوّق دلوقتي" في السلة الفاضية).
  ///
  /// الشاشات المفتوحة فوق الهيكل (صفحة الصنف مثلًا) مش تحته في شجرة
  /// الويدجتس — هي أخت ليه جوه الـ Navigator — فالبحث بالـ ancestor
  /// بيرجّع فاضي منها. عشان كده بنرجع للنسخة الشغّالة كخطة تانية.
  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>() ?? AppShellState.current;
}

class AppShellState extends State<AppShell> {
  /// النسخة الشغّالة دلوقتي — الهيكل واحد على مستوى التطبيق.
  static AppShellState? current;

  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    current = this;
  }

  @override
  void dispose() {
    if (identical(current, this)) current = null;
    super.dispose();
  }

  final _pages = const [
    HomeScreen(),
    OrdersScreen(),
    CartScreen(),
    OffersScreen(),
    MoreScreen(),
  ];

  void goTo(int index) => setState(() => _index = index);

  void goHome() => goTo(0);
  void goCart() => goTo(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: goTo,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _Item(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'الرئيسية',
                selected: index == 0,
                onTap: () => onTap(0),
              ),
              _Item(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'الطلبات',
                selected: index == 1,
                onTap: () => onTap(1),
              ),
              _CartButton(selected: index == 2, onTap: () => onTap(2)),
              _Item(
                icon: Icons.local_offer_outlined,
                activeIcon: Icons.local_offer,
                label: 'العروض',
                selected: index == 3,
                onTap: () => onTap(3),
              ),
              _Item(
                icon: Icons.more_horiz,
                activeIcon: Icons.more_horiz,
                label: 'المزيد',
                selected: index == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: ListenableBuilder(
          listenable: Cart.i,
          builder: (context, _) {
            final count = Cart.i.count;
            return GestureDetector(
              onTap: onTap,
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints: const BoxConstraints(minWidth: 22),
                          child: Text(
                            '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
