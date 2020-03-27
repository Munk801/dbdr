
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'perk.dart';

class DBDRStorageManager {
  static final sharedInstance = new DBDRStorageManager();
  FirebaseStorage storage;
  Map<String, String> perkImageMap;
  FirebaseAuth _auth;

  void initialize({FirebaseApp app}) {
    this.storage = new FirebaseStorage(app: app, 
      storageBucket: 'gs://dbdr-6fbb1.appspot.com');
  }

  Future<String> getPerkImageURL(Perk perk) async {
    this._auth = FirebaseAuth.instance;
    // Do not attempt to retrieve the storage data until
    // the user has been signed in
    while (this._auth.currentUser() == null) {
      sleep(Duration(seconds: 2));
    }
    // Early out if the perk doesn't exist to locate
    if (perk == null || perk.isEmpty()) {
      return "";
    }
    var assetUrl = '/images/perks/${perk.id}.png';
    var url = await storage.ref().child(assetUrl).getDownloadURL();
    return url;
  }
}