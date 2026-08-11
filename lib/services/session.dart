import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'db.dart';

/// بيانات العميل وعناوينه.
///
/// الدخول بالاسم والرقم بس — من غير كود تحقق.
///
/// **هوية العميل هي رقم تليفونه، مش الجهاز.** الأول كنا بنربط الطلبات
/// بمعرّف مجهول بيتولّد على الجهاز، فلما العميل كان يمسح التطبيق وينزله
/// تاني كان بيضيع منه كل حاجة. دلوقتي كل حاجة متعلّقة بالرقم، فأول ما
/// يكتبه بيرجعله اسمه وعناوينه وطلباته من السيرفر.
///
/// المقايضة اللي اتوافق عليها: مفيش كود تحقق، يعني اللي يكتب رقم حد
/// تاني هيشوف طلباته وعنوانه. الحل الآمن ده محتاج رسايل SMS مدفوعة.
/// لو اتفعّلت بعدين، التغيير هيبقى في الملف ده وفي قواعد الأمان بس.
///
/// الدخول المجهول في Firebase لسه موجود — بس دوره بقى إثبات إن الطلب
/// جاي من التطبيق مش من أي حد على النت.
class Session extends ChangeNotifier {
  Session._();
  static final Session i = Session._();

  static const _kName = 'customer_name';
  static const _kPhone = 'customer_phone';
  static const _kAddresses = 'customer_addresses';
  static const _kSelected = 'customer_selected_address';
  static const _kFavorites = 'customer_favorites';

  SharedPreferences? _prefs;

  String _name = '';
  String _phone = '';
  List<Address> _addresses = [];
  String _selectedAddressId = '';
  String _uid = '';

  String get name => _name;
  String get phone => _phone;
  String get uid => _uid;
  List<Address> get addresses => List.unmodifiable(_addresses);

  /// المفتاح اللي بتتخزّن بيه بيانات العميل وطلباته في قاعدة البيانات.
  /// أرقام بس — عشان "0103 254 7745" و"01032547745" يبقوا نفس العميل.
  String get customerKey => normalizePhone(_phone);

  static String normalizePhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  bool get isLoggedIn => _phone.isNotEmpty && _uid.isNotEmpty;
  bool get hasAddress => _addresses.isNotEmpty;

  Address? get selectedAddress {
    if (_addresses.isEmpty) return null;
    for (final a in _addresses) {
      if (a.id == _selectedAddressId) return a;
    }
    return _addresses.first;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _name = _prefs!.getString(_kName) ?? '';
    _phone = _prefs!.getString(_kPhone) ?? '';
    _selectedAddressId = _prefs!.getString(_kSelected) ?? '';
    _favorites
      ..clear()
      ..addAll(_prefs!.getStringList(_kFavorites) ?? const []);

    final raw = _prefs!.getString(_kAddresses);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _addresses =
            list.map((e) => Address.fromMap(asMap(e))).toList(growable: true);
      } catch (_) {
        // بيانات تالفة على الجهاز — منوقّفش التطبيق عشانها.
        _addresses = [];
      }
    }

    // العميل القديم اللي عنده رقم متسجّل بيرجع لحسابه من غير أي خطوة.
    if (_phone.isNotEmpty) {
      await _ensureSignedIn();
    }
    notifyListeners();
  }

  Future<bool> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        debugPrint('anonymous sign-in failed: $e');
        return false;
      }
    }
    _uid = auth.currentUser?.uid ?? '';
    return _uid.isNotEmpty;
  }

  /// بترجّع `false` لو مقدرناش نجيب هوية للجهاز من Firebase.
  ///
  /// من غير الهوية دي مفيش طلب يتبعت، فالشاشة اللي بتنادي لازم توقّف
  /// وتقول للعميل. أشهر سببين: النت مقطوع، أو مزوّد "Anonymous" لسه
  /// مش مفعّل في Firebase Console (راجع SETUP.md خطوة ١).
  Future<bool> signIn({required String name, required String phone}) async {
    _name = name.trim();
    _phone = phone.trim();
    final ok = await _ensureSignedIn();
    if (!ok) {
      // مبنحفظش بيانات ناقصة على الجهاز — نخلي العميل يعيد المحاولة نضيف.
      _name = '';
      _phone = '';
      return false;
    }
    await _prefs?.setString(_kName, _name);
    await _prefs?.setString(_kPhone, _phone);

    // العميل اللي طلب من قبل بنفس الرقم: بنرجّعله عناوينه من السيرفر
    // بدل ما يكتبها من الأول بعد كل إعادة تركيب.
    final restored = await _restoreFromServer();
    notifyListeners();
    if (!restored) _syncToServer();
    return true;
  }

  /// بنقرأ ملف العميل المحفوظ على رقمه ونرجّع منه العناوين (والاسم لو
  /// العميل ساب الخانة فاضية). بترجّع `true` لو لقينا حاجة فعلًا.
  Future<bool> _restoreFromServer() async {
    final key = customerKey;
    if (key.isEmpty) return false;
    try {
      final snap = await Db.i.customerRef(key).get();
      if (!snap.exists) return false;
      final m = asMap(snap.value);

      final serverName = (m['name'] ?? '').toString().trim();
      if (_name.isEmpty && serverName.isNotEmpty) _name = serverName;

      final serverAddresses = asMap(m['addresses'])
          .values
          .map((v) => Address.fromMap(asMap(v)))
          .where((a) => a.id.isNotEmpty)
          .toList();

      if (serverAddresses.isNotEmpty) {
        // بندمج: اللي على الجهاز له الأولوية، وبنضيف اللي على السيرفر بس.
        final have = _addresses.map((a) => a.id).toSet();
        _addresses.addAll(serverAddresses.where((a) => !have.contains(a.id)));
        if (_selectedAddressId.isEmpty) _selectedAddressId = _addresses.first.id;
        await _persistAddresses();
      }

      await _prefs?.setString(_kName, _name);
      return true;
    } catch (e) {
      // فشل الاسترجاع مش سبب يمنع الدخول — العميل يكتب عنوانه عادي.
      debugPrint('restore failed: $e');
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final oldKey = customerKey;
    if (name != null) _name = name.trim();
    if (phone != null) _phone = phone.trim();
    await _prefs?.setString(_kName, _name);
    await _prefs?.setString(_kPhone, _phone);

    // غيّر رقمه؟ يبقى بقى عميل تاني — نجيب بياناته المحفوظة على الرقم الجديد.
    if (customerKey != oldKey) await _restoreFromServer();

    notifyListeners();
    _syncToServer();
  }

  Future<void> signOut() async {
    _name = '';
    _phone = '';
    _addresses = [];
    _selectedAddressId = '';
    await _prefs?.remove(_kName);
    await _prefs?.remove(_kPhone);
    await _prefs?.remove(_kAddresses);
    await _prefs?.remove(_kSelected);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _uid = '';
    notifyListeners();
  }

  Future<void> saveAddress(Address address) async {
    final idx = _addresses.indexWhere((a) => a.id == address.id);
    if (idx >= 0) {
      _addresses[idx] = address;
    } else {
      _addresses.add(address);
    }
    _selectedAddressId = address.id;
    await _persistAddresses();
    notifyListeners();
    _syncToServer();
  }

  Future<void> deleteAddress(String id) async {
    _addresses.removeWhere((a) => a.id == id);
    if (_selectedAddressId == id) {
      _selectedAddressId = _addresses.isEmpty ? '' : _addresses.first.id;
    }
    await _persistAddresses();
    notifyListeners();
    // لازم يتشال من السيرفر كمان، وإلا هيرجع تاني مع أول استرجاع.
    Db.i
        .replaceAddresses(customerKey, _addresses)
        .catchError((e) => debugPrint('address delete sync failed: $e'));
  }

  Future<void> selectAddress(String id) async {
    _selectedAddressId = id;
    await _prefs?.setString(_kSelected, id);
    notifyListeners();
  }

  // ── المفضّلة ─────────────────────────────────────────────────────────────
  // محلية بالكامل: مالهاش لازمة على السيرفر ومش محتاجة تتزامن.

  final Set<String> _favorites = {};

  Set<String> get favorites => Set.unmodifiable(_favorites);

  bool isFavorite(String productId) => _favorites.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    if (!_favorites.remove(productId)) _favorites.add(productId);
    await _prefs?.setStringList(_kFavorites, _favorites.toList());
    notifyListeners();
  }

  Future<void> _persistAddresses() async {
    await _prefs?.setString(
      _kAddresses,
      jsonEncode(_addresses.map((a) => a.toMap()).toList()),
    );
    await _prefs?.setString(_kSelected, _selectedAddressId);
  }

  /// مزامنة صامتة — لو النت مقطوع مش هنزعّج العميل برسالة خطأ، الطلب
  /// نفسه بيتبعت معاه كل البيانات المطلوبة على أي حال.
  void _syncToServer() {
    if (_uid.isEmpty || customerKey.isEmpty) return;
    Db.i
        .saveCustomer(
          key: customerKey,
          name: _name,
          phone: _phone,
          addresses: _addresses,
        )
        .catchError((e) => debugPrint('customer sync failed: $e'));
  }
}
