import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase.initializeApp
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
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
    appId: '1:350459297702:web:f7185105ebfa0bad9e1967',
    messagingSenderId: '350459297702',
    projectId: 'mediq-opd',
    storageBucket: 'mediq-opd.firebasestorage.app',
    iosBundleId: 'com.mediq.opd',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCYqOjRDQAV0vZ4BxOPFRbz69EhpMyMgMQ',
    appId: '1:350459297702:web:f7185105ebfa0bad9e1967',
    messagingSenderId: '350459297702',
    projectId: 'mediq-opd',
    storageBucket: 'mediq-opd.firebasestorage.app',
    iosBundleId: 'com.mediq.opd',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCYqOjRDQAV0vZ4BxOPFRbz69EhpMyMgMQ',
    appId: '1:350459297702:web:f7185105ebfa0bad9e1967',
    messagingSenderId: '350459297702',
    projectId: 'mediq-opd',
    authDomain: 'mediq-opd.firebaseapp.com',
    storageBucket: 'mediq-opd.firebasestorage.app',
  );
}
