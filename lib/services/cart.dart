import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// السلة. بتتخزّن على الجهاز عشان لو العميل قفل التطبيق وهو بيدوّر على
/// حاجة تانية ما يلاقيش سلته فاضية لما يرجع.
class Cart extends ChangeNotifier {
  Cart._();
  static final Cart i = Cart._();

  static const _kItems = 'cart_items';

  SharedPreferences? _prefs;
  final List<CartItem> _items = [];

  Coupon? _coupon;
  Coupon? get coupon => _coupon;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get count => _items.length;

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  double get discount => _coupon?.discountOn(subtotal) ?? 0;

  double qtyOf(String productId) {
    for (final item in _items) {
      if (item.product.id == productId) return item.qty;
    }
    return 0;
  }

  Future<void> load(List<Product> catalog) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kItems);
    if (raw == null || raw.isEmpty) return;

    try {
      final saved = jsonDecode(raw) as List;
      final byId = {for (final p in catalog) p.id: p};
      _items.clear();
      for (final e in saved) {
        final m = asMap(e);
        final product = byId[m['id']?.toString()];
        // لو صاحب المحل شال الصنف أو وقّفه، بيختفي من السلة لوحده بدل
        // ما العميل يفاجأ عند الدفع.
        if (product == null || !product.available) continue;
        final qty = (m['qty'] is num) ? (m['qty'] as num).toDouble() : 1.0;
        _items.add(CartItem(product: product, qty: qty));
      }
      notifyListeners();
    } catch (_) {
      await _prefs!.remove(_kItems);
    }
  }

  void add(Product product, {double? qty}) {
    final amount = qty ?? product.step;
    final idx = _items.indexWhere((e) => e.product.id == product.id);
    if (idx >= 0) {
      _items[idx].qty += amount;
    } else {
      _items.add(CartItem(product: product, qty: amount));
    }
    _persist();
    notifyListeners();
  }

  void setQty(Product product, double qty) {
    final idx = _items.indexWhere((e) => e.product.id == product.id);
    if (qty <= 0) {
      if (idx >= 0) _items.removeAt(idx);
    } else if (idx >= 0) {
      _items[idx].qty = qty;
    } else {
      _items.add(CartItem(product: product, qty: qty));
    }
    _persist();
    notifyListeners();
  }

  void increment(Product product) =>
      setQty(product, qtyOf(product.id) + product.step);

  void decrement(Product product) =>
      setQty(product, qtyOf(product.id) - product.step);

  void remove(String productId) {
    _items.removeWhere((e) => e.product.id == productId);
    _persist();
    notifyListeners();
  }

  void applyCoupon(Coupon? coupon) {
    _coupon = coupon;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _coupon = null;
    _persist();
    notifyListeners();
  }

  void _persist() {
    _prefs?.setString(
      _kItems,
      jsonEncode(
        _items.map((e) => {'id': e.product.id, 'qty': e.qty}).toList(),
      ),
    );
  }
}
