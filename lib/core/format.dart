import 'package:intl/intl.dart';

import '../services/catalog.dart';

/// تنسيق الأرقام والفلوس والتواريخ في مكان واحد.

final _money = NumberFormat('#,##0.00', 'en');
final _qtyFmt = NumberFormat('0.##', 'en');

/// السعر بالعملة اللي صاحب المحل مختارها من لوحة التحكم.
String price(double value) =>
    '${_money.format(value)} ${Catalog.i.settings.currency}';

String priceNoCurrency(double value) => _money.format(value);

/// الكمية: "١" مش "١.٠٠"، و"٠.٥" للنص كيلو.
String qty(double value) => _qtyFmt.format(value);

String qtyWithUnit(double value, String unit) => '${qty(value)} $unit';

final _dayFmt = DateFormat('d MMMM', 'ar');
final _timeFmt = DateFormat('h:mm a', 'ar');

String orderDate(DateTime d) {
  final now = DateTime.now();
  final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day;

  if (sameDay) return 'النهاردة ${_timeFmt.format(d)}';
  if (isYesterday) return 'إمبارح ${_timeFmt.format(d)}';
  return '${_dayFmt.format(d)} — ${_timeFmt.format(d)}';
}

String clockOnly(DateTime d) => _timeFmt.format(d);
