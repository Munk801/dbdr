import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'perk.dart';

class DBDRStorageManager {
  static final sharedInstance = new DBDRStorageManager();
  FirebaseStorage storage;
  Map<String, String> perkImageMap;
  FirebaseUser user;

  void initialize({FirebaseApp app}) {
    this.storage = new FirebaseStorage(app: app, 
      storageBucket: 'gs://dbdr-6fbb1.appspot.com');
  }

  Future<String> getPerkImageURL(Perk perk) async {
    // Early out if the perk doesn't exist to locate
    if (perk == null || perk.isEmpty()) {
      return "";
    }

    if (user == null) {
      return "";
    }

    var assetUrl = '/images/perks/${perk.id}.png';
    var url = await FirebaseStorage.instance.ref().child(assetUrl).getDownloadURL();
    return url;
  }
}