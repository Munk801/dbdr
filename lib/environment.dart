// Dart
import 'dart:async';
import 'package:flutter/foundation.dart';

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

class OwnerHeader {
  final String owner;

  OwnerHeader(this.owner);
}

class PerkManager extends ChangeNotifier {
  static final sharedInstance = PerkManager();
  Firestore firestore;
  List<Perk> survivorPerks = [];
  List<Perk> killerPerks = [];
  bool hasRetrievedPerks = false;

  List<Perk> _getPerks(QuerySnapshot query, PlayerRole role) {
    // Converts the documents from the snapshot to perks
    var roleString = role == PlayerRole.survivor ? 'survivor' : 'killer';
    var perks = query.documents
      .where((snapshot) => snapshot['role'] == roleString)
      .map((document) {
        var perk = Perk.fromDocument(document);
        return perk;
      }).toList();
      return perks;
  }

  initialize({FirebaseApp app}) {
    this.firestore = new Firestore(app: app);
  }

  Future<Null> getAll() async {
    // Retrieve all perks based on the playe rrole
    await firestore.collection('perks')
      .getDocuments().then((perksDocs) async {
        survivorPerks = _getPerks(perksDocs, PlayerRole.survivor);
        killerPerks = _getPerks(perksDocs, PlayerRole.killer);
        hasRetrievedPerks = true;
        notifyListeners();
      }).catchError((error) => print("Unable to get documents: $error"));
  }

  List<Perk> filter(List<Perk> perks) {
    return perks.where((p) => !p.isFiltered).toList();
  }

  List<Perk> perks(role, {bool ignoreFiltered=false}) {
    List<Perk> perks = [];
    if (role == PlayerRole.survivor) {
      perks = ignoreFiltered ? this.filter(survivorPerks) : survivorPerks;
    } else {
      perks = ignoreFiltered ? this.filter(killerPerks) : killerPerks;
    }
    return perks;
  }

  Map<String, List<Perk>> rolePerkMap(PlayerRole role, {bool ignoreFiltered=false}) {
    var perks = this.perks(role, ignoreFiltered: ignoreFiltered);
    Map<String, List<Perk>> perkMap = {};
    // Add the All categories first
    perkMap["All"] = [];
    for (var perk in perks) {
      if (perk.owner == "") {
        perkMap["All"].add(perk);
      }
      else if (perkMap.containsKey(perk.owner)) {
        perkMap[perk.owner].add(perk);
      }
      else {
        perkMap[perk.owner] = [perk];
      }
    }
    return perkMap;
  }

  List flattenedOwnerPerkList(PlayerRole role, {bool ignoreFiltered=false}) {
    /* Returns a flattened list in the following
    [owner, perk, perk perk, owner ...]
    This can be used to pass through a list view which you need the owner to be displayed
    */
    List perkList = [];
    Map<String, List<Perk>> perkMap = this.rolePerkMap(role, ignoreFiltered: ignoreFiltered);
    perkMap.forEach((owner, perks) {
      perkList.add(owner);
      perkList.addAll(perks);
    });
    return perkList;
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