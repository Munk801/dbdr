import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayerRole {survivor, killer}

extension PlayerRoleExtension on PlayerRole {
  String shortString(){
    return this.toString().split(".").last;
  }
}

class Perk extends ChangeNotifier {
  String id, name, description, owner;
  ValueNotifier<String> thumbnailNotifier = ValueNotifier<String>("");
  bool isFiltered = false;

  Perk(this.id, this.name, this.description, this.owner);

  Perk.empty() : this("", "", "", "");

  Perk.fromDocument(DocumentSnapshot document) {
    id = document.documentID;
    name = document['name'];
    description = document['description'];
    owner = document['owner'];
    if (owner == "") {
      owner = "None";
    }
  }

  String get thumbnail {
    return this.thumbnailNotifier.value.toString();
  }

  bool isEmpty() {
    if (id == "") { return true;}
    return false;
  }

  // ///When setting the thumbnail notify
  // ///all other listeners that the thumbnail
  // ///can now be retrieved.
  set thumbnail(String newValue) {
    this.thumbnailNotifier.value = newValue;
  }
}

class PerkBuild {
  String id, name, user;
  Perk perk1, perk2, perk3, perk4;
  PlayerRole role;


}

