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
    apiKey: 'AIzaSyMediQWebDummyApiKey1234567890',
    appId: '1:123456789012:web:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'mediq-opd-app',
    authDomain: 'mediq-opd-app.firebaseapp.com',
    storageBucket: 'mediq-opd-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyMediQAndroidDummyApiKey123456',
    appId: '1:123456789012:android:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'mediq-opd-app',
    storageBucket: 'mediq-opd-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyMediQiOSDummyApiKey123456789',
    appId: '1:123456789012:ios:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'mediq-opd-app',
    storageBucket: 'mediq-opd-app.appspot.com',
    iosBundleId: 'com.mediq.opd',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyMediQMacosDummyApiKey123456',
    appId: '1:123456789012:ios:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'mediq-opd-app',
    storageBucket: 'mediq-opd-app.appspot.com',
    iosBundleId: 'com.mediq.opd',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyMediQWinDummyApiKey1234567890',
    appId: '1:123456789012:web:abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'mediq-opd-app',
    authDomain: 'mediq-opd-app.firebaseapp.com',
    storageBucket: 'mediq-opd-app.appspot.com',
  );
}
