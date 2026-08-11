import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../core/constants.dart';
import '../models/models.dart';

/// كل التعامل مع Realtime Database بيمرّ من هنا. الشاشات ما بتعرفش
/// أسماء المسارات، عشان لو اتغيّرت قاعدة البيانات بعدين (زي ما صاحب المحل
/// ناوي) التعديل يبقى في ملف واحد.
class Db {
  Db._();
  static final Db i = Db._();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference get _root => _db.ref();
  DatabaseReference get settingsRef => _root.child('settings');
  DatabaseReference get productsRef => _root.child('products');
  DatabaseReference get categoriesRef => _root.child('categories');
  DatabaseReference get bannersRef => _root.child('banners');
  DatabaseReference get couponsRef => _root.child('coupons');
  DatabaseReference get ordersRef => _root.child('orders');
  /// [key] هو رقم تليفون العميل بأرقام بس — مش معرّف الجهاز. كده بياناته
  /// وطلباته بتفضل معاه حتى لو مسح التطبيق ونزّله تاني.
  DatabaseReference customerRef(String key) => _root.child('customers/$key');
  DatabaseReference userOrdersRef(String key) => _root.child('user_orders/$key');

  /// خلي الكتالوج والإعدادات متخزّنين على الجهاز عشان التطبيق يفتح
  /// بمحتوى حتى لو النت ضعيف أو مقطوع.
  Future<void> enableOfflineCache() async {
    _db.setPersistenceEnabled(true);
    settingsRef.keepSynced(true);
    productsRef.keepSynced(true);
    categoriesRef.keepSynced(true);
    bannersRef.keepSynced(true);
  }

  // ── قراءة ────────────────────────────────────────────────────────────────

  Stream<AppSettings> settings() => settingsRef.onValue.map(
        (e) => AppSettings.fromMap(asMap(e.snapshot.value)),
      );

  Stream<List<Category>> categories() => categoriesRef.onValue.map((e) {
        final list = asMap(e.snapshot.value)
            .entries
            .map((kv) => Category.fromMap(kv.key, asMap(kv.value)))
            .where((c) => c.active)
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));
        return list;
      });

  Stream<List<Product>> products() => productsRef.onValue.map((e) {
        final list = asMap(e.snapshot.value)
            .entries
            .map((kv) => Product.fromMap(kv.key, asMap(kv.value)))
            .toList()
          ..sort((a, b) {
            // الأصناف المتاحة الأول، وبعدين ترتيب صاحب المحل، وبعدين الاسم.
            if (a.available != b.available) return a.available ? -1 : 1;
            final s = a.sort.compareTo(b.sort);
            return s != 0 ? s : a.name.compareTo(b.name);
          });
        return list;
      });

  Stream<List<Banner>> banners() => bannersRef.onValue.map((e) {
        final list = asMap(e.snapshot.value)
            .entries
            .map((kv) => Banner.fromMap(kv.key, asMap(kv.value)))
            .where((b) => b.active)
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));
        return list;
      });

  Future<Coupon?> findCoupon(String code) async {
    final key = code.trim().toUpperCase();
    if (key.isEmpty) return null;
    final snap = await couponsRef.child(key).get();
    if (!snap.exists) return null;
    return Coupon.fromMap(key, asMap(snap.value));
  }

  // ── طلبات العميل ─────────────────────────────────────────────────────────

  /// بنقرأ طلبات العميل من فهرس `user_orders/{phone}` وبعدين نجيب كل طلب
  /// بمفتاحه — كده العميل مش محتاج صلاحية قراءة على كل الطلبات.
  Stream<List<ShopOrder>> myOrders(String key) {
    return userOrdersRef(key).onValue.asyncMap((event) async {
      final ids = asMap(event.snapshot.value).keys.toList();
      final orders = await Future.wait(ids.map((id) async {
        final s = await ordersRef.child(id).get();
        if (!s.exists) return null;
        return ShopOrder.fromMap(id, asMap(s.value));
      }));
      final list = orders.whereType<ShopOrder>().toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<ShopOrder?> watchOrder(String id) => ordersRef.child(id).onValue.map(
        (e) => e.snapshot.exists
            ? ShopOrder.fromMap(id, asMap(e.snapshot.value))
            : null,
      );

  /// رقم طلب قصير ومتسلسل. بنستخدم transaction عشان لو اتنين طلبوا في
  /// نفس اللحظة ما ياخدوش نفس الرقم.
  Future<String> _nextOrderNumber() async {
    final ref = _root.child('counters/orderNumber');
    final result = await ref.runTransaction((current) {
      final n = current is int ? current : 1000;
      return Transaction.success(n + 1);
    });
    final value = result.snapshot.value;
    if (value is int) return value.toString();
    // لو الـ transaction فشلت لأي سبب، منرجّعش خطأ للعميل — بنستخدم
    // آخر ٦ أرقام من الوقت كبديل مؤقت.
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  }

  Future<String> placeOrder({
    required String uid,
    required String customerKey,
    required List<CartItem> items,
    required Address address,
    required String customerName,
    required String customerPhone,
    required double subtotal,
    required double delivery,
    required double discount,
    required double total,
    required String slot,
    String couponCode = '',
    String note = '',
  }) async {
    final ref = ordersRef.push();
    final id = ref.key!;
    final now = DateTime.now().millisecondsSinceEpoch;
    final number = await _nextOrderNumber();

    await ref.set({
      'number': number,
      // `phone` هو صاحب الطلب — عليه بيتبني الفهرس وقواعد الأمان.
      // `uid` معرّف الجهاز، محفوظ للمراجعة بس.
      'phone': customerKey,
      'uid': uid,
      'status': OrderStatus.pending.key,
      'createdAt': now,
      'statusHistory': {OrderStatus.pending.key: now},
      'lines': items.map((e) => e.toOrderLine()).toList(),
      'subtotal': subtotal,
      'delivery': delivery,
      'discount': discount,
      'total': total,
      'couponCode': couponCode,
      'payment': 'cod',
      'slot': slot,
      'note': note,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'addressText': address.oneLine,
      'address': address.toMap(),
    });

    await userOrdersRef(customerKey).child(id).set(now);
    return id;
  }

  Future<void> cancelOrder(String id, String reason) async {
    await ordersRef.child(id).update({
      'status': OrderStatus.cancelled.key,
      'cancelReason': reason,
      'statusHistory/${OrderStatus.cancelled.key}':
          DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── ملف العميل ───────────────────────────────────────────────────────────

  /// ملف العميل: بياناته وعناوينه، متخزّن على رقم تليفونه.
  ///
  /// ده مش مجرد نسخة لصاحب المحل — ده المصدر اللي بيرجّع للعميل بياناته
  /// لو غيّر الموبايل أو مسح التطبيق.
  Future<void> saveCustomer({
    required String key,
    required String name,
    required String phone,
    List<Address> addresses = const [],
  }) async {
    await customerRef(key).update({
      'name': name,
      'phone': phone,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (addresses.isNotEmpty)
        'addresses': {for (final a in addresses) a.id: a.toMap()},
    });
  }

  /// بنستبدل قايمة العناوين بالكامل — بنستخدمها بعد الحذف، لأن `update`
  /// بيدمج ومش بيشيل اللي اتشال.
  Future<void> replaceAddresses(String key, List<Address> addresses) async {
    await customerRef(key).child('addresses').set(
          addresses.isEmpty
              ? null
              : {for (final a in addresses) a.id: a.toMap()},
        );
  }
}
