import '../core/constants.dart';

/// قراءة آمنة من ماب الـ Realtime Database. الداتا جاية من لوحة تحكم
/// بشرية فمينفعش نفترض إن كل حقل موجود أو من النوع الصح.
double _d(dynamic v, [double def = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

int _i(dynamic v, [int def = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

String _s(dynamic v, [String def = '']) => v == null ? def : v.toString();

bool _b(dynamic v, [bool def = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return def;
}

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

// ─────────────────────────────────────────────────────────────────────────────

class Category {
  Category({
    required this.id,
    required this.name,
    this.image = '',
    this.sort = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String image;
  final int sort;
  final bool active;

  factory Category.fromMap(String id, Map<String, dynamic> m) => Category(
        id: id,
        name: _s(m['name']),
        image: _s(m['image']),
        sort: _i(m['sort']),
        active: _b(m['active'], true),
      );
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice = 0,
    this.categoryId = '',
    this.tags = const [],
    this.unit = 'كجم',
    this.step = 1,
    this.image = '',
    this.description = '',
    this.rating = 0,
    this.available = true,
    this.featured = false,
    this.sort = 0,
  });

  final String id;
  final String name;
  final double price;

  /// السعر قبل الخصم. لو أكبر من [price] يبقى الصنف عليه عرض.
  final double oldPrice;
  final String categoryId;

  /// تصنيفات فرعية (ثمار / ورقيات / جذور) زي الفلاتر في التصميم.
  final List<String> tags;
  final String unit;

  /// وحدة الزيادة والنقصان في الكمية — نص كيلو مثلًا يبقى 0.5.
  final double step;
  final String image;
  final String description;
  final double rating;
  final bool available;
  final bool featured;
  final int sort;

  bool get onSale => oldPrice > price && price > 0;

  int get discountPercent =>
      onSale ? (((oldPrice - price) / oldPrice) * 100).round() : 0;

  factory Product.fromMap(String id, Map<String, dynamic> m) {
    final rawTags = m['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      tags.addAll(rawTags.map((e) => e.toString()));
    } else if (rawTags is Map) {
      tags.addAll(rawTags.values.map((e) => e.toString()));
    } else if (rawTags is String && rawTags.trim().isNotEmpty) {
      tags.addAll(rawTags.split(',').map((e) => e.trim()));
    }

    return Product(
      id: id,
      name: _s(m['name']),
      price: _d(m['price']),
      oldPrice: _d(m['oldPrice']),
      categoryId: _s(m['categoryId']),
      tags: tags,
      unit: _s(m['unit'], 'كجم'),
      step: _d(m['step'], 1) <= 0 ? 1 : _d(m['step'], 1),
      image: _s(m['image']),
      description: _s(m['description']),
      rating: _d(m['rating']),
      available: _b(m['available'], true),
      featured: _b(m['featured']),
      sort: _i(m['sort']),
    );
  }
}

class Banner {
  Banner({
    required this.id,
    this.title = '',
    this.subtitle = '',
    this.image = '',
    this.categoryId = '',
    this.active = true,
    this.sort = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;

  /// لو متحدد، الضغط على البانر بيفتح القسم ده.
  final String categoryId;
  final bool active;
  final int sort;

  factory Banner.fromMap(String id, Map<String, dynamic> m) => Banner(
        id: id,
        title: _s(m['title']),
        subtitle: _s(m['subtitle']),
        image: _s(m['image']),
        categoryId: _s(m['categoryId']),
        active: _b(m['active'], true),
        sort: _i(m['sort']),
      );
}

class AppSettings {
  AppSettings({
    this.currency = 'ج.م',
    this.deliveryFee = 0,
    this.freeDeliveryOver = 0,
    this.minOrder = 0,
    this.open = true,
    this.closedMessage = 'المحل مقفول دلوقتي، اطلب في مواعيد العمل',
    this.workingHours = 'يوميًا من ٩ ص إلى ١٢ م',
    this.deliveryEtaMinutes = '٣٠ - ٤٥ دقيقة',
    this.announcement = '',
  });

  final String currency;
  final double deliveryFee;

  /// لو مجموع الطلب تعدّى الرقم ده يبقى التوصيل مجاني. صفر = الميزة مقفولة.
  final double freeDeliveryOver;
  final double minOrder;
  final bool open;
  final String closedMessage;
  final String workingHours;
  final String deliveryEtaMinutes;

  /// شريط إعلان بيظهر فوق الشاشة الرئيسية لو فيه نص.
  final String announcement;

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        currency: _s(m['currency'], 'ج.م'),
        deliveryFee: _d(m['deliveryFee']),
        freeDeliveryOver: _d(m['freeDeliveryOver']),
        minOrder: _d(m['minOrder']),
        open: _b(m['open'], true),
        closedMessage: _s(m['closedMessage'],
            'المحل مقفول دلوقتي، اطلب في مواعيد العمل'),
        workingHours: _s(m['workingHours'], 'يوميًا من ٩ ص إلى ١٢ م'),
        deliveryEtaMinutes: _s(m['deliveryEtaMinutes'], '٣٠ - ٤٥ دقيقة'),
        announcement: _s(m['announcement']),
      );

  /// حساب التوصيل على مجموع معيّن — مكان واحد بس عشان السلة والمراجعة
  /// والطلب النهائي ما يختلفوش.
  double deliveryFor(double subtotal) {
    if (freeDeliveryOver > 0 && subtotal >= freeDeliveryOver) return 0;
    return deliveryFee;
  }
}

class Coupon {
  Coupon({
    required this.code,
    this.percent = 0,
    this.amount = 0,
    this.minOrder = 0,
    this.active = true,
  });

  final String code;
  final double percent;
  final double amount;
  final double minOrder;
  final bool active;

  factory Coupon.fromMap(String code, Map<String, dynamic> m) => Coupon(
        code: code,
        percent: _d(m['percent']),
        amount: _d(m['amount']),
        minOrder: _d(m['minOrder']),
        active: _b(m['active'], true),
      );

  double discountOn(double subtotal) {
    if (!active || subtotal < minOrder) return 0;
    final byPercent = percent > 0 ? subtotal * percent / 100 : 0.0;
    final value = byPercent > 0 ? byPercent : amount;
    return value > subtotal ? subtotal : value;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class CartItem {
  CartItem({required this.product, required this.qty});

  final Product product;
  double qty;

  double get total => product.price * qty;

  Map<String, dynamic> toOrderLine() => {
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'unit': product.unit,
        'qty': qty,
        'total': total,
        'image': product.image,
      };
}

class Address {
  Address({
    required this.id,
    required this.label,
    required this.street,
    this.area = '',
    this.city = 'المنصورة',
    this.details = '',
    this.lat,
    this.lng,
  });

  final String id;
  final String label;
  final String street;
  final String area;
  final String city;
  final String details;
  final double? lat;
  final double? lng;

  String get oneLine {
    final parts = [street, area, city].where((e) => e.trim().isNotEmpty);
    return parts.join('، ');
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'street': street,
        'area': area,
        'city': city,
        'details': details,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  factory Address.fromMap(Map<String, dynamic> m) => Address(
        id: _s(m['id']),
        label: _s(m['label'], 'المنزل'),
        street: _s(m['street']),
        area: _s(m['area']),
        city: _s(m['city'], 'المنصورة'),
        details: _s(m['details']),
        lat: m['lat'] == null ? null : _d(m['lat']),
        lng: m['lng'] == null ? null : _d(m['lng']),
      );

  Address copyWith({
    String? label,
    String? street,
    String? area,
    String? city,
    String? details,
    double? lat,
    double? lng,
  }) =>
      Address(
        id: id,
        label: label ?? this.label,
        street: street ?? this.street,
        area: area ?? this.area,
        city: city ?? this.city,
        details: details ?? this.details,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}

class OrderLine {
  OrderLine({
    required this.name,
    required this.price,
    required this.qty,
    required this.unit,
    this.image = '',
  });

  final String name;
  final double price;
  final double qty;
  final String unit;
  final String image;

  double get total => price * qty;

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        name: _s(m['name']),
        price: _d(m['price']),
        qty: _d(m['qty'], 1),
        unit: _s(m['unit'], 'كجم'),
        image: _s(m['image']),
      );
}

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.number,
    required this.status,
    required this.createdAt,
    required this.lines,
    required this.subtotal,
    required this.delivery,
    required this.discount,
    required this.total,
    required this.addressText,
    this.customerName = '',
    this.customerPhone = '',
    this.slot = 'now',
    this.note = '',
    this.cancelReason = '',
    this.statusHistory = const {},
  });

  final String id;

  /// رقم قصير يقوله العميل في التليفون بدل مفتاح Firebase الطويل.
  final String number;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderLine> lines;
  final double subtotal;
  final double delivery;
  final double discount;
  final double total;
  final String addressText;
  final String customerName;
  final String customerPhone;

  /// `now` = دلوقتي، أو نص الوقت اللي اختاره العميل.
  final String slot;
  final String note;
  final String cancelReason;

  /// توقيت كل حالة عشان التايم-لاين يعرض الساعة مش بس علامة صح.
  final Map<String, DateTime> statusHistory;

  bool get isDone =>
      status == OrderStatus.delivered || status == OrderStatus.cancelled;

  /// العميل يقدر يلغي بس قبل ما الطلب يتجهّز.
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  factory ShopOrder.fromMap(String id, Map<String, dynamic> m) {
    final rawLines = m['lines'];
    final lines = <OrderLine>[];
    if (rawLines is List) {
      for (final e in rawLines) {
        lines.add(OrderLine.fromMap(asMap(e)));
      }
    } else if (rawLines is Map) {
      for (final e in rawLines.values) {
        lines.add(OrderLine.fromMap(asMap(e)));
      }
    }

    final history = <String, DateTime>{};
    final rawHistory = asMap(m['statusHistory']);
    rawHistory.forEach((k, v) {
      final ms = _i(v);
      if (ms > 0) history[k] = DateTime.fromMillisecondsSinceEpoch(ms);
    });

    return ShopOrder(
      id: id,
      number: _s(m['number'], id.length > 6 ? id.substring(id.length - 6) : id),
      status: OrderStatus.fromKey(_s(m['status'], 'pending')),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        _i(m['createdAt'], DateTime.now().millisecondsSinceEpoch),
      ),
      lines: lines,
      subtotal: _d(m['subtotal']),
      delivery: _d(m['delivery']),
      discount: _d(m['discount']),
      total: _d(m['total']),
      addressText: _s(m['addressText']),
      customerName: _s(m['customerName']),
      customerPhone: _s(m['customerPhone']),
      slot: _s(m['slot'], 'now'),
      note: _s(m['note']),
      cancelReason: _s(m['cancelReason']),
      statusHistory: history,
    );
  }
}
