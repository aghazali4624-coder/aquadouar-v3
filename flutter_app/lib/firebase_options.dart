// lib/firebase_options.dart
// ⚠️  REMPLACEZ CE FICHIER par celui généré par : flutterfire configure
// Ce fichier est un template — les vraies valeurs viennent de votre projet Firebase

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default:                     return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWXOqwQhri0eP6ofGK1FO48N7Q6tMp_KU',
    appId: '1:947388843332:android:d2ee70a28bc1949072c311',
    messagingSenderId: '947388843332',
    projectId: 'aquadouar',
    storageBucket: 'aquadouar.firebasestorage.app',
  );

  // ⚠️  REMPLACEZ par vos vraies valeurs (depuis flutterfire configure)

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBgQgCWktmsgC3cdOJg9koAVTOGJJS2Bpk',
    appId: '1:947388843332:web:b61962045f84957e72c311',
    messagingSenderId: '947388843332',
    projectId: 'aquadouar',
    authDomain: 'aquadouar.firebaseapp.com',
    storageBucket: 'aquadouar.firebasestorage.app',
    measurementId: 'G-0SNB3CVVE5',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'VOTRE_API_KEY',
    appId:             'VOTRE_APP_ID_IOS',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId:         'aquadouar',
    storageBucket:     'aquadouar.firebasestorage.app',
    iosBundleId:       'com.aquadouar.app',
  );
}