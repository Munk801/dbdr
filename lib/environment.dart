// Dart
import 'dart:async';

// External Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// Internal Packages
import 'perk.dart';

String _getRoleString(PlayerRole role) {
  return role == PlayerRole.survivor ? 'survivor' : 'killer';
}

class Environment {

}

class AuthManager {
  static final sharedInstance = AuthManager();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser currentUser;

  signIn() {
    _auth.signInAnonymously().then((user) => currentUser = user).catchError((e) {
      print("Error while signing in: $e");
    });
  }      
}

class PerkManager {
  static final sharedInstance = PerkManager();
  Firestore firestore;
  List<Perk> survivorPerks = [];
  List<Perk> killerPerks = [];

  List<Perk> _getPerks(QuerySnapshot query, PlayerRole role) {
    // Converts the documents from the snapshot to perks
    var roleString = role == PlayerRole.survivor ? 'survivor' : 'killer';
    var perks = query.documents
      .where((snapshot) => snapshot['role'] == roleString)
      .map((document) => Perk.fromDocument(document))
      .toList();
    return perks;
  }

  initialize({FirebaseApp app}) {
    this.firestore = new Firestore(app: app);
  }

  Future<Null> getAll() async {
    // Retrieve all perks based on the playe rrole
    await firestore.collection('perks')
      .getDocuments().then((perksDocs) {
          survivorPerks = _getPerks(perksDocs, PlayerRole.survivor);
          killerPerks = _getPerks(perksDocs, PlayerRole.killer);
      }).catchError((error) => print("Unable to get documents: $error"));
  }

  Stream<QuerySnapshot> getUserBuilds({PlayerRole role, String uid}) {
    var roleString = _getRoleString(role);
    return Firestore.instance.collection('builds')
      .where("user", isEqualTo: uid)
      .where('role', isEqualTo: roleString)
      .snapshots();
  }

  Future<Null> removeBuild(String documentID) async {
    await firestore.collection('builds').document(documentID).delete();
  }
}