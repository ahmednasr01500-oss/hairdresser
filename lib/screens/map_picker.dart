import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// نتيجة اختيار الموقع: الإحداثيات + وصف نصي للمكان لو قدرنا نجيبه.
class PickedLocation {
  PickedLocation({required this.lat, required this.lng, this.description = ''});

  final double lat;
  final double lng;
  final String description;
}

/// اختيار موقع التوصيل على الخريطة.
///
/// بنستخدم خرايط OpenStreetMap مش Google Maps: مجانية بالكامل ومش
/// محتاجة مفتاح API ولا تفعيل فوترة — وده اللي يناسب المرحلة الحالية.
/// لو صاحب المحل حب يحوّل لـ Google Maps بعدين، التغيير محصور في الملف ده.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _map = MapController();
  final _searchCtrl = TextEditingController();

  late LatLng _center;
  String _description = '';
  bool _resolving = false;
  bool _locating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ??
        const LatLng(Shop.defaultLat, Shop.defaultLng);
    _resolveAddress();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _map.dispose();
    super.dispose();
  }

  /// بنستنى شوية بعد ما العميل يبطّل تحريك الخريطة قبل ما نسأل السيرفر —
  /// من غير كده هنبعت عشرات الطلبات في السحبة الواحدة.
  void _onMoved(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _resolveAddress);
  }

  Future<void> _resolveAddress() async {
    setState(() => _resolving = true);
    final text = await _reverseGeocode(_center);
    if (!mounted) return;
    setState(() {
      _description = text;
      _resolving = false;
    });
  }

  Future<String> _reverseGeocode(LatLng p) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}'
        '&accept-language=ar&zoom=18',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'AkhdarApp/1.0 (shop delivery app)',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return '';
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['display_name'] ?? '').toString();
    } catch (_) {
      // العنوان النصي رفاهية — لو فشل، الإحداثيات لوحدها تكفي السايق.
      return '';
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast('محتاجين إذن الموقع عشان نحدد مكانك تلقائي');
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('شغّل الـ GPS الأول');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _center = target;
      _map.move(target, 17);
      await _resolveAddress();
    } catch (_) {
      _toast('مقدرناش نجيب موقعك، حدده على الخريطة بإيدك');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _resolving = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=jsonv2&q=${Uri.encodeQueryComponent(query)}'
        '&accept-language=ar&limit=1&countrycodes=eg',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'AkhdarApp/1.0 (shop delivery app)',
      }).timeout(const Duration(seconds: 8));
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) {
        _toast('ملقيناش المكان ده');
        return;
      }
      final first = list.first as Map<String, dynamic>;
      final target = LatLng(
        double.parse(first['lat'].toString()),
        double.parse(first['lon'].toString()),
      );
      _center = target;
      _map.move(target, 16);
      if (mounted) {
        setState(() => _description = (first['display_name'] ?? '').toString());
      }
    } catch (_) {
      _toast('البحث مش شغّال دلوقتي');
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حدد موقعك على الخريطة')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'ابحث عن موقعك أو تحرّك على الخريطة',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _search(_searchCtrl.text),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15,
                    onPositionChanged: _onMoved,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.akhdar.akhdar',
                      maxZoom: 19,
                    ),
                  ],
                ),

                // الدبوس ثابت في نص الشاشة والخريطة هي اللي بتتحرك تحته —
                // أسهل بكتير من إن العميل يحاول يظبط دبوس بصباعه.
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 36),
                      child: Icon(
                        Icons.location_on,
                        size: 52,
                        color: AppColors.primary,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 16,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: 'myloc',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: _locating ? null : _goToMyLocation,
                    child: _locating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShape.soft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppShape.r),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'العنوان المحدد',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _resolving
                                  ? 'جاري تحديد العنوان…'
                                  : (_description.isEmpty
                                      ? 'موقع على الخريطة'
                                      : _description),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      PickedLocation(
                        lat: _center.latitude,
                        lng: _center.longitude,
                        description: _description,
                      ),
                    ),
                    child: const Text('تأكيد الموقع'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
