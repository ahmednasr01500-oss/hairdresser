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
  static const String _apiKey = 'AIzaSyDP2O_p8w4iRvMFU_RQ8l4aaszT4DJ4AiA';
  static const String _projectId = 'hairdresser-d6d24';
  static const String _messagingSenderId = '8571108114';
  static const String _databaseURL =
      'https://hairdresser-d6d24-default-rtdb.firebaseio.com';
  static const String _storageBucket = 'hairdresser-d6d24.firebasestorage.app';
  static const String _webAppId = '1:8571108114:web:a99de2aa857603ed57d1cb';

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
    authDomain: 'hairdresser-d6d24.firebaseapp.com',
    measurementId: 'G-8S85BX4D65',
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
