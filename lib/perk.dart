import 'package:cloud_firestore/cloud_firestore.dart';

enum PlayerRole {survivor, killer}

class Perk {
  String id, name, description, owner;
  String thumbnail = "";
  bool isFiltered = false;

  Perk(this.id, this.name, this.description);

  Perk.empty() : this("", "", "");

  Perk.fromDocument(DocumentSnapshot document) {
    id = document.documentID;
    name = document['name'];
    description = document['description'];
    owner = document['owner'];
  }
}

class PerkBuild {
  String id, name, user;
  Perk perk1, perk2, perk3, perk4;
  PlayerRole role;


}