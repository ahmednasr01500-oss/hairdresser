import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// إعدادات Firebase.
///
/// القيم دي جاية من إعداد الويب اللي اتبعت لينا. الديتابيز والمصادقة
/// بيشتغلوا بيها على أندرويد و iOS من غير ملف google-services.json،
/// لأننا بنمرّر الـ options يدويًا في [Firebase.initializeApp].
///
/// لو صاحب المحل سجّل تطبيق أندرويد/iOS منفصل في الـ Console وجاب
/// appId خاص بكل منصة، غيّر `appId` في [android] و[ios] بس — الباقي زي ما هو.
/// راجع SETUP.md خطوة (٢).
class DefaultFirebaseOptions {
  static const String _apiKey = 'AIzaSyCqck36lWXsVCOQ5SR8Z-SewIDcjIbso4o';
  static const String _projectId = 'akhdar-89577';
  static const String _messagingSenderId = '1033627027701';
  static const String _databaseURL =
      'https://akhdar-89577-default-rtdb.firebaseio.com';
  static const String _storageBucket = 'akhdar-89577.firebasestorage.app';
  static const String _webAppId = '1:1033627027701:web:d452aef05392537c845dbc';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    databaseURL: _databaseURL,
    storageBucket: _storageBucket,
    authDomain: 'akhdar-89577.firebaseapp.com',
    measurementId: 'G-SC0LK2CK9Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    databaseURL: _databaseURL,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    databaseURL: _databaseURL,
    storageBucket: _storageBucket,
    iosBundleId: 'com.akhdar.akhdar',
  );
}
