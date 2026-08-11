import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart' as m;
import '../services/catalog.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

/// أصناف قسم واحد، مع بحث داخل القسم وفلاتر فرعية (ثمار / ورقيات / جذور…).
/// الفلاتر بتتولّد من الوسوم اللي صاحب المحل كتبها فعلًا — مش قايمة ثابتة.
class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final m.Category category;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _tag = '';
  bool _onlyAvailable = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<m.Product> _filtered() {
    final q = normalizeArabic(_query);
    return Catalog.i.inCategory(widget.category.id).where((p) {
      if (_onlyAvailable && !p.available) return false;
      if (_tag.isNotEmpty && !p.tags.contains(_tag)) return false;
      if (q.isNotEmpty && !normalizeArabic(p.name).contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: ListenableBuilder(
        listenable: Catalog.i,
        builder: (context, _) {
          final tags = Catalog.i.tagsIn(widget.category.id);
          final products = _filtered();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن منتج…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FilterButton(
                      active: _onlyAvailable,
                      onTap: () =>
                          setState(() => _onlyAvailable = !_onlyAvailable),
                    ),
                  ],
                ),
              ),

              if (tags.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _Chip(
                        label: 'الكل',
                        selected: _tag.isEmpty,
                        onTap: () => setState(() => _tag = ''),
                      ),
                      ...tags.map((t) => _Chip(
                            label: t,
                            selected: _tag == t,
                            onTap: () => setState(() => _tag = t),
                          )),
                    ],
                  ),
                ),

              Expanded(
                child: products.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: _query.isEmpty
                            ? 'القسم ده لسه فاضي'
                            : 'ملقيناش حاجة بالاسم ده',
                        message: _query.isEmpty
                            ? 'هيتضاف عليه أصناف قريب إن شاء الله'
                            : 'جرّب اسم تاني أو شيل الفلاتر',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, i) =>
                            ProductCard(product: products[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'المتاح دلوقتي بس',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFF3F6F3),
            borderRadius: AppShape.radiusSm,
          ),
          child: Icon(
            Icons.tune,
            color: active ? Colors.white : AppColors.text,
            size: 22,
          ),
        ),
      ),
    );
  }
}
