/// بيانات المحل الثابتة. أي حاجة ممكن تتغيّر مع الوقت (رسوم التوصيل،
/// الحد الأدنى للطلب، المحل مفتوح ولا لأ) موجودة في `settings` في قاعدة
/// البيانات وبيتحكم فيها صاحب المحل من لوحة التحكم — مش من هنا.
class Shop {
  static const name = 'أخضر';
  static const tagline = 'مِتنَقّي بالوَاحدَه';
  static const slogan = 'طازج .. نقي .. لأجلك';

  static const address =
      'شارع منار الإسلام متفرع من شارع الترعة، على ناصية الشارع مقلة اللؤلؤة، '
      'ومن ناحية سامية الجمل الحمام الذهبي — المنصورة';

  static const phoneLandline = '0502380922';
  static const phoneOrders = '01039086955';
  static const phoneAlt = '01552145899';
  static const whatsapp = '201039086955';
  static const whatsappChannel =
      'https://whatsapp.com/channel/0029VbDstqDAYlUPPV3Ln213';

  /// مركز المنصورة تقريبًا — نقطة بداية الخريطة قبل ما العميل يحدد مكانه.
  static const defaultLat = 31.0409;
  static const defaultLng = 31.3785;
}

/// حالات الطلب بالترتيب. الترتيب ده هو اللي بيرسم التايم-لاين في شاشة
/// تتبع الطلب، فأي حالة جديدة لازم تتحط في مكانها الصح.
enum OrderStatus {
  pending('pending', 'قيد المراجعة'),
  confirmed('confirmed', 'تم التأكيد'),
  preparing('preparing', 'بيتجهّز'),
  onWay('on_way', 'في الطريق إليك'),
  delivered('delivered', 'تم التسليم'),
  cancelled('cancelled', 'ملغي');

  const OrderStatus(this.key, this.label);
  final String key;
  final String label;

  static OrderStatus fromKey(String? k) => OrderStatus.values.firstWhere(
        (e) => e.key == k,
        orElse: () => OrderStatus.pending,
      );

  /// الحالات اللي بتتعرض كخطوات في التايم-لاين (الإلغاء مش خطوة، هو نهاية).
  static const timeline = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.onWay,
    OrderStatus.delivered,
  ];
}
