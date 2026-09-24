// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCYqOjRDQAV0vZ4BxOPFRbz69EhpMyMgMQ',
    appId: '1:350459297702:web:f7185105ebfa0bad9e1967',
    messagingSenderId: '350459297702',
    projectId: 'mediq-opd',
    authDomain: 'mediq-opd.firebaseapp.com',
    storageBucket: 'mediq-opd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCYqOjRDQAV0vZ4BxOPFRbz69EhpMyMgMQ',
    appId: '1:350459297702:android:694f509e530ce994',
    messagingSenderId: '350459297702',
    projectId: 'mediq-opd',
    storageBucket: 'mediq-opd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCYqOjRDQAV0vZ4BxOPFRbz69EhpMyMgMQ',
    appId: '1:350459297702:ios:f7185105ebfa0bad9e1967',
    messagingSenderId: '350459297702',
    projectId: 'mediq-opd',
    storageBucket: 'mediq-opd.firebasestorage.app',
  );
}