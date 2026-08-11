import 'package:akhdar/models/models.dart';
import 'package:akhdar/services/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات للمنطق اللي لو غلط بيغلط في فلوس العميل — الخصم والتوصيل
/// والبحث العربي. الشاشات نفسها بتتجرّب يدويًا على الجهاز.
void main() {
  group('حساب التوصيل', () {
    test('التوصيل مجاني فوق الحد', () {
      final s = AppSettings(deliveryFee: 15, freeDeliveryOver: 200);
      expect(s.deliveryFor(199), 15);
      expect(s.deliveryFor(200), 0);
      expect(s.deliveryFor(350), 0);
    });

    test('لو الحد بصفر يبقى التوصيل مدفوع دايمًا', () {
      final s = AppSettings(deliveryFee: 15, freeDeliveryOver: 0);
      expect(s.deliveryFor(10000), 15);
    });
  });

  group('كوبون الخصم', () {
    test('نسبة مئوية', () {
      final c = Coupon(code: 'AKH10', percent: 10);
      expect(c.discountOn(200), 20);
    });

    test('مبلغ ثابت مش بيزيد عن قيمة الطلب', () {
      final c = Coupon(code: 'FLAT50', amount: 50);
      expect(c.discountOn(30), 30);
    });

    test('مش بيشتغل تحت الحد الأدنى', () {
      final c = Coupon(code: 'AKH10', percent: 10, minOrder: 100);
      expect(c.discountOn(80), 0);
      expect(c.discountOn(100), 10);
    });

    test('الكوبون الموقوف مالوش أثر', () {
      final c = Coupon(code: 'OLD', percent: 50, active: false);
      expect(c.discountOn(200), 0);
    });
  });

  group('تطبيع النص العربي في البحث', () {
    test('الهمزات والتاء المربوطة والتشكيل', () {
      expect(normalizeArabic('أرز'), normalizeArabic('ارز'));
      expect(normalizeArabic('فاكهة'), normalizeArabic('فاكهه'));
      expect(normalizeArabic('طَمَاطِم'), normalizeArabic('طماطم'));
      expect(normalizeArabic('  بطاطس '), 'بطاطس');
    });
  });

  group('قراءة الصنف من قاعدة البيانات', () {
    test('الوسوم بتتقرا سواء قايمة أو نص مفصول بفواصل', () {
      final fromList = Product.fromMap('a', {
        'name': 'خيار',
        'price': 4.5,
        'tags': ['ثمار', 'طازج'],
      });
      final fromString = Product.fromMap('b', {
        'name': 'خيار',
        'price': '4.5',
        'tags': 'ثمار, طازج',
      });
      expect(fromList.tags, ['ثمار', 'طازج']);
      expect(fromString.tags, ['ثمار', 'طازج']);
      expect(fromString.price, 4.5);
    });

    test('خطوة الكمية مبتبقاش صفر حتى لو اتكتبت غلط', () {
      final p = Product.fromMap('a', {'name': 'موز', 'price': 6, 'step': 0});
      expect(p.step, 1);
    });

    test('نسبة الخصم بتتحسب من السعر القديم', () {
      final p = Product.fromMap('a', {
        'name': 'تفاح',
        'price': 8,
        'oldPrice': 10,
      });
      expect(p.onSale, isTrue);
      expect(p.discountPercent, 20);
    });
  });
}
