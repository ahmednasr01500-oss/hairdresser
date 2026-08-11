import 'package:flutter/material.dart';

import '../services/catalog.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';

/// بحث في كل الكتالوج. البحث بيتم محليًا على القايمة المحمّلة أصلًا،
/// فبيبان فوري وشغّال حتى من غير نت.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = Catalog.i.search(_query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'طماطم، موز، خيار…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      body: _query.trim().isEmpty
          ? const _Suggestions()
          : results.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'ملقيناش المنتج ده',
                  message: 'جرّب اسم تاني، أو كلّمنا واطلبه ونجيبهولك',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (context, i) => ProductTile(product: results[i]),
                ),
    );
  }
}

/// قبل ما العميل يكتب حاجة بنعرض الأقسام كاقتراحات سريعة.
class _Suggestions extends StatelessWidget {
  const _Suggestions();

  @override
  Widget build(BuildContext context) {
    final featured = Catalog.i.featured;
    if (featured.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'دوّر على اللي نفسك فيه',
        message: 'اكتب اسم المنتج وهيظهرلك على طول',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            'الأكثر بحثًا',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        ...featured.map((p) => ProductTile(product: p)),
      ],
    );
  }
}
