
import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'perk.dart';

class DBDRStorageManager {
  static final sharedInstance = new DBDRStorageManager();
  FirebaseStorage storage;

  Future<Null> initialize() async {
    await FirebaseApp
        .configure(
      name: 'DBDR',
      options: new FirebaseOptions(
        googleAppID: Platform.isIOS
            ? '1:612079491419:ios:472df683bdd23490'
            : '1:612079491419:android:472df683bdd23490',
        gcmSenderID: '612079491419',
        apiKey: Platform.environment['FIREBASE_DBDR_APIKEY'],
        projectID: 'dbdr-6fbb1',
      ),
    )
        .then((app) {
      this.storage = new FirebaseStorage(
          app: app, storageBucket: 'gs://dbdr-6fbb1.appspot.com');
    });
  }

  Future<String> getPerkImageURL(Perk perk) async {
    var assetUrl = '/images/perks/${perk.id}.png';
    var url = await storage.ref().child(assetUrl).getDownloadURL();
    return url;
  }
}