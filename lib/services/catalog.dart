import 'dart:async';

// `Category` معرّف كمان في foundation كـ annotation — بنخفيه عشان ما
// يتلخبطش مع كلاس الأقسام بتاعنا.
import 'package:flutter/foundation.dart' hide Category;

import '../models/models.dart';
import 'cart.dart';
import 'db.dart';

/// الكتالوج المشترك: الأصناف والأقسام والبانرات والإعدادات.
///
/// بنشترك في كل مسار مرة واحدة بس على مستوى التطبيق. كل شاشة بتستمع
/// للـ notifier ده بدل ما تفتح اشتراك جديد لنفسها — ده بيوفّر من حصة
/// التحميل المجانية في Firebase وبيخلي كل الشاشات متسقة مع بعض.
class Catalog extends ChangeNotifier {
  Catalog._();
  static final Catalog i = Catalog._();

  final List<StreamSubscription> _subs = [];

  List<Product> products = [];
  List<Category> categories = [];
  List<Banner> banners = [];
  AppSettings settings = AppSettings();

  bool _productsLoaded = false;
  bool get ready => _productsLoaded;

  /// أول مرة توصل فيها قائمة الأصناف بنرجّع السلة المحفوظة، عشان نقدر
  /// نربط كل سطر فيها بالصنف وسعره الحالي.
  bool _cartRestored = false;

  void start() {
    if (_subs.isNotEmpty) return;

    _subs.add(Db.i.products().listen((v) async {
      products = v;
      _productsLoaded = true;
      if (!_cartRestored) {
        _cartRestored = true;
        await Cart.i.load(products);
      }
      notifyListeners();
    }, onError: (e) => debugPrint('products stream: $e')));

    _subs.add(Db.i.categories().listen((v) {
      categories = v;
      notifyListeners();
    }, onError: (e) => debugPrint('categories stream: $e')));

    _subs.add(Db.i.banners().listen((v) {
      banners = v;
      notifyListeners();
    }, onError: (e) => debugPrint('banners stream: $e')));

    _subs.add(Db.i.settings().listen((v) {
      settings = v;
      notifyListeners();
    }, onError: (e) => debugPrint('settings stream: $e')));
  }

  Product? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> inCategory(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList();

  /// الأكثر طلبًا = اللي صاحب المحل علّم عليه "مميّز". لو ماعلّمش على
  /// حاجة بنعرض أول الأصناف المتاحة بدل ما القسم يفضل فاضي.
  List<Product> get featured {
    final marked = products.where((p) => p.featured && p.available).toList();
    if (marked.isNotEmpty) return marked;
    return products.where((p) => p.available).take(6).toList();
  }

  List<Product> get onSale =>
      products.where((p) => p.onSale && p.available).toList();

  /// بحث بسيط بيتجاهل التشكيل والهمزات عشان "باذنجان" و"باذنجان" و"بازنجان"
  /// ما يبقوش نتايج مختلفة.
  List<Product> search(String query) {
    final q = normalizeArabic(query);
    if (q.isEmpty) return const [];
    return products.where((p) {
      return normalizeArabic(p.name).contains(q) ||
          normalizeArabic(p.description).contains(q) ||
          p.tags.any((t) => normalizeArabic(t).contains(q));
    }).toList();
  }

  /// كل الوسوم الفرعية الموجودة فعلًا في قسم معيّن — دي اللي بتترسم
  /// كشرايط الفلاتر فوق قائمة الأصناف.
  List<String> tagsIn(String categoryId) {
    final set = <String>{};
    for (final p in inCategory(categoryId)) {
      set.addAll(p.tags.where((t) => t.trim().isNotEmpty));
    }
    return set.toList()..sort();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}

final _diacritics = RegExp('[ً-ْـ]');

String normalizeArabic(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll(_diacritics, '');
  s = s.replaceAll(RegExp('[أإآٱ]'), 'ا');
  s = s.replaceAll('ى', 'ي');
  s = s.replaceAll('ة', 'ه');
  s = s.replaceAll('ؤ', 'و');
  s = s.replaceAll('ئ', 'ي');
  return s;
}
