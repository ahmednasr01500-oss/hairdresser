import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../services/session.dart';
import 'map_picker.dart';
import 'shell.dart';

/// إضافة أو تعديل عنوان توصيل.
///
/// الخريطة اختيارية مش إجبارية: في المنصورة كتير من العناوين بتتوصف
/// بالعلامات المميزة أحسن من الإحداثيات، فسبنا للعميل الاتنين.
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({
    super.key,
    this.existing,
    this.isOnboarding = false,
  });

  final Address? existing;

  /// أول مرة بعد التسجيل — بنعرض زرار "تخطي" ونروح للرئيسية بعد الحفظ.
  final bool isOnboarding;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const _labels = ['المنزل', 'العمل', 'مكان آخر'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _street;
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _details;

  late String _label;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _street = TextEditingController(text: a?.street ?? '');
    _area = TextEditingController(text: a?.area ?? '');
    _city = TextEditingController(text: a?.city ?? 'المنصورة');
    _details = TextEditingController(text: a?.details ?? '');
    _label = _labels.contains(a?.label) ? a!.label : _labels.first;
    _lat = a?.lat;
    _lng = a?.lng;
  }

  @override
  void dispose() {
    _street.dispose();
    _area.dispose();
    _city.dispose();
    _details.dispose();
    super.dispose();
  }

  bool get _hasPin => _lat != null && _lng != null;

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initial: _hasPin ? LatLng(_lat!, _lng!) : null,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      // بنملأ الشارع من الخريطة بس لو العميل ماكتبش حاجة، عشان ما نمسحش
      // وصف كتبه بإيده.
      if (_street.text.trim().isEmpty && result.description.isNotEmpty) {
        _street.text = result.description.split('،').take(2).join('،').trim();
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      label: _label,
      street: _street.text.trim(),
      area: _area.text.trim(),
      city: _city.text.trim(),
      details: _details.text.trim(),
      lat: _lat,
      lng: _lng,
    );

    await Session.i.saveAddress(address);
    if (!mounted) return;

    if (widget.isOnboarding) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pop(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'عنوان التوصيل' : 'تعديل العنوان'),
        actions: [
          if (widget.isOnboarding)
            TextButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AppShell()),
                (_) => false,
              ),
              child: const Text('تخطي', style: TextStyle(color: AppColors.muted)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.leaf.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      size: 38, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'فين نوصّل طلبك؟',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'كل ما العنوان يكون واضح، كل ما الطلب يوصلك أسرع',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              const _Label('نوع المكان'),
              Wrap(
                spacing: 8,
                children: _labels
                    .map((l) => ChoiceChip(
                          label: Text(l),
                          selected: _label == l,
                          onSelected: (_) => setState(() => _label = l),
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF3F6F3),
                          side: BorderSide.none,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: _label == l ? Colors.white : AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),

              const _Label('العنوان'),
              TextFormField(
                controller: _street,
                decoration: const InputDecoration(
                  hintText: 'مثال: شارع منار الإسلام، عمارة ١٢',
                ),
                validator: (v) => (v ?? '').trim().length < 4
                    ? 'اكتب اسم الشارع ورقم العمارة'
                    : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Label('الحي / المنطقة'),
                        TextFormField(
                          controller: _area,
                          decoration:
                              const InputDecoration(hintText: 'مثال: توريل'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Label('المدينة'),
                        TextFormField(
                          controller: _city,
                          decoration:
                              const InputDecoration(hintText: 'المنصورة'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const _Label('تفاصيل إضافية (اختياري)'),
              TextFormField(
                controller: _details,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'مثال: بجوار مسجد النور، الدور الثالث، شقة ٧',
                ),
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _pickOnMap,
                icon: Icon(
                  _hasPin ? Icons.check_circle : Icons.map_outlined,
                  color: _hasPin ? AppColors.primary : null,
                ),
                label: Text(
                  _hasPin ? 'الموقع محدد — اضغط للتعديل' : 'تحديد الموقع على الخريطة',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: const Text('حفظ العنوان'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
}
