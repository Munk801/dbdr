
import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'perk.dart';

class DBDRStorageManager {
  static final sharedInstance = new DBDRStorageManager();
  FirebaseStorage storage;

  void initialize({FirebaseApp app}) {
    this.storage = new FirebaseStorage(app: app, 
      storageBucket: 'gs://dbdr-6fbb1.appspot.com');
  }

  Future<String> getPerkImageURL(Perk perk) async {
    var assetUrl = '/images/perks/${perk.id}.png';
    var url = await storage.ref().child(assetUrl).getDownloadURL();
    return url;
  }
}