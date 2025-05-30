// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCugvXhoGg1MtSAmwCaTURyTM7GzSch3K4',
    appId: '1:543822780259:web:b8d27fdc6998eee24a6556',
    messagingSenderId: '543822780259',
    projectId: 'auxilia1',
    authDomain: 'auxilia1.firebaseapp.com',
    storageBucket: 'auxilia1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGiGtptL3cUCuKAR2WHA3gPge8_N6q0sc',
    appId: '1:543822780259:android:156ea80d5876d9da4a6556',
    messagingSenderId: '543822780259',
    projectId: 'auxilia1',
    storageBucket: 'auxilia1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWwJjNEqJwxA0QuA6pDJTDBxE46rcm0lA',
    appId: '1:543822780259:ios:e20b97a7bc9584814a6556',
    messagingSenderId: '543822780259',
    projectId: 'auxilia1',
    storageBucket: 'auxilia1.firebasestorage.app',
    iosBundleId: 'com.goodfellas.auxilia',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCWwJjNEqJwxA0QuA6pDJTDBxE46rcm0lA',
    appId: '1:543822780259:ios:e20b97a7bc9584814a6556',
    messagingSenderId: '543822780259',
    projectId: 'auxilia1',
    storageBucket: 'auxilia1.firebasestorage.app',
    iosBundleId: 'com.goodfellas.auxilia',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCugvXhoGg1MtSAmwCaTURyTM7GzSch3K4',
    appId: '1:543822780259:web:0470411c72cb3c094a6556',
    messagingSenderId: '543822780259',
    projectId: 'auxilia1',
    authDomain: 'auxilia1.firebaseapp.com',
    storageBucket: 'auxilia1.firebasestorage.app',
  );
}
