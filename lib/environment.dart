// Dart
import 'dart:async';

// External Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  List<Perk> survivorPerks = [];
  List<Perk> killerPerks = [];

  List<Perk> _getPerks(QuerySnapshot query) {
    // Converts the documents from the snapshot to perks
    var perks = query.documents
      .map((document) => Perk.fromDocument(document))
      .toList();
    return perks;
  }
  Future<Null> getAll({PlayerRole role}) async {
    // Retrieve all perks based on the playe rrole
    var roleString = role == PlayerRole.survivor ? 'survivor' : 'killer';
    var perksDocs = await Firestore.instance.collection('perks')
      .where('role', isEqualTo: roleString)
      .getDocuments();
    switch (role) {
      case PlayerRole.survivor:
        survivorPerks = _getPerks(perksDocs);
        break;
      case PlayerRole.killer:
        killerPerks = _getPerks(perksDocs);
        break;
      default:
        break;
    }
  }

  Stream<QuerySnapshot> getUserBuilds({PlayerRole role, String uid}) {
    var roleString = _getRoleString(role);
    return Firestore.instance.collection('builds')
      .where("user", isEqualTo: uid)
      .where('role', isEqualTo: roleString)
      .snapshots();
  }
}
